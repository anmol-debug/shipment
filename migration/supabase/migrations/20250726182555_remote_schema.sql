

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."user_role" AS ENUM (
    'admin',
    'manager',
    'reviewer'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_access_shipment"("shipment_id" "uuid", "user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
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


ALTER FUNCTION "public"."can_access_shipment"("shipment_id" "uuid", "user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_role"("user_id" "uuid") RETURNS "public"."user_role"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT role FROM public.profiles WHERE id = user_id;
$$;


ALTER FUNCTION "public"."get_user_role"("user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
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


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."automation_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid",
    "automation_mode" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid",
    CONSTRAINT "automation_settings_automation_mode_check" CHECK (("automation_mode" = ANY (ARRAY['full-auto'::"text", 'semi-auto'::"text", 'manual'::"text"])))
);


ALTER TABLE "public"."automation_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "first_name" "text",
    "last_name" "text",
    "role" "public"."user_role" DEFAULT 'reviewer'::"public"."user_role" NOT NULL,
    "manager_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shipment_assignments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shipment_id" "text" NOT NULL,
    "reviewer_id" "uuid",
    "assigned_by" "uuid",
    "assigned_at" timestamp with time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'assigned'::"text",
    CONSTRAINT "shipment_assignments_status_check" CHECK (("status" = ANY (ARRAY['assigned'::"text", 'in_progress'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."shipment_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shipment_request_files" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shipment_request_id" "uuid" NOT NULL,
    "file_name" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "file_type" "text" NOT NULL,
    "file_size" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."shipment_request_files" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shipment_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "extracted_data" "jsonb",
    "status" "text" DEFAULT '''pending''::text'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "data_extracted" boolean DEFAULT false NOT NULL,
    "transportMode" "text" DEFAULT 'ocean'::"text" NOT NULL,
    "entry_number" "text" DEFAULT 'ST9-2050399-4'::"text",
    "entry_link" "text" DEFAULT 'https://sandbox.netchb.com/app/entry/viewEntry.do?filerCode=ST9&entryNo=2050399'::"text",
    "hidden" boolean DEFAULT false,
    CONSTRAINT "shipment_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'syncing'::"text", 'needs review'::"text", 'new'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."shipment_requests" OWNER TO "postgres";


ALTER TABLE ONLY "public"."automation_settings"
    ADD CONSTRAINT "automation_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shipment_assignments"
    ADD CONSTRAINT "shipment_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shipment_request_files"
    ADD CONSTRAINT "shipment_request_files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shipment_requests"
    ADD CONSTRAINT "shipment_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."automation_settings"
    ADD CONSTRAINT "automation_settings_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."automation_settings"
    ADD CONSTRAINT "automation_settings_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_manager_id_fkey" FOREIGN KEY ("manager_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."shipment_assignments"
    ADD CONSTRAINT "shipment_assignments_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."shipment_assignments"
    ADD CONSTRAINT "shipment_assignments_reviewer_id_fkey" FOREIGN KEY ("reviewer_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shipment_request_files"
    ADD CONSTRAINT "shipment_request_files_shipment_request_id_fkey" FOREIGN KEY ("shipment_request_id") REFERENCES "public"."shipment_requests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shipment_requests"
    ADD CONSTRAINT "shipment_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



CREATE POLICY "Admins and managers can insert automation settings" ON "public"."automation_settings" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'manager'::"public"."user_role"]))))));



CREATE POLICY "Admins and managers can manage assignments" ON "public"."shipment_assignments" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'manager'::"public"."user_role"]))))));



CREATE POLICY "Admins and managers can update automation settings" ON "public"."automation_settings" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'manager'::"public"."user_role"]))))));



CREATE POLICY "Admins and managers can view automation settings" ON "public"."automation_settings" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'manager'::"public"."user_role"]))))));



CREATE POLICY "Admins can insert profiles" ON "public"."profiles" FOR INSERT WITH CHECK (("public"."get_user_role"("auth"."uid"()) = 'admin'::"public"."user_role"));



CREATE POLICY "Admins can update all profiles" ON "public"."profiles" FOR UPDATE USING (("public"."get_user_role"("auth"."uid"()) = 'admin'::"public"."user_role"));



CREATE POLICY "Admins can view all assignments" ON "public"."shipment_assignments" FOR SELECT USING (("public"."get_user_role"("auth"."uid"()) = 'admin'::"public"."user_role"));



CREATE POLICY "Admins can view all profiles" ON "public"."profiles" FOR SELECT USING (("public"."get_user_role"("auth"."uid"()) = 'admin'::"public"."user_role"));



CREATE POLICY "Files access follows shipment access" ON "public"."shipment_request_files" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."shipment_requests" "sr"
  WHERE (("sr"."id" = "shipment_request_files"."shipment_request_id") AND "public"."can_access_shipment"("sr"."id", "auth"."uid"())))));



CREATE POLICY "Managers can create assignments" ON "public"."shipment_assignments" FOR INSERT WITH CHECK ((("public"."get_user_role"("auth"."uid"()) = 'manager'::"public"."user_role") AND ("assigned_by" = "auth"."uid"())));



CREATE POLICY "Managers can view assignments they made" ON "public"."shipment_assignments" FOR SELECT USING (("assigned_by" = "auth"."uid"()));



CREATE POLICY "Managers can view their team" ON "public"."profiles" FOR SELECT USING ((("public"."get_user_role"("auth"."uid"()) = 'manager'::"public"."user_role") AND (("manager_id" = "auth"."uid"()) OR ("id" = "auth"."uid"()))));



CREATE POLICY "Reviewers can update their assignments" ON "public"."shipment_assignments" FOR UPDATE USING (("reviewer_id" = "auth"."uid"()));



CREATE POLICY "Reviewers can view their assignments" ON "public"."shipment_assignments" FOR SELECT USING (("reviewer_id" = "auth"."uid"()));



CREATE POLICY "Shipment assignments access policy" ON "public"."shipment_assignments" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'manager'::"public"."user_role"]))))) OR ("reviewer_id" = "auth"."uid"())));



CREATE POLICY "Users can access shipments based on role" ON "public"."shipment_requests" FOR SELECT USING ("public"."can_access_shipment"("id", "auth"."uid"()));



CREATE POLICY "Users can create files for their own shipment requests" ON "public"."shipment_request_files" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."shipment_requests"
  WHERE (("shipment_requests"."id" = "shipment_request_files"."shipment_request_id") AND ("shipment_requests"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can create their own shipment requests" ON "public"."shipment_requests" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create their own shipments" ON "public"."shipment_requests" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can delete files of their own shipment requests" ON "public"."shipment_request_files" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."shipment_requests"
  WHERE (("shipment_requests"."id" = "shipment_request_files"."shipment_request_id") AND ("shipment_requests"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can delete their own shipment requests" ON "public"."shipment_requests" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update accessible shipments" ON "public"."shipment_requests" FOR UPDATE USING ("public"."can_access_shipment"("id", "auth"."uid"()));



CREATE POLICY "Users can update files of their own shipment requests" ON "public"."shipment_request_files" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."shipment_requests"
  WHERE (("shipment_requests"."id" = "shipment_request_files"."shipment_request_id") AND ("shipment_requests"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update their own shipment requests" ON "public"."shipment_requests" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view files of their own shipment requests" ON "public"."shipment_request_files" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."shipment_requests"
  WHERE (("shipment_requests"."id" = "shipment_request_files"."shipment_request_id") AND ("shipment_requests"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view their own profile" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view their own shipment requests" ON "public"."shipment_requests" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."automation_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shipment_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shipment_request_files" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shipment_requests" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."can_access_shipment"("shipment_id" "uuid", "user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_shipment"("shipment_id" "uuid", "user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_shipment"("shipment_id" "uuid", "user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_role"("user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_role"("user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_role"("user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";


















GRANT ALL ON TABLE "public"."automation_settings" TO "anon";
GRANT ALL ON TABLE "public"."automation_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."automation_settings" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."shipment_assignments" TO "anon";
GRANT ALL ON TABLE "public"."shipment_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."shipment_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."shipment_request_files" TO "anon";
GRANT ALL ON TABLE "public"."shipment_request_files" TO "authenticated";
GRANT ALL ON TABLE "public"."shipment_request_files" TO "service_role";



GRANT ALL ON TABLE "public"."shipment_requests" TO "anon";
GRANT ALL ON TABLE "public"."shipment_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."shipment_requests" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























RESET ALL;