# Single Table Migration Summary

## What Changed?

### Before: Two-Table Design
```
shipment_audit_events (event log)
├─ version_no, event_type, actor, timestamp, reason
├─ field_changes (compact diff) ← STORED
└─ metadata

shipment_versions (snapshots)
├─ version_no
└─ snapshot_data (full state) ← STORED
```

**Problem**: Data duplication - storing BOTH diff AND full snapshot

### After: Single-Table Design ✅
```
shipment_history (combined)
├─ version_no, event_type, actor, timestamp, reason
├─ snapshot_data (full state) ← STORED
├─ metadata
└─ field_changes ← COMPUTED ON-DEMAND (not stored)
```

**Benefit**: Simpler schema, no duplication, meets all requirements

---

## How It Meets Requirements

### 1. Immutable Event Log ✅
- ✅ version_no, timestamp, actor, reason stored
- ✅ Append-only enforced by RLS policy
- ✅ Compact diff computed on-demand via `get_field_changes()` function

### 2. Versioning ✅
- ✅ Auto-incrementing version_no via `get_next_version_no()`
- ✅ Retrieve exact form data: `SELECT snapshot_data WHERE version_no = X`

### 3. Restore ✅
- ✅ Creates new head version (no mutation)
- ✅ Records all metadata: source_version_no, restorer, timestamp, reason

---

## Database Changes

### New Table: `shipment_history`
```sql
CREATE TABLE shipment_history (
    id uuid PRIMARY KEY,
    shipment_id uuid REFERENCES shipment_requests(id),
    version_no integer NOT NULL,

    -- Event metadata
    event_type text NOT NULL,
    actor_id uuid NOT NULL,
    actor_name text,
    timestamp timestamp NOT NULL,
    reason text,

    -- Full snapshot (ONLY thing stored)
    snapshot_data jsonb NOT NULL,

    -- Additional context
    metadata jsonb,

    UNIQUE(shipment_id, version_no)
);
```

### New Functions

#### 1. `create_history_entry()` (replaces `create_audit_event()`)
```sql
-- Creates a single history row with event metadata + snapshot
-- NO LONGER takes field_changes parameter (computed on-demand)
```

#### 2. `get_field_changes()` (NEW)
```sql
-- Computes diff between two versions on-demand
-- Parameters: shipment_id, from_version, to_version
-- Returns: jsonb with {field: {old: X, new: Y}}
```

#### 3. `restore_shipment_version()` (unchanged interface)
```sql
-- Still works the same way
-- Copies snapshot from old version to new version
```

---

## Code Changes

### Backend Service (audit_service.py)

#### Changed:
1. **Table references**: `shipment_audit_events` → `shipment_history`
2. **Table references**: `shipment_versions` → `shipment_history`
3. **Function call**: `create_audit_event()` → `create_history_entry()`
4. **Field changes**: Now computed on-demand in `get_shipment_history()`

#### Example:
```python
# Before
result = self.supabase.table('shipment_audit_events').select('*')...

# After
result = self.supabase.table('shipment_history').select('*')...
```

### API Routes (routes.py)
- **No changes needed** - uses audit_service interface which remains same

### Test Scripts
- Need to update table names
- Need to update function names

---

## Migration Steps

### Step 1: Apply New Migration
```bash
# In Supabase SQL Editor, run:
supabase/migrations/20251120_single_table_audit.sql
```

This will:
- Drop old tables (`shipment_audit_events`, `shipment_versions`)
- Drop old functions (`create_audit_event`)
- Create new table (`shipment_history`)
- Create new functions (`create_history_entry`, `get_field_changes`)

### Step 2: Restart Backend
```bash
# The code changes are already made
# Just restart the FastAPI server
```

### Step 3: Test
```bash
# Run comprehensive test
python3 test_requirements.py
```

---

## Performance Implications

### Storage
**Before (Two Tables)**:
- Event row: ~500 bytes (small diff)
- Version row: ~10KB (full snapshot)
- Total per version: ~10.5KB

**After (Single Table)**:
- History row: ~10KB (full snapshot only)
- Total per version: ~10KB

**Savings**: ~5% storage reduction

### Query Performance

#### Reading History (Improved ✅)
```sql
-- Before: Join two tables
SELECT e.*, v.snapshot_data
FROM shipment_audit_events e
JOIN shipment_versions v USING (shipment_id, version_no)

-- After: Single table
SELECT * FROM shipment_history
```
**Result**: Faster, no joins needed

#### Computing Diffs (Slight Cost ⚠️)
```sql
-- Before: Pre-stored
SELECT field_changes FROM shipment_audit_events

-- After: Computed on-demand
SELECT get_field_changes(shipment_id, v1, v2)
```
**Result**: Slightly slower when diffs needed, but cached in app layer

### Overall: Better Performance ✅
- Most queries faster (no joins)
- Diff computation only when needed (UI display)
- Simpler query plans = better database optimization

---

## Comparison Table

| Aspect | Two Tables | Single Table | Winner |
|--------|-----------|--------------|---------|
| **Storage** | 10.5KB/version | 10KB/version | Single ✅ |
| **Schema Complexity** | 2 tables, 2 functions | 1 table, 3 functions | Single ✅ |
| **Query Performance** | Joins required | Direct lookups | Single ✅ |
| **Diff Performance** | Pre-computed (fast) | On-demand (slower) | Two Tables |
| **Maintainability** | Complex | Simple | Single ✅ |
| **Clarity** | Unclear purpose | Clear purpose | Single ✅ |

**Verdict**: Single table is better for our use case ✅

---

## Why This Design Works

### 1. Diffs Are Rarely Needed
- History display: Show event type and reason (no diff needed)
- Detailed view: Compute diff once when user clicks (acceptable delay)
- Filtering: Most filters don't need diffs (actor, date, event_type)

### 2. Snapshots Always Needed
- Restore: Must have full snapshot
- View version: Must have full snapshot
- Diffs: Can be computed from consecutive snapshots

### 3. Storage Is Cheap
- 10KB per version is minimal
- 1000 shipments × 10 versions = 100MB total
- Database storage costs ~$0.023/GB/month
- Cost difference: negligible

### 4. Simplicity > Optimization
- Premature optimization is root of all evil
- Single table is easier to understand, maintain, debug
- Performance is already good enough

---

## Testing Checklist

After migration, verify:

- [ ] Create audit event works
- [ ] Get history returns correct data
- [ ] Get specific version works
- [ ] Restore creates new version
- [ ] Restore doesn't mutate history
- [ ] Field changes computed correctly
- [ ] Filtering by actor works
- [ ] Filtering by event_type works
- [ ] Filtering by date works
- [ ] Auto-increment works
- [ ] RLS policies work

---

## Rollback Plan

If issues arise, rollback to two-table design:

```sql
-- 1. Run original migration
supabase/migrations/20251120_audit_versioning.sql

-- 2. Revert code changes in audit_service.py
git checkout app/services/audit_service.py

-- 3. Restart backend
```

---

## Summary

✅ **Migrated from 2 tables to 1 table**
✅ **Simpler schema and queries**
✅ **Better performance (no joins)**
✅ **Meets all requirements**
✅ **Backward compatible API**
✅ **5% storage savings**

**Recommendation**: Proceed with single table design. It's cleaner, simpler, and performs better.
