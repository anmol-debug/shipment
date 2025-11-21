"""
Comprehensive test to verify Supabase setup is complete
"""
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_environment_variables():
    """Test that all required environment variables are set"""
    print("\n🔍 Testing Environment Variables...")

    required_vars = {
        'ANTHROPIC_API_KEY': 'Anthropic API Key',
        'SUPABASE_URL': 'Supabase URL',
        'SUPABASE_KEY': 'Supabase Anon Key',
        'SUPABASE_SERVICE_KEY': 'Supabase Service Key'
    }

    all_set = True
    for var, description in required_vars.items():
        value = os.getenv(var)
        if value:
            print(f"  ✅ {description}: Set")
        else:
            print(f"  ❌ {description}: Missing")
            all_set = False

    return all_set

def test_supabase_connection():
    """Test Supabase connection"""
    print("\n🔗 Testing Supabase Connection...")

    try:
        from supabase import create_client

        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_KEY')

        if not supabase_url or not supabase_key:
            print("  ❌ Missing Supabase credentials")
            return False

        client = create_client(supabase_url, supabase_key)
        print("  ✅ Supabase client created successfully")
        return True
    except Exception as e:
        print(f"  ❌ Connection failed: {e}")
        return False

def test_database_tables():
    """Test that audit tables exist"""
    print("\n📊 Testing Database Tables...")

    try:
        from supabase import create_client

        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_KEY')

        client = create_client(supabase_url, supabase_key)

        # Test that we can query the audit tables
        tables_to_test = [
            'shipment_audit_events',
            'shipment_versions',
            'shipment_requests'
        ]

        all_exist = True
        for table in tables_to_test:
            try:
                # Try to query the table (limit 0 to not fetch data)
                result = client.table(table).select("*").limit(0).execute()
                print(f"  ✅ Table '{table}' exists and is accessible")
            except Exception as e:
                print(f"  ❌ Table '{table}' not found or not accessible")
                print(f"     Error: {str(e)}")
                all_exist = False

        return all_exist
    except Exception as e:
        print(f"  ❌ Database test failed: {e}")
        return False

def test_anthropic_api():
    """Test Anthropic API key"""
    print("\n🤖 Testing Anthropic API...")

    try:
        from anthropic import Anthropic

        api_key = os.getenv('ANTHROPIC_API_KEY')
        if not api_key:
            print("  ❌ Anthropic API key not set")
            return False

        client = Anthropic(api_key=api_key)

        # Simple test message
        message = client.messages.create(
            model="claude-3-haiku-20240307",  # Use cheaper model for testing
            max_tokens=10,
            messages=[{
                "role": "user",
                "content": "Say 'test'"
            }]
        )

        response = message.content[0].text
        print(f"  ✅ Anthropic API working (response: '{response}')")
        return True
    except Exception as e:
        print(f"  ❌ Anthropic API test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("🧪 Supabase & API Configuration Test")
    print("=" * 60)

    results = {}

    # Test environment variables
    results['env_vars'] = test_environment_variables()

    # Test Supabase connection
    results['supabase_connection'] = test_supabase_connection()

    # Test database tables (only if connection works)
    if results['supabase_connection']:
        results['database_tables'] = test_database_tables()
    else:
        results['database_tables'] = False
        print("\n📊 Testing Database Tables...")
        print("  ⏭️  Skipped (connection failed)")

    # Test Anthropic API
    results['anthropic_api'] = test_anthropic_api()

    # Summary
    print("\n" + "=" * 60)
    print("📋 Test Summary")
    print("=" * 60)

    all_passed = all(results.values())

    for test_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {status} - {test_name.replace('_', ' ').title()}")

    print("\n" + "=" * 60)
    if all_passed:
        print("🎉 All tests passed! Setup is complete.")
        print("=" * 60)
        print("\n✅ You're ready to proceed to Step 2:")
        print("   - Create backend API endpoints for audit and versioning")
    else:
        print("⚠️  Some tests failed. Please fix the issues above.")
        print("=" * 60)

        # Provide specific guidance
        if not results['env_vars']:
            print("\n🔧 Fix: Check your .env file has all required variables")

        if not results['supabase_connection']:
            print("\n🔧 Fix: Verify your Supabase URL and keys are correct")

        if not results['database_tables']:
            print("\n🔧 Fix: Run the migration SQL in Supabase SQL Editor")
            print("   File: supabase/migrations/20251120_audit_versioning.sql")
            print("   URL: https://supabase.com/dashboard/project/prfmsfczqmbciwywxrga/sql")

        if not results['anthropic_api']:
            print("\n🔧 Fix: Verify your Anthropic API key is valid")

    return all_passed

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
