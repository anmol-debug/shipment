# 🧪 Audit API Testing Guide

## Step-by-Step Testing Instructions

### Prerequisites
1. ✅ Server is running at `http://localhost:8000`
2. ✅ Database migrations have been run in Supabase

### Open the Test Page

Open `test_audit_api.html` in your browser:
```bash
open test_audit_api.html
```

---

## 📝 Test Scenario: Track Changes to a Shipment

Let's simulate a real-world workflow where a shipment goes through multiple changes.

### **Step 1: Create Initial Shipment (Version 1)**

**What we're doing:** Recording the creation of a new shipment.

1. Scroll to **"1️⃣ Create Audit Event"** section
2. Use these pre-filled values:
   ```
   Shipment ID: test-shipment-123
   Event Type: created
   Actor ID: user-001
   Actor Name: John Doe
   Reason: Initial shipment creation

   Field Changes: {}  (empty for creation)

   Snapshot Data:
   {
     "title": "Ocean Shipment to Los Angeles",
     "status": "pending",
     "containerNumber": "ABCD1234567",
     "billOfLadingNumber": "BL123456",
     "origin": "Shanghai",
     "destination": "Los Angeles"
   }
   ```

3. Click **"Create Audit Event"**

**Expected Response:**
```json
{
  "success": true,
  "version_no": 1,
  "shipment_id": "test-shipment-123",
  "event_type": "created",
  "timestamp": "2025-11-20T21:50:00Z"
}
```

✅ **What happened:** Version 1 created with initial shipment data.

---

### **Step 2: Update Container Number (Version 2)**

**What we're doing:** Simulating a user correcting a typo in the container number.

1. Stay in **"1️⃣ Create Audit Event"** section
2. Change these values:
   ```
   Event Type: updated
   Reason: Fixed typo in container number

   Field Changes:
   {
     "containerNumber": {
       "old": "ABCD1234567",
       "new": "EFGH9876543"
     }
   }

   Snapshot Data:
   {
     "title": "Ocean Shipment to Los Angeles",
     "status": "pending",
     "containerNumber": "EFGH9876543",  ← Changed
     "billOfLadingNumber": "BL123456",
     "origin": "Shanghai",
     "destination": "Los Angeles"
   }
   ```

3. Click **"Create Audit Event"**

**Expected Response:**
```json
{
  "success": true,
  "version_no": 2,
  "shipment_id": "test-shipment-123",
  "event_type": "updated",
  "timestamp": "2025-11-20T21:51:00Z"
}
```

✅ **What happened:** Version 2 created. We can now see what changed (container number).

---

### **Step 3: Change Status to Completed (Version 3)**

**What we're doing:** Marking the shipment as completed.

1. Change these values:
   ```
   Event Type: status_changed
   Reason: Shipment delivered successfully

   Field Changes:
   {
     "status": {
       "old": "pending",
       "new": "completed"
     }
   }

   Snapshot Data:
   {
     "title": "Ocean Shipment to Los Angeles",
     "status": "completed",  ← Changed
     "containerNumber": "EFGH9876543",
     "billOfLadingNumber": "BL123456",
     "origin": "Shanghai",
     "destination": "Los Angeles"
   }
   ```

2. Click **"Create Audit Event"**

**Expected Response:**
```json
{
  "success": true,
  "version_no": 3,
  "shipment_id": "test-shipment-123",
  "event_type": "status_changed",
  "timestamp": "2025-11-20T21:52:00Z"
}
```

✅ **What happened:** Version 3 created. Shipment is now "completed".

---

### **Step 4: View Complete History**

**What we're doing:** See all changes we just made.

1. Scroll down to **"2️⃣ Get Shipment History"** section
2. Shipment ID should already be `test-shipment-123`
3. Click **"Get History"**

**Expected Response:**
```json
{
  "success": true,
  "shipment_id": "test-shipment-123",
  "count": 3,
  "history": [
    {
      "id": "...",
      "version_no": 3,
      "event_type": "status_changed",
      "actor_name": "John Doe",
      "timestamp": "2025-11-20T21:52:00Z",
      "reason": "Shipment delivered successfully",
      "field_changes": {
        "status": {"old": "pending", "new": "completed"}
      }
    },
    {
      "id": "...",
      "version_no": 2,
      "event_type": "updated",
      "actor_name": "John Doe",
      "timestamp": "2025-11-20T21:51:00Z",
      "reason": "Fixed typo in container number",
      "field_changes": {
        "containerNumber": {"old": "ABCD1234567", "new": "EFGH9876543"}
      }
    },
    {
      "id": "...",
      "version_no": 1,
      "event_type": "created",
      "actor_name": "John Doe",
      "timestamp": "2025-11-20T21:50:00Z",
      "reason": "Initial shipment creation",
      "field_changes": {}
    }
  ]
}
```

✅ **What we see:** Complete audit trail showing all 3 changes in reverse chronological order.

---

### **Step 5: View Specific Version**

**What we're doing:** See exactly what the shipment looked like at version 1.

1. Scroll to **"3️⃣ Get Specific Version"** section
2. Enter:
   ```
   Shipment ID: test-shipment-123
   Version Number: 1
   ```
3. Click **"Get Version"**

**Expected Response:**
```json
{
  "success": true,
  "version": {
    "id": "...",
    "shipment_id": "test-shipment-123",
    "version_no": 1,
    "snapshot_data": {
      "title": "Ocean Shipment to Los Angeles",
      "status": "pending",
      "containerNumber": "ABCD1234567",  ← Original container number
      "billOfLadingNumber": "BL123456",
      "origin": "Shanghai",
      "destination": "Los Angeles"
    },
    "created_at": "2025-11-20T21:50:00Z",
    "created_by": "user-001"
  }
}
```

✅ **What we see:** The original shipment data before any changes.

---

### **Step 6: Compare Versions (Manual Diff)**

Compare version 1 and version 3:

**Version 1:**
- Container Number: `ABCD1234567`
- Status: `pending`

**Version 3:**
- Container Number: `EFGH9876543` ← Changed
- Status: `completed` ← Changed

---

### **Step 7: Restore to Previous Version**

**What we're doing:** Oops! We marked it as completed by mistake. Let's restore to version 2.

1. Scroll to **"4️⃣ Restore to Previous Version"** section
2. Enter:
   ```
   Shipment ID: test-shipment-123
   Source Version Number: 2
   Actor ID: user-001
   Actor Name: John Doe
   Reason: Accidentally marked as completed, reverting
   ```
3. Click **"Restore Version"**

**Expected Response:**
```json
{
  "success": true,
  "new_version_no": 4,
  "source_version_no": 2,
  "shipment_id": "test-shipment-123",
  "restored_by": "John Doe",
  "timestamp": "2025-11-20T21:53:00Z"
}
```

✅ **What happened:**
- Created version 4 with the data from version 2
- Status is back to "pending"
- Container number is still "EFGH9876543" (from version 2)
- The restore itself is tracked as an audit event!

---

### **Step 8: Filter Events by Type**

**What we're doing:** Find only the "updated" events.

1. Scroll to **"5️⃣ Filter Audit Events"** section
2. Enter:
   ```
   Shipment ID: test-shipment-123
   Event Type: updated
   ```
3. Leave other fields empty
4. Click **"Filter Events"**

**Expected Response:**
```json
{
  "success": true,
  "shipment_id": "test-shipment-123",
  "count": 1,
  "events": [
    {
      "version_no": 2,
      "event_type": "updated",
      "actor_name": "John Doe",
      "timestamp": "2025-11-20T21:51:00Z",
      "reason": "Fixed typo in container number"
    }
  ]
}
```

✅ **What we see:** Only the update event (version 2).

---

## 🎬 Real-World Use Cases

### Use Case 1: Compliance Audit
**Question:** "Who changed the container number and when?"

**Answer:**
1. Go to "Filter Audit Events"
2. Set `field_name: containerNumber`
3. Get complete history of all container number changes with actor and timestamp

### Use Case 2: Undo Mistakes
**Question:** "User accidentally deleted critical data, how do I recover?"

**Answer:**
1. Get history to find the last good version
2. Use "Restore Version" to roll back
3. The restore itself is tracked for accountability

### Use Case 3: Dispute Resolution
**Question:** "Customer claims we changed their destination without permission"

**Answer:**
1. Get shipment history
2. Show audit trail with actor_id, timestamp, and field_changes
3. Prove who made the change and when

---

## 🔍 Understanding the Response Colors

- **Green Background** = Success (HTTP 200)
- **Red Background** = Error (HTTP 400/500)
- **Gray Background** = Server not running

---

## 🐛 Common Errors

### Error: "Server not responding"
**Fix:** Make sure the server is running:
```bash
cd /Users/anmolgewal/take_home
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Error: "Invalid JSON"
**Fix:** Make sure Field Changes and Snapshot Data are valid JSON (use quotes around keys and values)

### Error: "Shipment not found"
**Fix:** The shipment must exist in `shipment_requests` table first. For testing, we're using a fake ID which works because the database functions don't check existence.

---

## 📊 View Data in Supabase

After testing, view the data in Supabase:

1. Go to: https://supabase.com/dashboard/project/prfmsfczqmbciwywxrga
2. Click: **Table Editor**
3. View tables:
   - `shipment_audit_events` - See all events
   - `shipment_versions` - See all version snapshots

---

## ✅ What You've Learned

1. **Create audit events** - Track every change with context
2. **View history** - See complete audit trail
3. **Get specific versions** - Time travel to any point
4. **Restore versions** - Undo changes safely
5. **Filter events** - Search by actor, type, field, or date

Your audit system is now fully functional! 🎉
