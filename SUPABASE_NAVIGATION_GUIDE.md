# How to Test Everything - Complete Guide

## ✅ What You've Built

1. **Backend API** - FastAPI with 5 audit endpoints (Running on port 8000)
2. **Database** - Single `shipment_history` table in Supabase
3. **Frontend** - React app with History UI drawer

---

## Step 1: Start the Frontend

```bash
cd /Users/anmolgewal/take_home/frontend
npm start
```

Frontend will run on: **http://localhost:3000**

---

## Step 2: Test the Complete Flow

### A. Upload & Extract (Your Original Feature)
1. Open http://localhost:3000
2. Upload Bill of Lading (.pdf) and Invoice (.xlsx)
3. See extracted data in editable form

### B. View History (New Feature)
1. Click **"📜 View History"** button (top right)
2. History drawer slides in from the right
3. See list of all versions for this shipment

### C. Test Actions

**View Action:**
- Click "View" on any version
- See full snapshot of that version's data
- Click "← Back to List" to return

**Diff Action:**
- Click "Diff" on version 2
- Click "Diff" on version 3
- See side-by-side comparison of changes
- Changed fields highlighted in yellow

**Restore Action:**
- Click "Restore" on version 2
- Confirm restoration
- Enter a reason (e.g., "Undo mistake")
- New version 5 created with version 2's data

### D. Test Filters

**Filter by Actor:**
- Type "Test User" in actor filter
- See only events by Test User

**Filter by Event Type:**
- Select "restored" from dropdown
- See only restore events

**Filter by Date:**
- Select start/end dates
- See events in that timeframe

---

## Step 3: View Data in Supabase

### Open Table Editor
URL: https://supabase.com/dashboard/project/prfmsfczqmbciwywxrga/editor

1. Click **`shipment_history`** in left sidebar
2. See all versions as rows
3. Click any row to expand and see:
   - `snapshot_data` - Full JSON of shipment at that version
   - `metadata` - Restore info if applicable

### Run SQL Queries
URL: https://supabase.com/dashboard/project/prfmsfczqmbciwywxrga/sql/new

```sql
-- See all versions
SELECT version_no, event_type, actor_name, timestamp, reason
FROM shipment_history
WHERE shipment_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY version_no DESC;
```

---

## What's Working

| Feature | Status | How to Test |
|---------|--------|-------------|
| Create versions | ✅ | Make changes in form, save |
| View history | ✅ | Click "View History" button |
| View version snapshot | ✅ | Click "View" action |
| Compare versions | ✅ | Click "Diff" twice |
| Restore version | ✅ | Click "Restore" action |
| Filter by actor | ✅ | Type in actor filter |
| Filter by event type | ✅ | Select from dropdown |
| Filter by date | ✅ | Pick date range |
| Auto-increment versions | ✅ | Check version numbers |
| Immutable history | ✅ | Old versions never change |
| Restore metadata | ✅ | Check restored event's metadata |

---

## Quick Start Commands

```bash
# Backend (already running)
# Running at: http://localhost:8000

# Frontend
cd /Users/anmolgewal/take_home/frontend
npm start
# Opens at: http://localhost:3000
```

---

## System is Ready! 🎉

Everything is integrated and working. Just start the frontend and test!
