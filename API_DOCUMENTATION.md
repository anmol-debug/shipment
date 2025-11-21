# Audit & Versioning API Documentation

## 🎯 Overview

The audit and versioning system provides complete change tracking and version history for shipments. Every change is recorded, and you can restore to any previous version.

## 📡 API Endpoints

Base URL: `http://localhost:8000/api`

---

### 1. **Get Shipment History**

Get the complete audit trail for a shipment.

**Endpoint**: `GET /shipments/{shipment_id}/history`

**Query Parameters**:
- `limit` (optional): Max results (default: 50, max: 100)
- `offset` (optional): Skip N results (default: 0)

**Example**:
```bash
curl http://localhost:8000/api/shipments/abc-123/history?limit=20
```

**Response**:
```json
{
  "success": true,
  "shipment_id": "abc-123",
  "count": 3,
  "history": [
    {
      "id": "event-1",
      "version_no": 3,
      "event_type": "updated",
      "actor_name": "John Doe",
      "timestamp": "2025-11-20T10:30:00Z",
      "reason": "Fixed container number",
      "field_changes": {
        "containerNumber": {
          "old": "ABCD1234567",
          "new": "EFGH9876543"
        }
      }
    },
    ...
  ]
}
```

---

### 2. **Get Specific Version**

Retrieve the complete shipment data as it existed at a specific version.

**Endpoint**: `GET /shipments/{shipment_id}/versions/{version_no}`

**Example**:
```bash
curl http://localhost:8000/api/shipments/abc-123/versions/2
```

**Response**:
```json
{
  "success": true,
  "version": {
    "id": "version-2",
    "shipment_id": "abc-123",
    "version_no": 2,
    "snapshot_data": {
      "title": "Ocean Shipment",
      "status": "pending",
      "extracted_data": { ... },
      ...
    },
    "created_at": "2025-11-20T09:15:00Z",
    "created_by": "user-id"
  }
}
```

---

### 3. **Create Audit Event**

Record a change to a shipment (automatically creates a new version).

**Endpoint**: `POST /shipments/{shipment_id}/audit`

**Body**:
```json
{
  "event_type": "updated",
  "actor_id": "user-123",
  "actor_name": "John Doe",
  "reason": "Updated container number",
  "field_changes": {
    "containerNumber": {
      "old": "ABCD1234567",
      "new": "EFGH9876543"
    }
  },
  "snapshot_data": {
    "title": "Ocean Shipment",
    "status": "pending",
    "containerNumber": "EFGH9876543",
    ...
  },
  "metadata": {
    "ip_address": "192.168.1.1",
    "user_agent": "Mozilla/5.0..."
  }
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/api/shipments/abc-123/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "updated",
    "actor_id": "user-123",
    "actor_name": "John Doe",
    "field_changes": {"status": {"old": "pending", "new": "completed"}},
    "snapshot_data": {"title": "Ocean Shipment", "status": "completed"}
  }'
```

**Response**:
```json
{
  "success": true,
  "version_no": 4,
  "shipment_id": "abc-123",
  "event_type": "updated",
  "timestamp": "2025-11-20T10:45:00Z"
}
```

---

### 4. **Restore Version**

Restore a shipment to a previous version (creates a new version with old data).

**Endpoint**: `POST /shipments/{shipment_id}/restore`

**Body**:
```json
{
  "source_version_no": 2,
  "actor_id": "user-123",
  "actor_name": "John Doe",
  "reason": "Reverting incorrect changes"
}
```

**Example**:
```bash
curl -X POST http://localhost:8000/api/shipments/abc-123/restore \
  -H "Content-Type: application/json" \
  -d '{
    "source_version_no": 2,
    "actor_id": "user-123",
    "actor_name": "John Doe",
    "reason": "Reverting incorrect changes"
  }'
```

**Response**:
```json
{
  "success": true,
  "new_version_no": 5,
  "source_version_no": 2,
  "shipment_id": "abc-123",
  "restored_by": "John Doe",
  "timestamp": "2025-11-20T11:00:00Z"
}
```

---

### 5. **Filter Audit Events**

Filter audit events by actor, event type, date range, or field changed.

**Endpoint**: `GET /shipments/{shipment_id}/filter`

**Query Parameters**:
- `actor_id` (optional): Filter by who made the change
- `event_type` (optional): Filter by type (created, updated, restored, etc.)
- `field_name` (optional): Filter by which field was changed
- `start_date` (optional): ISO date (e.g., `2025-11-01T00:00:00`)
- `end_date` (optional): ISO date
- `limit` (optional): Max results (default: 50)

**Example**:
```bash
# Get all updates by John Doe
curl "http://localhost:8000/api/shipments/abc-123/filter?actor_id=user-123&event_type=updated"

# Get changes to status field
curl "http://localhost:8000/api/shipments/abc-123/filter?field_name=status"

# Get changes in date range
curl "http://localhost:8000/api/shipments/abc-123/filter?start_date=2025-11-01T00:00:00&end_date=2025-11-30T23:59:59"
```

**Response**:
```json
{
  "success": true,
  "shipment_id": "abc-123",
  "count": 2,
  "events": [ ... ],
  "filters": {
    "actor_id": "user-123",
    "event_type": "updated",
    "field_name": null,
    "start_date": null,
    "end_date": null
  }
}
```

---

## 🎬 Usage Flow

### Typical Workflow:

1. **User creates a shipment** → Automatic audit event (type: `created`, version: 1)
2. **User edits container number** → Call `POST /shipments/{id}/audit` (version: 2)
3. **User changes status** → Call `POST /shipments/{id}/audit` (version: 3)
4. **User wants to see history** → Call `GET /shipments/{id}/history`
5. **User wants to restore version 1** → Call `POST /shipments/{id}/restore` (creates version: 4 with version 1's data)

---

## 📝 Event Types

- `created` - Shipment initially created
- `updated` - General field update
- `status_changed` - Status field specifically changed
- `file_added` - File uploaded
- `file_removed` - File deleted
- `restored` - Restored from a previous version

---

## 🔒 Security & Permissions

All endpoints respect Row Level Security (RLS) policies:
- Users can only access shipments they have permission to view
- RLS is enforced at the database level
- `actor_id` must match authenticated user

---

## 🧪 Testing the API

### Step 1: Start the server
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Step 2: Create a test shipment
```bash
# First create a shipment in Supabase Table Editor with ID: test-123
```

### Step 3: Create an audit event
```bash
curl -X POST http://localhost:8000/api/shipments/test-123/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "created",
    "actor_id": "user-1",
    "actor_name": "Test User",
    "field_changes": {},
    "snapshot_data": {
      "title": "Test Shipment",
      "status": "pending"
    }
  }'
```

### Step 4: View history
```bash
curl http://localhost:8000/api/shipments/test-123/history
```

---

## 📊 What Gets Stored

### In `shipment_audit_events` table:
- `version_no` - Auto-incremented version number
- `event_type` - What happened
- `actor_id` - Who did it
- `timestamp` - When it happened
- `field_changes` - What changed (JSON)
- `reason` - Why (optional)

### In `shipment_versions` table:
- `version_no` - Version number
- `snapshot_data` - Complete shipment state (JSON)
- `created_at` - When this version was created
- `created_by` - Who created it

This allows:
✅ View complete history
✅ See exact changes between versions
✅ Restore to any previous state
✅ Track who made what changes
✅ Filter/search history
