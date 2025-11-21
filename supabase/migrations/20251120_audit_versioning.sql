-- Migration: Add audit and versioning system for shipment requests
-- This builds on top of the existing shipment_requests table

-- Create audit_events table for immutable event log
CREATE TABLE IF NOT EXISTS "public"."shipment_audit_events" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    "shipment_id" uuid NOT NULL REFERENCES "public"."shipment_requests"("id") ON DELETE CASCADE,
    "version_no" integer NOT NULL,
    "event_type" text NOT NULL CHECK (event_type IN ('created', 'updated', 'status_changed', 'restored', 'file_added', 'file_removed')),
    "actor_id" uuid NOT NULL REFERENCES "auth"."users"("id"),
    "actor_name" text,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    "reason" text,
    "field_changes" jsonb, -- JSON Patch format or simple diff
    "metadata" jsonb, -- Additional context (IP, user agent, etc.)

    -- Ensure unique version numbers per shipment
    CONSTRAINT "unique_shipment_version" UNIQUE ("shipment_id", "version_no"),

    -- Ensure version numbers are positive
    CONSTRAINT "positive_version" CHECK (version_no > 0)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS "idx_audit_shipment_version_desc" ON "public"."shipment_audit_events" ("shipment_id", "version_no" DESC);
CREATE INDEX IF NOT EXISTS "idx_audit_shipment_timestamp_desc" ON "public"."shipment_audit_events" ("shipment_id", "timestamp" DESC);
CREATE INDEX IF NOT EXISTS "idx_audit_actor" ON "public"."shipment_audit_events" ("actor_id");
CREATE INDEX IF NOT EXISTS "idx_audit_event_type" ON "public"."shipment_audit_events" ("event_type");

-- Create shipment_versions table for full snapshots at each version
CREATE TABLE IF NOT EXISTS "public"."shipment_versions" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    "shipment_id" uuid NOT NULL REFERENCES "public"."shipment_requests"("id") ON DELETE CASCADE,
    "version_no" integer NOT NULL,
    "snapshot_data" jsonb NOT NULL, -- Full shipment data at this version
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "created_by" uuid NOT NULL REFERENCES "auth"."users"("id"),

    -- Ensure unique version numbers per shipment
    CONSTRAINT "unique_version_snapshot" UNIQUE ("shipment_id", "version_no"),

    -- Foreign key to audit event
    CONSTRAINT "fk_audit_event" FOREIGN KEY ("shipment_id", "version_no")
        REFERENCES "public"."shipment_audit_events"("shipment_id", "version_no")
        ON DELETE CASCADE
);

-- Create index for fast version retrieval
CREATE INDEX IF NOT EXISTS "idx_version_shipment_version_desc" ON "public"."shipment_versions" ("shipment_id", "version_no" DESC);

-- Function to get the next version number for a shipment
CREATE OR REPLACE FUNCTION "public"."get_next_version_no"(p_shipment_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(MAX(version_no), 0) + 1
    FROM public.shipment_audit_events
    WHERE shipment_id = p_shipment_id;
$$;

-- Function to create an audit event and version snapshot (called from application)
CREATE OR REPLACE FUNCTION "public"."create_audit_event"(
    p_shipment_id uuid,
    p_event_type text,
    p_actor_id uuid,
    p_actor_name text,
    p_reason text,
    p_field_changes jsonb,
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

    -- Insert audit event
    INSERT INTO public.shipment_audit_events (
        shipment_id,
        version_no,
        event_type,
        actor_id,
        actor_name,
        reason,
        field_changes,
        metadata
    ) VALUES (
        p_shipment_id,
        v_version_no,
        p_event_type,
        p_actor_id,
        p_actor_name,
        p_reason,
        p_field_changes,
        p_metadata
    );

    -- Insert version snapshot
    INSERT INTO public.shipment_versions (
        shipment_id,
        version_no,
        snapshot_data,
        created_by
    ) VALUES (
        p_shipment_id,
        v_version_no,
        p_snapshot_data,
        p_actor_id
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
    FROM public.shipment_versions
    WHERE shipment_id = p_shipment_id AND version_no = p_source_version_no;

    IF v_snapshot_data IS NULL THEN
        RAISE EXCEPTION 'Version % not found for shipment %', p_source_version_no, p_shipment_id;
    END IF;

    -- Create new audit event for restore
    v_new_version_no := public.create_audit_event(
        p_shipment_id,
        'restored',
        p_actor_id,
        p_actor_name,
        p_reason,
        jsonb_build_object('source_version_no', p_source_version_no),
        v_snapshot_data,
        jsonb_build_object('restored_from', p_source_version_no)
    );

    -- Update the shipment_requests table with restored data
    UPDATE public.shipment_requests
    SET
        title = v_snapshot_data->>'title',
        description = v_snapshot_data->>'description',
        extracted_data = v_snapshot_data->'extracted_data',
        status = v_snapshot_data->>'status',
        updated_at = now()
    WHERE id = p_shipment_id;

    RETURN v_new_version_no;
END;
$$;

-- Row Level Security Policies for audit_events
ALTER TABLE "public"."shipment_audit_events" ENABLE ROW LEVEL SECURITY;

-- Users can view audit events for shipments they can access
CREATE POLICY "Users can view audit events for accessible shipments"
ON "public"."shipment_audit_events"
FOR SELECT
USING (public.can_access_shipment(shipment_id, auth.uid()));

-- Only allow inserts through the create_audit_event function
CREATE POLICY "System can insert audit events"
ON "public"."shipment_audit_events"
FOR INSERT
WITH CHECK (false); -- No direct inserts, must use function

-- Row Level Security Policies for shipment_versions
ALTER TABLE "public"."shipment_versions" ENABLE ROW LEVEL SECURITY;

-- Users can view versions for shipments they can access
CREATE POLICY "Users can view versions for accessible shipments"
ON "public"."shipment_versions"
FOR SELECT
USING (public.can_access_shipment(shipment_id, auth.uid()));

-- Only allow inserts through the create_audit_event function
CREATE POLICY "System can insert versions"
ON "public"."shipment_versions"
FOR INSERT
WITH CHECK (false); -- No direct inserts, must use function

-- Grant permissions
GRANT ALL ON TABLE "public"."shipment_audit_events" TO "anon";
GRANT ALL ON TABLE "public"."shipment_audit_events" TO "authenticated";
GRANT ALL ON TABLE "public"."shipment_audit_events" TO "service_role";

GRANT ALL ON TABLE "public"."shipment_versions" TO "anon";
GRANT ALL ON TABLE "public"."shipment_versions" TO "authenticated";
GRANT ALL ON TABLE "public"."shipment_versions" TO "service_role";

GRANT ALL ON FUNCTION "public"."get_next_version_no"(uuid) TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_version_no"(uuid) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_version_no"(uuid) TO "service_role";

GRANT ALL ON FUNCTION "public"."create_audit_event"(uuid, text, uuid, text, text, jsonb, jsonb, jsonb) TO "anon";
GRANT ALL ON FUNCTION "public"."create_audit_event"(uuid, text, uuid, text, text, jsonb, jsonb, jsonb) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_audit_event"(uuid, text, uuid, text, text, jsonb, jsonb, jsonb) TO "service_role";

GRANT ALL ON FUNCTION "public"."restore_shipment_version"(uuid, integer, uuid, text, text) TO "anon";
GRANT ALL ON FUNCTION "public"."restore_shipment_version"(uuid, integer, uuid, text, text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."restore_shipment_version"(uuid, integer, uuid, text, text) TO "service_role";

COMMENT ON TABLE "public"."shipment_audit_events" IS 'Immutable append-only log of all shipment changes';
COMMENT ON TABLE "public"."shipment_versions" IS 'Full snapshots of shipment data at each version';
COMMENT ON FUNCTION "public"."create_audit_event" IS 'Creates an audit event and version snapshot in a single transaction';
COMMENT ON FUNCTION "public"."restore_shipment_version" IS 'Restores a shipment to a previous version, creating a new version';
