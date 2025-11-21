-- Enable Row Level Security (RLS) on tables
-- This ensures users can only see and modify their own data

-- Enable RLS on shipment_requests
ALTER TABLE public.shipment_requests ENABLE ROW LEVEL SECURITY;

-- Enable RLS on shipment_history
ALTER TABLE public.shipment_history ENABLE ROW LEVEL SECURITY;

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ========================================
-- SHIPMENT_REQUESTS POLICIES
-- ========================================

-- Policy: Users can view their own shipments
CREATE POLICY "Users can view own shipments"
ON public.shipment_requests
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Users can insert their own shipments
CREATE POLICY "Users can insert own shipments"
ON public.shipment_requests
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy: Users can update their own shipments
CREATE POLICY "Users can update own shipments"
ON public.shipment_requests
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy: Users cannot delete shipments (audit requirement)
-- No DELETE policy = no one can delete

-- ========================================
-- SHIPMENT_HISTORY POLICIES
-- ========================================

-- Policy: Users can view history for their own shipments
CREATE POLICY "Users can view history for own shipments"
ON public.shipment_history
FOR SELECT
TO authenticated
USING (
  shipment_id IN (
    SELECT id FROM public.shipment_requests WHERE user_id = auth.uid()
  )
);

-- Policy: Users can append audit events to their own shipments
CREATE POLICY "Users can append events to own shipments"
ON public.shipment_history
FOR INSERT
TO authenticated
WITH CHECK (
  shipment_id IN (
    SELECT id FROM public.shipment_requests WHERE user_id = auth.uid()
  )
);

-- Policy: Users cannot update or delete history (immutable audit log)
-- No UPDATE or DELETE policies = history is append-only

-- ========================================
-- PROFILES POLICIES
-- ========================================

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- ========================================
-- VERIFICATION
-- ========================================

-- Verify RLS is enabled
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('shipment_requests', 'shipment_history', 'profiles');

-- Show all policies
SELECT
  schemaname,
  tablename,
  policyname,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
