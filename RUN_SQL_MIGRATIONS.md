# How to Run SQL Migrations in Supabase

## Overview
You need to run 2 SQL files in your Supabase SQL Editor to enable authentication and Row Level Security (RLS).

## Step-by-Step Instructions

### 1. Open Supabase SQL Editor

Go to: https://supabase.com/dashboard/project/prfmsfczqmbciwywxrga/sql/new

(Or navigate to your project → SQL Editor → New Query)

### 2. Run Migration #1: RLS Policies

**File**: `supabase/migrations/20251120_add_rls_policies.sql`

This migration:
- Enables Row Level Security on shipment_requests, shipment_history, and profiles tables
- Creates policies so users can only view/edit their own shipments
- Makes audit history immutable (no UPDATE or DELETE allowed)

**Steps**:
1. Open the file `supabase/migrations/20251120_add_rls_policies.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click "Run" (or press Cmd+Enter)
5. Verify you see "Success. No rows returned"

### 3. Run Migration #2: Set User Passwords

**File**: `create_user_passwords.sql`

This migration:
- Sets passwords for all test users to "password123"
- Allows you to log in with test accounts

**Steps**:
1. Open the file `create_user_passwords.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click "Run" (or press Cmd+Enter)
5. Verify you see the password verification results

## Test Accounts

After running the migrations, you can log in with these accounts:

| Email | Password | Role |
|-------|----------|------|
| manager2@email.com | password123 | manager |
| admin1@email.com | password123 | admin |
| manager1@email.com | password123 | manager |
| reviewer2@email.com | password123 | reviewer |
| reviewer3@email.com | password123 | reviewer |

## What Happens After Running Migrations

### Database Security (RLS)
- ✅ Users can only see shipments where `user_id` matches their ID
- ✅ Users can only edit their own shipments
- ✅ Users can view all profiles (needed for seeing names)
- ✅ Audit history cannot be modified or deleted (immutable)

### Authentication Flow
1. User visits http://localhost:5173
2. Login screen appears
3. User enters email/password (or clicks quick-login button)
4. On success, JWT token is stored in localStorage
5. Dashboard shows only the user's shipments
6. All API requests include Bearer token
7. Database RLS policies enforce permissions

## Verifying It Works

### Test RLS Policies
1. Log in as manager2@email.com (password123)
2. You should only see shipments created by Manager Two
3. Try editing a shipment - the audit event should show "Manager Two" as actor
4. Log out and log in as admin1@email.com
5. You should see different shipments (Admin One's shipments)

### Check Database Directly
Run this in Supabase SQL Editor to see which users own which shipments:

```sql
SELECT
  sr.id,
  sr.title,
  p.email,
  p.first_name || ' ' || p.last_name as owner_name
FROM public.shipment_requests sr
JOIN public.profiles p ON sr.user_id = p.id
ORDER BY sr.created_at DESC;
```

## Troubleshooting

### Error: "permission denied for table shipment_requests"
- RLS policies are working correctly!
- This means the API is not passing a valid auth token
- Check that the user is logged in and token exists in localStorage

### Error: "duplicate key value violates unique constraint"
- The policies were already created
- You can skip this migration

### Login fails with "Invalid credentials"
- Make sure you ran the password migration
- Double-check you're using "password123" (all lowercase)
- Verify the user exists in auth.users table

### Cannot see any shipments after login
- Check that the logged-in user has shipments assigned to them
- Run the query above to see user-shipment mapping
- The test data has 3 shipments assigned to manager2@email.com

## Security Notes

1. **RLS is mandatory**: Without RLS policies, users could access all shipments
2. **Immutable audit trail**: No one can modify or delete audit history records
3. **Token-based auth**: JWT tokens expire and need to be refreshed
4. **Password hashing**: All passwords are bcrypt hashed in the database
5. **Service role bypasses RLS**: Be careful with SUPABASE_SERVICE_KEY

## Next Steps

After running migrations:

1. ✅ Test login at http://localhost:5173
2. ✅ Try each test account
3. ✅ Verify RLS by checking users only see their shipments
4. ✅ Edit a shipment and verify the audit event has correct actor_name
5. ✅ View shipment history and try restoring a version
6. ✅ Log out and log in as different user
