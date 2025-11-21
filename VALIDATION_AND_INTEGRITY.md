# Validation and Integrity Features

## Overview

The audit system now includes comprehensive validation and integrity guarantees to ensure data quality and prevent corruption of the audit trail.

## Features Implemented

### 1. Unique Constraint on (shipment_id, version_no)
**Location**: Database constraint in `shipment_history` table

**Purpose**: Prevents race conditions where two concurrent writes could assign the same version number

**How it works**:
- Database enforces uniqueness at the constraint level
- If two requests try to create the same version simultaneously, one will succeed and the other will get a clear error message
- Combined with `SELECT FOR UPDATE` in the `create_history_entry` function to lock version number assignment

**Example error**:
```
Integrity Error: Version conflict detected. A concurrent write created version 5 for shipment abc-123. Please retry.
```

### 2. Field Validation with Clear Errors
**Location**: Client-side in [audit_service.py](app/services/audit_service.py) + Server-side in SQL function

**Validates**:
- ✅ `shipment_id` - Cannot be NULL
- ✅ `event_type` - Must be one of: created, updated, status_changed, restored, file_added, file_removed, deleted, archived
- ✅ `actor_id` - Cannot be NULL, must be valid UUID
- ✅ `actor_name` - Cannot be NULL or empty string
- ✅ `snapshot_data` - Cannot be NULL, must be valid JSON dict with at least `id` and `title` fields
- ✅ `version_no` - Must be positive integer (server-assigned)

**Example errors**:
```python
# Missing required field
ValueError: Validation Error: shipment_id is required

# Invalid event type
ValueError: Validation Error: Invalid event_type 'updated_wrong'. Must be one of: archived, created, deleted, file_added, file_removed, restored, status_changed, updated

# Empty actor name
ValueError: Validation Error: actor_name is required and cannot be empty

# Missing snapshot fields
ValueError: Validation Error: snapshot_data missing required fields: id, title
```

### 3. Transaction Safety - No Partial History
**Location**: Database functions with `BEGIN...COMMIT` transaction blocks

**Guarantees**:
- All audit writes occur in a single atomic transaction
- If any part of the operation fails, the entire operation rolls back
- No partial history entries can ever exist in the database

**What's included in the transaction**:
1. Get next version number (with lock)
2. Insert history entry
3. Verify insertion succeeded

For restores:
1. Validate source version exists
2. Update `shipment_requests` table
3. Create new history entry

**If any step fails**: Everything rolls back, database remains in consistent state

### 4. Server-Assigned Version Numbers
**Location**: `create_history_entry` SQL function

**How it works**:
```sql
-- Get next version number atomically
SELECT COALESCE(MAX(version_no), 0) + 1
INTO v_next_version
FROM public.shipment_history
WHERE shipment_id = p_shipment_id
FOR UPDATE;  -- Locks the rows to prevent race conditions
```

**Benefits**:
- Clients cannot specify version numbers (prevents malicious/accidental overwrites)
- Server guarantees sequential version numbers starting from 1
- `SELECT FOR UPDATE` prevents concurrent transactions from getting the same number
- Combined with unique constraint for defense-in-depth

### 5. Enhanced Error Messages
**Location**: Throughout the system

**Before**:
```
Error: Failed to create history entry
```

**After**:
```
Validation Error: Invalid event_type "update". Must be one of: created, updated, status_changed, restored, file_added, file_removed, deleted, archived
```

**Error categories**:
- `Validation Error:` - Invalid input data
- `Integrity Error:` - Constraint violation (e.g., version conflict)
- `Transaction Error:` - Database transaction failed
- `Restore Error:` - Failed to restore a version

## Migration

Run the migration to apply these features:

```sql
-- Run in Supabase SQL Editor
-- File: supabase/migrations/20251121_add_validation_and_integrity.sql
```

This adds:
- Unique constraint on (shipment_id, version_no)
- Check constraints for validation
- Enhanced database functions
- Performance indexes

## API Usage

### Creating an Audit Event

**Endpoint**: `POST /api/shipments/{shipment_id}/audit`

**Valid request**:
```json
{
  "event_type": "updated",
  "actor_id": "user-uuid-here",
  "actor_name": "John Doe",
  "reason": "Updated shipping address",
  "field_changes": {},
  "snapshot_data": {
    "id": "shipment-uuid",
    "title": "Ocean Freight",
    "description": "Shipment to LA",
    "status": "in_transit"
  }
}
```

**Response on success**:
```json
{
  "success": true,
  "version_no": 5,
  "shipment_id": "shipment-uuid",
  "event_type": "updated",
  "timestamp": "2025-11-21T10:30:00Z"
}
```

**Response on validation error** (400):
```json
{
  "detail": "Validation Error: Invalid event_type 'update'. Must be one of: created, updated, status_changed, restored, file_added, file_removed, deleted, archived"
}
```

**Response on integrity error** (500):
```json
{
  "detail": "Integrity Error: Version conflict detected. Please retry."
}
```

### Restoring a Version

**Endpoint**: `POST /api/shipments/{shipment_id}/restore`

**Valid request**:
```json
{
  "source_version_no": 3,
  "actor_id": "user-uuid",
  "actor_name": "John Doe",
  "reason": "Reverting accidental changes"
}
```

**Response on success**:
```json
{
  "success": true,
  "new_version_no": 6,
  "source_version_no": 3,
  "shipment_id": "shipment-uuid",
  "restored_by": "John Doe",
  "timestamp": "2025-11-21T10:35:00Z"
}
```

**Response on validation error** (400):
```json
{
  "detail": "Validation Error: Source version 99 not found for shipment shipment-uuid"
}
```

## Testing Validation

### Test 1: Missing Required Field
```bash
curl -X POST http://localhost:8000/api/shipments/test-id/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "updated",
    "actor_id": "",
    "actor_name": "Test User",
    "snapshot_data": {"id": "test", "title": "Test"}
  }'

# Expected: 400 Bad Request
# Error: "Validation Error: actor_id is required"
```

### Test 2: Invalid Event Type
```bash
curl -X POST http://localhost:8000/api/shipments/test-id/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "invalid_type",
    "actor_id": "user-123",
    "actor_name": "Test User",
    "snapshot_data": {"id": "test", "title": "Test"}
  }'

# Expected: 400 Bad Request
# Error: "Validation Error: Invalid event_type 'invalid_type'..."
```

### Test 3: Missing Snapshot Fields
```bash
curl -X POST http://localhost:8000/api/shipments/test-id/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "updated",
    "actor_id": "user-123",
    "actor_name": "Test User",
    "snapshot_data": {"title": "Test"}
  }'

# Expected: 400 Bad Request
# Error: "Validation Error: snapshot_data missing required fields: id"
```

### Test 4: Race Condition (concurrent writes)
```bash
# Run these two commands simultaneously in different terminals
curl -X POST http://localhost:8000/api/shipments/same-id/audit -d '...'  &
curl -X POST http://localhost:8000/api/shipments/same-id/audit -d '...'  &

# Expected: One succeeds, one gets:
# "Integrity Error: Version conflict detected. Please retry."
```

## Database Constraints

View all constraints:
```sql
SELECT
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'public.shipment_history'::regclass
  AND conname LIKE 'shipment_history_%'
ORDER BY conname;
```

Expected output:
```
shipment_history_actor_not_null       CHECK ((actor_id IS NOT NULL) AND (actor_name IS NOT NULL))
shipment_history_snapshot_not_null    CHECK (snapshot_data IS NOT NULL)
shipment_history_unique_version       UNIQUE (shipment_id, version_no)
shipment_history_valid_event_type     CHECK (event_type IN ('created', 'updated', ...))
shipment_history_version_positive     CHECK (version_no > 0)
```

## Performance Indexes

Indexes added for fast lookups:
```sql
idx_shipment_history_version_lookup   ON (shipment_id, version_no)
idx_shipment_history_event_type       ON (shipment_id, event_type)
idx_shipment_history_actor            ON (shipment_id, actor_id)
idx_shipment_history_timestamp        ON (shipment_id, timestamp DESC)
```

## Benefits

### For Developers
- ✅ Clear, actionable error messages
- ✅ Validation happens before database calls (faster feedback)
- ✅ No need to handle partial state or cleanup failed writes
- ✅ Race conditions prevented automatically

### For Data Integrity
- ✅ No duplicate version numbers possible
- ✅ No partial audit entries
- ✅ No invalid data in history table
- ✅ Guaranteed sequential version numbers
- ✅ Atomic restore operations

### For Users
- ✅ Consistent audit trail (no gaps or duplicates)
- ✅ Reliable restore functionality
- ✅ Clear error messages when something goes wrong
- ✅ No corrupted data

## Rollback

If you need to rollback the migration:

```sql
-- Remove constraints
ALTER TABLE public.shipment_history DROP CONSTRAINT IF EXISTS shipment_history_unique_version;
ALTER TABLE public.shipment_history DROP CONSTRAINT IF EXISTS shipment_history_version_positive;
ALTER TABLE public.shipment_history DROP CONSTRAINT IF EXISTS shipment_history_valid_event_type;
ALTER TABLE public.shipment_history DROP CONSTRAINT IF EXISTS shipment_history_snapshot_not_null;
ALTER TABLE public.shipment_history DROP CONSTRAINT IF EXISTS shipment_history_actor_not_null;

-- Drop indexes
DROP INDEX IF EXISTS idx_shipment_history_version_lookup;
DROP INDEX IF EXISTS idx_shipment_history_event_type;
DROP INDEX IF EXISTS idx_shipment_history_actor;
DROP INDEX IF EXISTS idx_shipment_history_timestamp;

-- Restore original functions (run old versions from previous migration)
```

## Related Files

- [supabase/migrations/20251121_add_validation_and_integrity.sql](supabase/migrations/20251121_add_validation_and_integrity.sql) - Database migration
- [app/services/audit_service.py](app/services/audit_service.py) - Enhanced audit service with validation
- [app/api/routes.py](app/api/routes.py) - API endpoints that use validation
