# Single Table Design Analysis

## Current Design (Two Tables)
```
shipment_audit_events:
- version_no, event_type, actor, timestamp, reason
- field_changes (compact diff)
- metadata

shipment_versions:
- version_no
- snapshot_data (full state)
```

## Proposed Single Table Design

### Option A: Single Table with BOTH Diff and Snapshot
```sql
CREATE TABLE shipment_history (
    id uuid PRIMARY KEY,
    shipment_id uuid NOT NULL,
    version_no integer NOT NULL,
    event_type text NOT NULL,
    actor_id uuid NOT NULL,
    actor_name text,
    timestamp timestamp NOT NULL,
    reason text,
    field_changes jsonb,      -- compact diff (small)
    snapshot_data jsonb,      -- full state (large)
    metadata jsonb,
    UNIQUE(shipment_id, version_no)
);
```

**Pros:**
- ✅ Single table - simpler schema
- ✅ All data in one place
- ✅ One query to get everything

**Cons:**
- ❌ Redundant: Stores BOTH diff AND full snapshot (wastes space)
- ❌ Large rows: Every row is ~10-50KB
- ❌ Unclear purpose: Is it an event log or snapshot store?

### Option B: Single Table with ONLY Snapshot (RECOMMENDED) ✅
```sql
CREATE TABLE shipment_history (
    id uuid PRIMARY KEY,
    shipment_id uuid NOT NULL,
    version_no integer NOT NULL,
    event_type text NOT NULL,
    actor_id uuid NOT NULL,
    actor_name text,
    timestamp timestamp NOT NULL,
    reason text,
    snapshot_data jsonb NOT NULL,  -- full state only
    metadata jsonb,
    UNIQUE(shipment_id, version_no)
);
```

**How it meets requirements:**

1. **Immutable event log** ✅
   - version_no, timestamp, actor, reason ✅
   - Compact diff: **COMPUTED on-the-fly** by comparing consecutive snapshots

2. **Versioning** ✅
   - Auto-incrementing version_no ✅
   - Retrieve exact form data: `SELECT snapshot_data WHERE version_no = X` ✅

3. **Restore** ✅
   - Create new version: Copy snapshot from old version ✅
   - Record metadata: event_type='restored', metadata contains source_version_no ✅

**Pros:**
- ✅ Simpler schema (one table instead of two)
- ✅ No data duplication (only full snapshots)
- ✅ Easier to query and understand
- ✅ Meets all requirements

**Cons:**
- ⚠️ Diffs computed on-demand (slight performance cost)
- ⚠️ Larger rows than pure event log (~10-50KB each)

### Option C: Single Table with ONLY Diffs (Event Sourcing)
```sql
CREATE TABLE shipment_events (
    id uuid PRIMARY KEY,
    shipment_id uuid NOT NULL,
    version_no integer NOT NULL,
    event_type text NOT NULL,
    actor_id uuid NOT NULL,
    timestamp timestamp NOT NULL,
    reason text,
    field_changes jsonb,  -- diff only
    metadata jsonb,
    UNIQUE(shipment_id, version_no)
);
```

**How to get full state:**
1. Start with empty object `{}`
2. Apply diff from version 1
3. Apply diff from version 2
4. Apply diff from version 3
5. Result = current state

**Pros:**
- ✅ Smallest storage (only diffs)
- ✅ True event sourcing pattern

**Cons:**
- ❌ Slow reads: Must reconstruct state by replaying all events
- ❌ Complex: Requires diff application logic
- ❌ Fragile: If one diff corrupted, all future versions break
- ❌ Poor performance: Getting version 100 requires 100 operations

## Recommendation: Option B (Single Table with Snapshots)

**Why this is the best choice:**

1. **Simplest implementation** - meets all requirements without complexity
2. **Fast reads** - direct snapshot lookup, no reconstruction needed
3. **Reliable** - each version independent, no cascading failures
4. **Diffs on-demand** - compute when needed for UI display
5. **Storage acceptable** - 10KB per version is reasonable

## Implementation

I'll migrate from two tables to one table with this approach.
