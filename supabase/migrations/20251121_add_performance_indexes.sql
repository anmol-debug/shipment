-- ========================================
-- PERFORMANCE INDEXES FOR SHIPMENT HISTORY
-- ========================================
-- Adds optimized indexes for common query patterns
-- These indexes speed up version lookups and history queries
-- ========================================

-- Drop old indexes if they exist (to replace with better ones)
DROP INDEX IF EXISTS public.idx_shipment_history_version_lookup;

-- ========================================
-- INDEX 1: (shipment_id, version_no DESC)
-- ========================================
-- Optimized for: Getting latest versions first
-- Query pattern: SELECT * FROM shipment_history WHERE shipment_id = ? ORDER BY version_no DESC
CREATE INDEX IF NOT EXISTS idx_shipment_history_version_desc
ON public.shipment_history (shipment_id, version_no DESC);

COMMENT ON INDEX public.idx_shipment_history_version_desc IS
'Optimized index for fetching shipment history ordered by version (latest first).
Speeds up queries like: SELECT * FROM shipment_history WHERE shipment_id = X ORDER BY version_no DESC';

-- ========================================
-- INDEX 2: (shipment_id, timestamp DESC)
-- ========================================
-- Already exists from previous migration, but ensuring it's there
-- Optimized for: Getting history ordered by time
-- Query pattern: SELECT * FROM shipment_history WHERE shipment_id = ? ORDER BY timestamp DESC
CREATE INDEX IF NOT EXISTS idx_shipment_history_timestamp_desc
ON public.shipment_history (shipment_id, timestamp DESC);

COMMENT ON INDEX public.idx_shipment_history_timestamp_desc IS
'Optimized index for fetching shipment history ordered by timestamp (latest first).
Speeds up queries like: SELECT * FROM shipment_history WHERE shipment_id = X ORDER BY timestamp DESC';

-- ========================================
-- ADDITIONAL PERFORMANCE INDEXES
-- ========================================

-- Index for actor-based queries (who made changes)
CREATE INDEX IF NOT EXISTS idx_shipment_history_actor
ON public.shipment_history (actor_id, timestamp DESC);

COMMENT ON INDEX public.idx_shipment_history_actor IS
'Optimized for querying all changes made by a specific user.
Speeds up queries like: SELECT * FROM shipment_history WHERE actor_id = X ORDER BY timestamp DESC';

-- Index for event type filtering
CREATE INDEX IF NOT EXISTS idx_shipment_history_event_type
ON public.shipment_history (shipment_id, event_type, timestamp DESC);

COMMENT ON INDEX public.idx_shipment_history_event_type IS
'Optimized for filtering history by event type (e.g., show only status_changed events).
Speeds up queries like: SELECT * FROM shipment_history WHERE shipment_id = X AND event_type = Y';

-- Composite index for common filter pattern
CREATE INDEX IF NOT EXISTS idx_shipment_history_composite
ON public.shipment_history (shipment_id, timestamp DESC, version_no DESC);

COMMENT ON INDEX public.idx_shipment_history_composite IS
'Composite index for complex queries involving both timestamp and version ordering';

-- ========================================
-- VERIFY INDEXES
-- ========================================

-- Show all indexes on shipment_history table
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
    RAISE NOTICE 'PERFORMANCE INDEXES CREATED';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ idx_shipment_history_version_desc: (shipment_id, version_no DESC)';
    RAISE NOTICE '✅ idx_shipment_history_timestamp_desc: (shipment_id, timestamp DESC)';
    RAISE NOTICE '✅ idx_shipment_history_actor: (actor_id, timestamp DESC)';
    RAISE NOTICE '✅ idx_shipment_history_event_type: (shipment_id, event_type, timestamp DESC)';
    RAISE NOTICE '✅ idx_shipment_history_composite: (shipment_id, timestamp DESC, version_no DESC)';
    RAISE NOTICE '';
    RAISE NOTICE 'These indexes optimize common query patterns:';
    RAISE NOTICE '- Fetching latest versions (ORDER BY version_no DESC)';
    RAISE NOTICE '- Fetching recent changes (ORDER BY timestamp DESC)';
    RAISE NOTICE '- Filtering by actor or event type';
    RAISE NOTICE '========================================';
END $$;
