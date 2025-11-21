# Supabase Setup Guide

## Step 1: Create Supabase Project (15-20 minutes)

### 1.1 Create Supabase Account and Project

1. Go to [https://supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Fill in project details:
   - **Project Name**: `shipment-audit-system` (or your choice)
   - **Database Password**: Create a strong password and **save it**
   - **Region**: Choose closest to your users
4. Click "Create new project" and wait for setup (~2 minutes)

### 1.2 Get API Keys

1. Once the project is ready, go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxxxxxxxxxx.supabase.co`
   - **anon/public key**: `eyJhbGc...` (used by frontend)
   - **service_role key**: `eyJhbGc...` (used by backend - keep secret!)

### 1.3 Configure Environment Variables

#### Backend Configuration

1. Create `.env` file in the project root (copy from `.env.example`):

```bash
# Anthropic API
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Supabase Configuration
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_KEY=your_supabase_anon_key_here
SUPABASE_SERVICE_KEY=your_supabase_service_role_key_here
```

2. Replace the placeholder values with your actual Supabase credentials

#### Frontend Configuration

1. Create `.env` file in `frontend/frontend/` directory:

```bash
# Supabase Configuration
VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

2. Replace with your actual values (use the **anon key**, NOT service_role key)

### 1.4 Install Dependencies

#### Backend

```bash
pip install -r requirements.txt
```

This will install:
- `supabase==2.3.4` - Python client for Supabase
- `postgrest==0.13.2` - PostgreSQL REST API client

#### Frontend

```bash
cd frontend/frontend
npm install
```

This will install:
- `@supabase/supabase-js` - JavaScript client for Supabase

### 1.5 Run Database Migrations

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Click "New Query"
4. Copy the contents of `/supabase/migrations/20251120_audit_versioning.sql`
5. Paste into the SQL editor
6. Click "Run" to execute the migration

**OR** use Supabase CLI (if installed):

```bash
# Link your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

### 1.6 Verify Setup

Check that the following tables were created:

1. Go to **Table Editor** in Supabase dashboard
2. You should see:
   - `shipment_audit_events` - Audit log table
   - `shipment_versions` - Version snapshots table
   - `shipment_requests` - Existing table (from migration)
   - `profiles` - User profiles
   - `shipment_assignments` - Assignments
   - `shipment_request_files` - File uploads

### 1.7 Test Connection

#### Test Backend Connection

Create a test script `test_supabase.py`:

```python
from app.services.supabase_client import get_supabase

try:
    client = get_supabase()
    result = client.table('shipment_requests').select("id").limit(1).execute()
    print("✅ Supabase backend connection successful!")
    print(f"Result: {result}")
except Exception as e:
    print(f"❌ Connection failed: {e}")
```

Run it:
```bash
python test_supabase.py
```

#### Test Frontend Connection

The frontend connection will be tested when you start the development server.

---

## ✅ Step 1 Complete!

You've successfully:
- ✅ Created a Supabase project
- ✅ Configured API keys and environment variables
- ✅ Installed required dependencies
- ✅ Created database tables with migrations
- ✅ Set up Supabase clients for backend and frontend

## Next Steps

Proceed to **Step 2: Create Backend API Endpoints** to implement the audit and versioning functionality.

---

## Troubleshooting

### Issue: "Missing Supabase environment variables"

**Solution**: Make sure you created `.env` files in both root and `frontend/frontend/` directories with correct values.

### Issue: Migration fails with "table already exists"

**Solution**: This is fine if you're re-running migrations. The `IF NOT EXISTS` clauses prevent errors.

### Issue: Connection timeout

**Solution**:
- Check your internet connection
- Verify the SUPABASE_URL is correct
- Ensure your Supabase project is active (not paused)

### Issue: Authentication errors

**Solution**:
- Backend should use `SUPABASE_SERVICE_KEY`
- Frontend should use `VITE_SUPABASE_ANON_KEY`
- Never expose service_role key in frontend!
