-- Migration: Single-table audit and versioning system
-- This replaces the two-table design (shipment_audit_events + shipment_versions)
-- with a single shipment_history table

-- Drop old tables if they exist
DROP TABLE IF EXISTS "public"."shipment_versions" CASCADE;
DROP TABLE IF EXISTS "public"."shipment_audit_events" CASCADE;

-- Drop old functions
DROP FUNCTION IF EXISTS "public"."create_audit_event"(uuid, text, uuid, text, text, jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS "public"."restore_shipment_version"(uuid, integer, uuid, text, text) CASCADE;
DROP FUNCTION IF EXISTS "public"."get_next_version_no"(uuid) CASCADE;

-- Create single history table combining audit events and version snapshots
CREATE TABLE IF NOT EXISTS "public"."shipment_history" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    "shipment_id" uuid NOT NULL REFERENCES "public"."shipment_requests"("id") ON DELETE CASCADE,
    "version_no" integer NOT NULL,

    -- Event metadata (the "what happened")
    "event_type" text NOT NULL CHECK (event_type IN ('created', 'updated', 'status_changed', 'restored', 'file_added', 'file_removed')),
    "actor_id" uuid NOT NULL,
    "actor_name" text,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    "reason" text,

    -- Full state snapshot at this version
    "snapshot_data" jsonb NOT NULL,

    -- Additional metadata
    "metadata" jsonb,

    -- Constraints
    CONSTRAINT "unique_shipment_version" UNIQUE ("shipment_id", "version_no"),
    CONSTRAINT "positive_version" CHECK (version_no > 0)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS "idx_history_shipment_version_desc"
    ON "public"."shipment_history" ("shipment_id", "version_no" DESC);

CREATE INDEX IF NOT EXISTS "idx_history_shipment_timestamp_desc"
    ON "public"."shipment_history" ("shipment_id", "timestamp" DESC);

CREATE INDEX IF NOT EXISTS "idx_history_actor"
    ON "public"."shipment_history" ("actor_id");

CREATE INDEX IF NOT EXISTS "idx_history_event_type"
    ON "public"."shipment_history" ("event_type");

CREATE INDEX IF NOT EXISTS "idx_history_timestamp"
    ON "public"."shipment_history" ("timestamp");

-- Function to get the next version number for a shipment
CREATE OR REPLACE FUNCTION "public"."get_next_version_no"(p_shipment_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(MAX(version_no), 0) + 1
    FROM public.shipment_history
    WHERE shipment_id = p_shipment_id;
$$;

-- Function to create a new history entry (audit event + version snapshot)
CREATE OR REPLACE FUNCTION "public"."create_history_entry"(
    p_shipment_id uuid,
    p_event_type text,
    p_actor_id uuid,
    p_actor_name text,
    p_reason text,
    p_snapshot_data jsonb,
    p_metadata jsonb DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_version_no integer;
BEGIN
    -- Get next version number
    v_version_no := public.get_next_version_no(p_shipment_id);

    -- Insert single history entry with event metadata and full snapshot
    INSERT INTO public.shipment_history (
        shipment_id,
        version_no,
        event_type,
        actor_id,
        actor_name,
        reason,
        snapshot_data,
        metadata
    ) VALUES (
        p_shipment_id,
        v_version_no,
        p_event_type,
        p_actor_id,
        p_actor_name,
        p_reason,
        p_snapshot_data,
        p_metadata
    );

    RETURN v_version_no;
END;
$$;

-- Function to restore a shipment to a previous version
CREATE OR REPLACE FUNCTION "public"."restore_shipment_version"(
    p_shipment_id uuid,
    p_source_version_no integer,
    p_actor_id uuid,
    p_actor_name text,
    p_reason text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_snapshot_data jsonb;
    v_new_version_no integer;
BEGIN
    -- Get the snapshot data from the source version
    SELECT snapshot_data INTO v_snapshot_data
    FROM public.shipment_history
    WHERE shipment_id = p_shipment_id AND version_no = p_source_version_no;

    IF v_snapshot_data IS NULL THEN
        RAISE EXCEPTION 'Version % not found for shipment %', p_source_version_no, p_shipment_id;
    END IF;

    -- Create new history entry for restore with full snapshot
    v_new_version_no := public.create_history_entry(
        p_shipment_id,
        'restored',
        p_actor_id,
        p_actor_name,
        p_reason,
        v_snapshot_data,  -- Copy the full snapshot
        jsonb_build_object('restored_from', p_source_version_no, 'source_version_no', p_source_version_no)
    );

    -- Update the shipment_requests table with restored data
    UPDATE public.shipment_requests
    SET
        title = COALESCE(v_snapshot_data->>'title', title),
        description = COALESCE(v_snapshot_data->>'description', description),
        extracted_data = COALESCE(v_snapshot_data->'extracted_data', extracted_data),
        status = COALESCE(v_snapshot_data->>'status', status),
        updated_at = now()
    WHERE id = p_shipment_id;

    RETURN v_new_version_no;
END;
$$;

-- Function to compute field changes (diff) between two versions
-- This replaces storing diffs - we compute them on-demand when needed
CREATE OR REPLACE FUNCTION "public"."get_field_changes"(
    p_shipment_id uuid,
    p_from_version integer,
    p_to_version integer
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_from_snapshot jsonb;
    v_to_snapshot jsonb;
    v_changes jsonb := '{}'::jsonb;
    v_key text;
BEGIN
    -- Get both snapshots
    SELECT snapshot_data INTO v_from_snapshot
    FROM public.shipment_history
    WHERE shipment_id = p_shipment_id AND version_no = p_from_version;

    SELECT snapshot_data INTO v_to_snapshot
    FROM public.shipment_history
    WHERE shipment_id = p_shipment_id AND version_no = p_to_version;

    -- Compare all keys and build diff object
    FOR v_key IN SELECT DISTINCT jsonb_object_keys(v_from_snapshot || v_to_snapshot)
    LOOP
        IF (v_from_snapshot->v_key) IS DISTINCT FROM (v_to_snapshot->v_key) THEN
            v_changes := v_changes || jsonb_build_object(
                v_key, jsonb_build_object(
                    'old', v_from_snapshot->v_key,
                    'new', v_to_snapshot->v_key
                )
            );
        END IF;
    END LOOP;

    RETURN v_changes;
END;
$$;

-- Row Level Security Policies
ALTER TABLE "public"."shipment_history" ENABLE ROW LEVEL SECURITY;

-- Users can view history for shipments they can access
CREATE POLICY "Users can view history for accessible shipments"
ON "public"."shipment_history"
FOR SELECT
USING (public.can_access_shipment(shipment_id, auth.uid()));

-- Only allow inserts through the create_history_entry function
CREATE POLICY "System can insert history"
ON "public"."shipment_history"
FOR INSERT
WITH CHECK (false); -- No direct inserts, must use function

-- Grant permissions
GRANT ALL ON TABLE "public"."shipment_history" TO "anon";
GRANT ALL ON TABLE "public"."shipment_history" TO "authenticated";
GRANT ALL ON TABLE "public"."shipment_history" TO "service_role";

GRANT ALL ON FUNCTION "public"."get_next_version_no"(uuid) TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_version_no"(uuid) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_version_no"(uuid) TO "service_role";

GRANT ALL ON FUNCTION "public"."create_history_entry"(uuid, text, uuid, text, text, jsonb, jsonb) TO "anon";
GRANT ALL ON FUNCTION "public"."create_history_entry"(uuid, text, uuid, text, text, jsonb, jsonb) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_history_entry"(uuid, text, uuid, text, text, jsonb, jsonb) TO "service_role";

GRANT ALL ON FUNCTION "public"."restore_shipment_version"(uuid, integer, uuid, text, text) TO "anon";
GRANT ALL ON FUNCTION "public"."restore_shipment_version"(uuid, integer, uuid, text, text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."restore_shipment_version"(uuid, integer, uuid, text, text) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_field_changes"(uuid, integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_field_changes"(uuid, integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_field_changes"(uuid, integer, integer) TO "service_role";

-- Comments
COMMENT ON TABLE "public"."shipment_history" IS 'Single table for immutable audit log with full version snapshots';
COMMENT ON FUNCTION "public"."create_history_entry" IS 'Creates a new history entry with event metadata and full snapshot';
COMMENT ON FUNCTION "public"."restore_shipment_version" IS 'Restores a shipment to a previous version by creating a new version';
COMMENT ON FUNCTION "public"."get_field_changes" IS 'Computes the diff between two versions on-demand';
