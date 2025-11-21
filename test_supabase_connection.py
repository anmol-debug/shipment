"""Test Supabase connection"""
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Test that env vars are loaded
print("Testing environment variables...")
print(f"SUPABASE_URL: {os.getenv('SUPABASE_URL')}")
print(f"ANTHROPIC_API_KEY: {'✅ Set' if os.getenv('ANTHROPIC_API_KEY') else '❌ Missing'}")
print(f"SUPABASE_KEY: {'✅ Set' if os.getenv('SUPABASE_KEY') else '❌ Missing'}")
print(f"SUPABASE_SERVICE_KEY: {'✅ Set' if os.getenv('SUPABASE_SERVICE_KEY') else '❌ Missing'}")

# Try to connect using anon key
try:
    from supabase import create_client

    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_KEY')

    if not supabase_url or not supabase_key:
        print("\n❌ Missing Supabase credentials in .env file")
        exit(1)

    print("\n🔄 Connecting to Supabase...")
    client = create_client(supabase_url, supabase_key)

    print("✅ Supabase client created successfully!")

    # Try a simple query (this might fail if tables don't exist yet)
    print("\n🔄 Testing database connection...")
    try:
        result = client.table('shipment_requests').select("id").limit(1).execute()
        print(f"✅ Database connection successful!")
        print(f"   Query result: {result}")
    except Exception as e:
        print(f"⚠️  Database query failed (this is normal if tables don't exist yet):")
        print(f"   {str(e)}")

except Exception as e:
    print(f"\n❌ Connection failed: {e}")
    import traceback
    traceback.print_exc()
