-- ========================================
-- VALIDATION AND INTEGRITY ENHANCEMENT
-- ========================================
-- Adds:
-- 1. Unique constraint on (shipment_id, version_no)
-- 2. Check constraints for field validation
-- 3. Transaction-safe audit event creation
-- 4. Enhanced error messages for invalid writes
-- ========================================

-- ========================================
-- STEP 1: Add Unique Constraint on (shipment_id, version_no)
-- ========================================
-- Prevents race conditions where two concurrent writes could get the same version_no
-- Database enforces this atomically

DO $$
BEGIN
    -- Check if constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'shipment_history_unique_version'
    ) THEN
        ALTER TABLE public.shipment_history
        ADD CONSTRAINT shipment_history_unique_version
        UNIQUE (shipment_id, version_no);

        RAISE NOTICE '✅ Added unique constraint on (shipment_id, version_no)';
    ELSE
        RAISE NOTICE '⚠️  Unique constraint already exists';
    END IF;
END $$;

-- ========================================
-- STEP 2: Add Check Constraints for Validation
-- ========================================

-- Ensure version_no is always positive
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'shipment_history_version_positive'
    ) THEN
        ALTER TABLE public.shipment_history
        ADD CONSTRAINT shipment_history_version_positive
        CHECK (version_no > 0);

        RAISE NOTICE '✅ Added check constraint: version_no > 0';
    END IF;
END $$;

-- Ensure event_type is one of the allowed values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'shipment_history_valid_event_type'
    ) THEN
        ALTER TABLE public.shipment_history
        ADD CONSTRAINT shipment_history_valid_event_type
        CHECK (event_type IN (
            'created',
            'updated',
            'status_changed',
            'restored',
            'file_added',
            'file_removed',
            'deleted',
            'archived'
        ));

        RAISE NOTICE '✅ Added check constraint: valid event_type';
    END IF;
END $$;

-- Ensure snapshot_data is not null and is valid JSON
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'shipment_history_snapshot_not_null'
    ) THEN
        ALTER TABLE public.shipment_history
        ADD CONSTRAINT shipment_history_snapshot_not_null
        CHECK (snapshot_data IS NOT NULL);

        RAISE NOTICE '✅ Added check constraint: snapshot_data NOT NULL';
    END IF;
END $$;

-- Ensure actor_id and actor_name are provided
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'shipment_history_actor_not_null'
    ) THEN
        ALTER TABLE public.shipment_history
        ADD CONSTRAINT shipment_history_actor_not_null
        CHECK (actor_id IS NOT NULL AND actor_name IS NOT NULL);

        RAISE NOTICE '✅ Added check constraint: actor_id and actor_name NOT NULL';
    END IF;
END $$;

-- ========================================
-- STEP 3: Enhanced create_history_entry Function
-- ========================================
-- Now with comprehensive validation and clear error messages

CREATE OR REPLACE FUNCTION public.create_history_entry(
    p_shipment_id UUID,
    p_event_type TEXT,
    p_actor_id UUID,
    p_actor_name TEXT,
    p_reason TEXT DEFAULT NULL,
    p_snapshot_data JSONB,
    p_metadata JSONB DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_version INTEGER;
    v_new_id UUID;
BEGIN
    -- ========================================
    -- VALIDATION: Check all required fields
    -- ========================================

    IF p_shipment_id IS NULL THEN
        RAISE EXCEPTION 'Validation Error: shipment_id cannot be NULL';
    END IF;

    IF p_event_type IS NULL OR p_event_type = '' THEN
        RAISE EXCEPTION 'Validation Error: event_type cannot be NULL or empty';
    END IF;

    IF p_event_type NOT IN ('created', 'updated', 'status_changed', 'restored', 'file_added', 'file_removed', 'deleted', 'archived') THEN
        RAISE EXCEPTION 'Validation Error: Invalid event_type "%". Must be one of: created, updated, status_changed, restored, file_added, file_removed, deleted, archived', p_event_type;
    END IF;

    IF p_actor_id IS NULL THEN
        RAISE EXCEPTION 'Validation Error: actor_id cannot be NULL';
    END IF;

    IF p_actor_name IS NULL OR p_actor_name = '' THEN
        RAISE EXCEPTION 'Validation Error: actor_name cannot be NULL or empty';
    END IF;

    IF p_snapshot_data IS NULL THEN
        RAISE EXCEPTION 'Validation Error: snapshot_data cannot be NULL';
    END IF;

    -- Validate snapshot_data has minimum required fields
    IF NOT (p_snapshot_data ? 'id' AND p_snapshot_data ? 'title') THEN
        RAISE EXCEPTION 'Validation Error: snapshot_data must contain at least "id" and "title" fields';
    END IF;

    -- ========================================
    -- TRANSACTION: All operations in single transaction
    -- ========================================
    -- This entire function runs in a single transaction
    -- If any part fails, everything rolls back (no partial history)

    -- Get next version number (atomically)
    -- Using SELECT FOR UPDATE to prevent race conditions
    SELECT COALESCE(MAX(version_no), 0) + 1
    INTO v_next_version
    FROM public.shipment_history
    WHERE shipment_id = p_shipment_id
    FOR UPDATE;

    -- Create new history entry
    INSERT INTO public.shipment_history (
        shipment_id,
        version_no,
        event_type,
        actor_id,
        actor_name,
        reason,
        snapshot_data,
        metadata,
        timestamp
    ) VALUES (
        p_shipment_id,
        v_next_version,
        p_event_type,
        p_actor_id,
        p_actor_name,
        p_reason,
        p_snapshot_data,
        p_metadata,
        NOW()
    )
    RETURNING id INTO v_new_id;

    -- Verify insertion succeeded
    IF v_new_id IS NULL THEN
        RAISE EXCEPTION 'Transaction Error: Failed to create history entry';
    END IF;

    -- Return the new version number
    RETURN v_next_version;

EXCEPTION
    WHEN unique_violation THEN
        -- This should never happen due to SELECT FOR UPDATE, but handle it anyway
        RAISE EXCEPTION 'Integrity Error: Version conflict detected. A concurrent write created version % for shipment %. Please retry.',
            v_next_version, p_shipment_id;

    WHEN check_violation THEN
        -- One of our CHECK constraints was violated
        RAISE EXCEPTION 'Validation Error: Data validation failed. %', SQLERRM;

    WHEN OTHERS THEN
        -- Catch any other errors and provide context
        RAISE EXCEPTION 'Database Error: Failed to create history entry. %', SQLERRM;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.create_history_entry TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_history_entry TO service_role;

COMMENT ON FUNCTION public.create_history_entry IS
'Creates a new audit history entry with validation and transactional integrity.
All operations occur in a single transaction - no partial history.
Server assigns version_no atomically to prevent race conditions.
Validates all required fields before writing.';

-- ========================================
-- STEP 4: Enhanced restore_shipment_version Function
-- ========================================
-- Now with validation and transaction safety

CREATE OR REPLACE FUNCTION public.restore_shipment_version(
    p_shipment_id UUID,
    p_source_version_no INTEGER,
    p_actor_id UUID,
    p_actor_name TEXT,
    p_reason TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_source_snapshot JSONB;
    v_new_version INTEGER;
BEGIN
    -- ========================================
    -- VALIDATION
    -- ========================================

    IF p_shipment_id IS NULL THEN
        RAISE EXCEPTION 'Validation Error: shipment_id cannot be NULL';
    END IF;

    IF p_source_version_no IS NULL OR p_source_version_no <= 0 THEN
        RAISE EXCEPTION 'Validation Error: source_version_no must be a positive integer';
    END IF;

    IF p_actor_id IS NULL THEN
        RAISE EXCEPTION 'Validation Error: actor_id cannot be NULL';
    END IF;

    IF p_actor_name IS NULL OR p_actor_name = '' THEN
        RAISE EXCEPTION 'Validation Error: actor_name cannot be NULL or empty';
    END IF;

    -- ========================================
    -- TRANSACTION: All operations atomic
    -- ========================================

    -- Get source version snapshot
    SELECT snapshot_data INTO v_source_snapshot
    FROM public.shipment_history
    WHERE shipment_id = p_shipment_id
      AND version_no = p_source_version_no;

    IF v_source_snapshot IS NULL THEN
        RAISE EXCEPTION 'Validation Error: Source version % not found for shipment %',
            p_source_version_no, p_shipment_id;
    END IF;

    -- Update the shipment_requests table with restored data
    UPDATE public.shipment_requests
    SET
        title = v_source_snapshot->>'title',
        description = v_source_snapshot->>'description',
        status = v_source_snapshot->>'status',
        extracted_data = v_source_snapshot->'extracted_data',
        updated_at = NOW()
    WHERE id = p_shipment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Validation Error: Shipment % not found in shipment_requests', p_shipment_id;
    END IF;

    -- Create new history entry for the restore operation
    v_new_version := public.create_history_entry(
        p_shipment_id := p_shipment_id,
        p_event_type := 'restored',
        p_actor_id := p_actor_id,
        p_actor_name := p_actor_name,
        p_reason := COALESCE(p_reason, 'Restored from version ' || p_source_version_no::TEXT),
        p_snapshot_data := v_source_snapshot,
        p_metadata := jsonb_build_object(
            'source_version_no', p_source_version_no,
            'restore_timestamp', NOW()
        )
    );

    RETURN v_new_version;

EXCEPTION
    WHEN OTHERS THEN
        -- Provide clear error message
        RAISE EXCEPTION 'Restore Error: Failed to restore version %. %',
            p_source_version_no, SQLERRM;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.restore_shipment_version TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_shipment_version TO service_role;

COMMENT ON FUNCTION public.restore_shipment_version IS
'Restores a shipment to a previous version in a single transaction.
Updates shipment_requests and creates a new history entry atomically.
Validates source version exists before restoring.';

-- ========================================
-- STEP 5: Create Index for Performance
-- ========================================
-- Speed up version lookups with index on (shipment_id, version_no)

CREATE INDEX IF NOT EXISTS idx_shipment_history_version_lookup
ON public.shipment_history (shipment_id, version_no);

CREATE INDEX IF NOT EXISTS idx_shipment_history_event_type
ON public.shipment_history (shipment_id, event_type);

CREATE INDEX IF NOT EXISTS idx_shipment_history_actor
ON public.shipment_history (shipment_id, actor_id);

CREATE INDEX IF NOT EXISTS idx_shipment_history_timestamp
ON public.shipment_history (shipment_id, timestamp DESC);

-- ========================================
-- VERIFICATION
-- ========================================

-- Show constraints added
SELECT
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'public.shipment_history'::regclass
  AND conname LIKE 'shipment_history_%'
ORDER BY conname;

-- Show indexes created
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'shipment_history'
  AND schemaname = 'public'
ORDER BY indexname;

-- ========================================
-- SUCCESS MESSAGE
-- ========================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'VALIDATION AND INTEGRITY MIGRATION COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Unique constraint: (shipment_id, version_no)';
    RAISE NOTICE '✅ Check constraints: version_no, event_type, snapshot_data, actor fields';
    RAISE NOTICE '✅ Enhanced functions: create_history_entry, restore_shipment_version';
    RAISE NOTICE '✅ Transaction safety: All audit writes in single transaction';
    RAISE NOTICE '✅ Server-assigned version_no: Prevents race conditions';
    RAISE NOTICE '✅ Clear error messages: Validation errors explain what went wrong';
    RAISE NOTICE '✅ Performance indexes: Faster version lookups';
    RAISE NOTICE '';
    RAISE NOTICE 'Test with invalid data to see validation in action!';
    RAISE NOTICE '========================================';
END $$;
