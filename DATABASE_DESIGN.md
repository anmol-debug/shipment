# Audit & Versioning Database Design

## Current Design: Two-Table Approach

### Tables

#### 1. `shipment_audit_events` - The "What Happened" Log
```sql
- id: uuid (primary key)
- shipment_id: uuid → references shipment_requests(id)
- version_no: integer (auto-incrementing per shipment)
- event_type: text (created, updated, status_changed, restored, etc.)
- actor_id: uuid → references auth.users(id)
- actor_name: text
- timestamp: timestamp
- reason: text
- field_changes: jsonb (compact diff, e.g., {"containerNumber": {"old": "ABC", "new": "XYZ"}})
- metadata: jsonb (IP, user agent, etc.)
```

**Purpose**: Immutable append-only event log. Records **WHAT** changed, **WHO** changed it, **WHEN**, and **WHY**.

#### 2. `shipment_versions` - The "Full State" Snapshots
```sql
- id: uuid (primary key)
- shipment_id: uuid → references shipment_requests(id)
- version_no: integer
- snapshot_data: jsonb (COMPLETE shipment data at this version)
- created_at: timestamp
- created_by: uuid → references auth.users(id)
```

**Purpose**: Full snapshots at each version. Records the **COMPLETE STATE** of the shipment.

#### 3. `shipment_requests` - The "Current State" Table
```sql
- id: uuid (primary key)
- title: text
- description: text
- extracted_data: jsonb
- status: text
- user_id: uuid
- ... other fields
```

**Purpose**: The **CURRENT/LIVE** state of the shipment.

---

## Why Two Tables Instead of One?

### Option 1: Single Table (What if we combined them?)
```sql
shipment_history:
  - version_no
  - event_type
  - actor_id
  - timestamp
  - field_changes (diff)
  - snapshot_data (full state)
  - reason
  - metadata
```

**Problems with Single Table:**
1. **Data Duplication**: Every row stores BOTH diff AND full snapshot (wastes space)
2. **Unclear Purpose**: Is it an event log or a snapshot store? Confusing for developers
3. **Query Performance**: Mixing small diffs with large snapshots hurts cache performance
4. **Index Bloat**: Different query patterns (event filtering vs snapshot retrieval) need different indexes

### Option 2: Two Tables (Current Design) ✅

**Benefits:**
1. **Separation of Concerns**:
   - `audit_events` = lightweight event log (small rows, ~1KB each)
   - `versions` = complete snapshots (larger rows, ~10-50KB each)

2. **Query Optimization**:
   - Filtering events by actor/date → fast, uses small `audit_events` table
   - Retrieving full snapshot → uses `versions` table with efficient indexes

3. **Storage Efficiency**:
   - Can purge old snapshots while keeping event log
   - Can compress snapshots differently than events

4. **Clear Data Model**:
   - 1 event = 1 version (enforced by foreign key)
   - Easy to understand: "Each event creates a version"

---

## How Values Reference Each Other

### Relationships:
```
shipment_requests (id: UUID)
    ↓ (shipment_id)
    ├─→ shipment_audit_events (shipment_id, version_no)
    │       ↓ (foreign key constraint)
    └─→ shipment_versions (shipment_id, version_no)

auth.users (id: UUID)
    ↓ (actor_id / created_by)
    ├─→ shipment_audit_events (actor_id)
    └─→ shipment_versions (created_by)
```

### Key Constraints:
1. **Unique version per shipment**: `(shipment_id, version_no)` is unique in both tables
2. **Paired relationship**: Every audit event MUST have a matching version snapshot
   - Enforced by: `FOREIGN KEY (shipment_id, version_no) REFERENCES shipment_audit_events`
3. **Auto-incrementing versions**: `get_next_version_no()` ensures versions increment without gaps

---

## How Restore Works: Copying vs Pointing

### Current Implementation: **COPYING** ✅

```sql
-- Step 1: Get snapshot from version 2
SELECT snapshot_data FROM shipment_versions
WHERE shipment_id = '...' AND version_no = 2;
-- Returns: {"title": "Old Title", "status": "pending", ...}

-- Step 2: Create NEW version 5 with SAME data (COPY)
INSERT INTO shipment_versions (shipment_id, version_no, snapshot_data)
VALUES ('...', 5, '{"title": "Old Title", "status": "pending", ...}');

-- Step 3: Update current state
UPDATE shipment_requests
SET title = 'Old Title', status = 'pending', ...
WHERE id = '...';
```

**What happens:**
- Version 2 snapshot: `{"title": "Old Title"}` (stored at address 0x1000)
- Version 5 snapshot: `{"title": "Old Title"}` (stored at address 0x2000) ← **NEW COPY**
- Both contain identical data but are **separate rows**

**Why Copying Instead of Pointing?**

#### Option A: Copying (Current) ✅
```json
Version 2: {"title": "Old Title", "status": "pending"}  ← Original
Version 5: {"title": "Old Title", "status": "pending"}  ← Copy
```

**Pros:**
- ✅ Simple to understand and query
- ✅ Self-contained: Version 5 has ALL data, no joins needed
- ✅ Safe: If version 2 is corrupted/deleted, version 5 still works
- ✅ Fast reads: Single row lookup, no pointer chasing

**Cons:**
- ❌ Storage overhead: Duplicates data
- ❌ Wastes space if many restores to same version

#### Option B: Pointing (Alternative)
```json
Version 2: {"title": "Old Title", "status": "pending"}  ← Original
Version 5: {"points_to": 2}                             ← Pointer
```

**Pros:**
- ✅ Saves storage space
- ✅ Clear relationship: "Version 5 is restored from version 2"

**Cons:**
- ❌ Complex queries: Must follow pointers recursively
- ❌ Slower reads: Requires joins or multiple queries
- ❌ Fragile: If version 2 is deleted, version 5 breaks
- ❌ Harder to optimize: Database can't cache pointer chains well

### Our Choice: Copying
We use **copying** because:
1. **Simplicity**: Queries remain simple (`SELECT snapshot_data WHERE version_no = 5`)
2. **Reliability**: Each version is independent, no cascading failures
3. **Performance**: Fast reads, no joins needed
4. **Storage is cheap**: Disk space is less expensive than complexity

---

## Optimization Opportunities

### 1. Deduplication with Content-Addressable Storage (Future)
```sql
-- Add a content hash
ALTER TABLE shipment_versions ADD COLUMN snapshot_hash text;

-- Store unique snapshots in separate table
CREATE TABLE snapshot_blobs (
  hash text PRIMARY KEY,
  data jsonb
);

-- Point to deduplicated data
shipment_versions:
  - version_no: 5
  - snapshot_hash: "abc123..." → references snapshot_blobs(hash)
```

**When to use**: If you have many identical restores (unlikely in practice)

### 2. Compress Old Snapshots
```sql
-- After 90 days, compress snapshots
UPDATE shipment_versions
SET snapshot_data = compress(snapshot_data)
WHERE created_at < now() - interval '90 days';
```

### 3. Partition by Time
```sql
-- Partition versions table by year
CREATE TABLE shipment_versions_2024 PARTITION OF shipment_versions
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

### 4. Selective Snapshot Storage
Instead of storing FULL snapshots every time, could store:
- Version 1: Full snapshot
- Version 2: Diff from version 1
- Version 3: Diff from version 2
- Version 10: Full snapshot (every 10th version)

**Trade-off**: Saves space but requires reconstruction to retrieve data

---

## Current Storage Estimate

### Per Version:
- **Audit Event**: ~500 bytes (small diff + metadata)
- **Version Snapshot**: ~10KB (full shipment data)
- **Total**: ~10.5KB per version

### For 1000 Shipments with 10 Versions Each:
- Total rows: 10,000 audit events + 10,000 versions = 20,000 rows
- Storage: 10,000 * 10.5KB = ~105MB
- With indexes: ~150MB

**Verdict**: Very manageable for most use cases. No optimization needed until millions of versions.

---

## Summary

| Aspect | Current Design | Why? |
|--------|---------------|------|
| **Tables** | Two (events + versions) | Separation of concerns, better performance |
| **Restore** | Copying data | Simplicity, reliability, fast reads |
| **References** | UUID foreign keys | Standard relational model |
| **Version Increment** | Auto-increment per shipment | No gaps, easy to track |
| **Immutability** | Append-only with RLS | Enforced at database level |

**Recommendation**: Current design is solid. No changes needed unless you hit >100K versions per shipment.
