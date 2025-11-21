-- Initial schema setup for shipment tracking system
-- This creates the base tables needed before audit/versioning

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_role enum
DO $$ BEGIN
    CREATE TYPE "public"."user_role" AS ENUM ('admin', 'manager', 'reviewer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create profiles table (links to auth.users)
CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" uuid NOT NULL PRIMARY KEY,
    "email" text NOT NULL,
    "first_name" text,
    "last_name" text,
    "role" "public"."user_role" DEFAULT 'reviewer'::"public"."user_role" NOT NULL,
    "manager_id" uuid REFERENCES "public"."profiles"("id"),
    "created_at" timestamp with time zone DEFAULT now(),
    "updated_at" timestamp with time zone DEFAULT now()
);

-- Create shipment_requests table (base shipment data)
CREATE TABLE IF NOT EXISTS "public"."shipment_requests" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    "title" text NOT NULL,
    "description" text,
    "extracted_data" jsonb,
    "status" text DEFAULT 'pending' NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "user_id" uuid NOT NULL,
    "data_extracted" boolean DEFAULT false NOT NULL,
    "transportMode" text DEFAULT 'ocean' NOT NULL,
    "entry_number" text,
    "entry_link" text,
    "hidden" boolean DEFAULT false,
    CONSTRAINT "shipment_requests_status_check" CHECK (status IN ('pending', 'syncing', 'needs review', 'new', 'completed'))
);

-- Create shipment_request_files table
CREATE TABLE IF NOT EXISTS "public"."shipment_request_files" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    "shipment_request_id" uuid NOT NULL REFERENCES "public"."shipment_requests"("id") ON DELETE CASCADE,
    "file_name" text NOT NULL,
    "file_path" text NOT NULL,
    "file_type" text NOT NULL,
    "file_size" integer,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

-- Create shipment_assignments table (no FK to shipment_requests - uses text id)
CREATE TABLE IF NOT EXISTS "public"."shipment_assignments" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    "shipment_id" text NOT NULL,
    "reviewer_id" uuid,
    "assigned_by" uuid,
    "assigned_at" timestamp with time zone DEFAULT now(),
    "status" text DEFAULT 'assigned',
    CONSTRAINT "shipment_assignments_status_check" CHECK (status IN ('assigned', 'in_progress', 'completed'))
);

-- Create automation_settings table
CREATE TABLE IF NOT EXISTS "public"."automation_settings" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    "organization_id" uuid,
    "automation_mode" text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "created_by" uuid,
    "updated_by" uuid,
    CONSTRAINT "automation_settings_automation_mode_check" CHECK (automation_mode IN ('full-auto', 'semi-auto', 'manual'))
);

-- Helper function to check shipment access
CREATE OR REPLACE FUNCTION "public"."can_access_shipment"("shipment_id" uuid, "user_id" uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id
    AND role IN ('admin', 'manager')
  )
  OR EXISTS (
    SELECT 1 FROM public.shipment_assignments sa
    WHERE sa.shipment_id = shipment_id::text
    AND sa.reviewer_id = user_id
  )
  OR EXISTS (
    SELECT 1 FROM public.shipment_requests sr
    WHERE sr.id = shipment_id
    AND sr.user_id = user_id
  );
$$;

-- Helper function to get user role
CREATE OR REPLACE FUNCTION "public"."get_user_role"("user_id" uuid)
RETURNS "public"."user_role"
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT role FROM public.profiles WHERE id = user_id;
$$;

-- Trigger to create profile on user signup
CREATE OR REPLACE FUNCTION "public"."handle_new_user"()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  );
  RETURN NEW;
END;
$$;

-- Create trigger on auth.users (if not exists)
DO $$ BEGIN
  CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Enable Row Level Security
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."shipment_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."shipment_request_files" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."shipment_assignments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."automation_settings" ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON "public"."profiles";
CREATE POLICY "Users can view their own profile" ON "public"."profiles"
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON "public"."profiles";
CREATE POLICY "Users can update their own profile" ON "public"."profiles"
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON "public"."profiles";
CREATE POLICY "Admins can view all profiles" ON "public"."profiles"
  FOR SELECT USING (public.get_user_role(auth.uid()) = 'admin');

-- RLS Policies for shipment_requests
DROP POLICY IF EXISTS "Users can create their own shipments" ON "public"."shipment_requests";
CREATE POLICY "Users can create their own shipments" ON "public"."shipment_requests"
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can view their own shipment requests" ON "public"."shipment_requests";
CREATE POLICY "Users can view their own shipment requests" ON "public"."shipment_requests"
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can access shipments based on role" ON "public"."shipment_requests";
CREATE POLICY "Users can access shipments based on role" ON "public"."shipment_requests"
  FOR SELECT USING (public.can_access_shipment(id, auth.uid()));

DROP POLICY IF EXISTS "Users can update accessible shipments" ON "public"."shipment_requests";
CREATE POLICY "Users can update accessible shipments" ON "public"."shipment_requests"
  FOR UPDATE USING (public.can_access_shipment(id, auth.uid()));

DROP POLICY IF EXISTS "Users can delete their own shipment requests" ON "public"."shipment_requests";
CREATE POLICY "Users can delete their own shipment requests" ON "public"."shipment_requests"
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for shipment_request_files
DROP POLICY IF EXISTS "Files access follows shipment access" ON "public"."shipment_request_files";
CREATE POLICY "Files access follows shipment access" ON "public"."shipment_request_files"
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.shipment_requests sr
      WHERE sr.id = shipment_request_files.shipment_request_id
      AND public.can_access_shipment(sr.id, auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can create files for their shipments" ON "public"."shipment_request_files";
CREATE POLICY "Users can create files for their shipments" ON "public"."shipment_request_files"
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.shipment_requests
      WHERE shipment_requests.id = shipment_request_files.shipment_request_id
      AND shipment_requests.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Add comments
COMMENT ON TABLE "public"."shipment_requests" IS 'Main shipment tracking table';
COMMENT ON TABLE "public"."profiles" IS 'User profiles linked to auth.users';
COMMENT ON TABLE "public"."shipment_request_files" IS 'Files uploaded for shipments';
