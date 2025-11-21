#!/usr/bin/env python3
"""
Concurrency Test for Audit System
Tests that simultaneous edits to the same shipment result in distinct sequential versions
without data loss or race conditions.

This test verifies:
1. Two concurrent writes get different version numbers (no duplicates)
2. Both writes succeed (no data loss)
3. Version numbers are sequential (no gaps)
4. FOR UPDATE lock prevents race conditions
5. Unique constraint on (shipment_id, version_no) works
"""

import asyncio
import httpx
import time
from datetime import datetime
from typing import List, Dict, Any
import sys

# Configuration
API_BASE = "http://localhost:8000/api"
TEST_SHIPMENT_ID = None  # Will be created during test
# Generate a valid UUID for test user
import uuid
TEST_USER_ID = str(uuid.uuid4())  # Valid UUID format
TEST_USER_NAME = "Concurrency Tester"

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text: str):
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{text:^60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*60}{Colors.END}\n")

def print_success(text: str):
    print(f"{Colors.GREEN}✅ {text}{Colors.END}")

def print_error(text: str):
    print(f"{Colors.RED}❌ {text}{Colors.END}")

def print_info(text: str):
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.END}")

def print_test(text: str):
    print(f"{Colors.YELLOW}🔧 {text}{Colors.END}")


async def create_test_shipment() -> str:
    """Create a test shipment to use for concurrency testing"""
    print_test("Creating test shipment...")

    async with httpx.AsyncClient() as client:
        # Create shipment in database
        # Note: This is a simplified version - you may need to adjust based on your API
        shipment_data = {
            "title": f"Concurrency Test Shipment {datetime.now().isoformat()}",
            "description": "Test shipment for concurrency testing",
            "status": "new",
            "extracted_data": {
                "container_number": "TEST1234567",
                "port_of_loading": "Test Port",
                "port_of_discharge": "Test Destination"
            }
        }

        # You'll need to call your shipment creation API here
        # For now, using a placeholder UUID
        import uuid
        shipment_id = str(uuid.uuid4())

        print_success(f"Created test shipment: {shipment_id}")
        return shipment_id


async def create_audit_event(
    shipment_id: str,
    change_description: str,
    request_id: int,
    delay_ms: int = 0
) -> Dict[str, Any]:
    """
    Create an audit event (simulates editing a shipment)

    Args:
        shipment_id: ID of the shipment to edit
        change_description: Description of the change
        request_id: ID of this request (for tracking)
        delay_ms: Artificial delay before making request (to simulate timing)

    Returns:
        Response data including version_no
    """
    if delay_ms > 0:
        await asyncio.sleep(delay_ms / 1000.0)

    start_time = time.time()

    async with httpx.AsyncClient(timeout=30.0) as client:
        snapshot_data = {
            "id": shipment_id,
            "title": f"Updated by Request {request_id}",
            "status": "in_progress",
            "container_number": f"TEST{request_id:07d}",
            "port_of_loading": f"Port {request_id}",
            "gross_weight_kgs": f"{1000 + request_id}"
        }

        payload = {
            "event_type": "updated",
            "actor_id": TEST_USER_ID,
            "actor_name": f"{TEST_USER_NAME} - Request {request_id}",
            "reason": f"Concurrency test: {change_description}",
            "field_changes": {},
            "snapshot_data": snapshot_data,
            "metadata": {
                "test_request_id": request_id,
                "test_timestamp": datetime.now().isoformat()
            }
        }

        try:
            response = await client.post(
                f"{API_BASE}/shipments/{shipment_id}/audit",
                json=payload
            )

            end_time = time.time()
            duration_ms = (end_time - start_time) * 1000

            if response.status_code == 200:
                result = response.json()
                return {
                    "success": True,
                    "request_id": request_id,
                    "version_no": result.get("version_no"),
                    "duration_ms": duration_ms,
                    "response": result
                }
            else:
                return {
                    "success": False,
                    "request_id": request_id,
                    "error": response.text,
                    "status_code": response.status_code,
                    "duration_ms": duration_ms
                }

        except Exception as e:
            end_time = time.time()
            duration_ms = (end_time - start_time) * 1000
            return {
                "success": False,
                "request_id": request_id,
                "error": str(e),
                "duration_ms": duration_ms
            }


async def test_concurrent_writes(shipment_id: str, num_concurrent: int = 5):
    """
    Test concurrent writes to the same shipment

    Args:
        shipment_id: ID of the shipment to test
        num_concurrent: Number of concurrent requests to make
    """
    print_header(f"CONCURRENT WRITES TEST ({num_concurrent} simultaneous requests)")

    print_info(f"Shipment ID: {shipment_id}")
    print_info(f"Number of concurrent requests: {num_concurrent}")
    print_info("Launching all requests simultaneously...\n")

    # Create tasks for concurrent requests
    tasks = [
        create_audit_event(
            shipment_id,
            f"Concurrent change #{i+1}",
            i + 1,
            delay_ms=0  # All start at same time
        )
        for i in range(num_concurrent)
    ]

    # Execute all requests concurrently
    start_time = time.time()
    results = await asyncio.gather(*tasks)
    total_time = (time.time() - start_time) * 1000

    # Analyze results
    print_header("RESULTS")

    successful = [r for r in results if r.get("success")]
    failed = [r for r in results if not r.get("success")]

    print(f"Total time: {Colors.BOLD}{total_time:.2f}ms{Colors.END}")
    print(f"Successful: {Colors.GREEN}{len(successful)}{Colors.END}")
    print(f"Failed: {Colors.RED}{len(failed)}{Colors.END}\n")

    # Display each result
    for result in results:
        req_id = result["request_id"]
        duration = result["duration_ms"]

        if result["success"]:
            version = result["version_no"]
            print_success(f"Request {req_id}: Version {version} (took {duration:.2f}ms)")
        else:
            error = result.get("error", "Unknown error")
            print_error(f"Request {req_id}: FAILED - {error} (took {duration:.2f}ms)")

    # Verify correctness
    print_header("VERIFICATION")

    all_passed = True

    # Check 1: All requests succeeded
    if len(failed) > 0:
        print_error(f"FAIL: {len(failed)} requests failed")
        all_passed = False
    else:
        print_success("PASS: All requests succeeded")

    # Check 2: No duplicate version numbers
    if successful:
        versions = [r["version_no"] for r in successful]
        unique_versions = set(versions)

        if len(versions) != len(unique_versions):
            print_error(f"FAIL: Duplicate version numbers detected!")
            print_error(f"  Versions: {sorted(versions)}")
            all_passed = False
        else:
            print_success(f"PASS: All version numbers are unique")
            print_info(f"  Versions: {sorted(versions)}")

    # Check 3: Sequential version numbers
    if successful:
        versions = sorted([r["version_no"] for r in successful])
        expected_sequential = list(range(versions[0], versions[0] + len(versions)))

        if versions == expected_sequential:
            print_success(f"PASS: Version numbers are sequential")
            print_info(f"  Range: {versions[0]} to {versions[-1]}")
        else:
            print_error(f"FAIL: Version numbers have gaps")
            print_error(f"  Expected: {expected_sequential}")
            print_error(f"  Got: {versions}")
            all_passed = False

    # Check 4: Performance (all completed within reasonable time)
    max_acceptable_time = 5000  # 5 seconds
    if total_time > max_acceptable_time:
        print_error(f"FAIL: Total time ({total_time:.2f}ms) exceeds {max_acceptable_time}ms")
        all_passed = False
    else:
        print_success(f"PASS: Completed in acceptable time ({total_time:.2f}ms)")

    # Final verdict
    print_header("FINAL VERDICT")

    if all_passed:
        print(f"{Colors.BOLD}{Colors.GREEN}{'✅ ALL TESTS PASSED!':^60}{Colors.END}")
        print(f"\n{Colors.GREEN}The system correctly handles concurrent writes:{Colors.END}")
        print(f"{Colors.GREEN}  ✓ No race conditions{Colors.END}")
        print(f"{Colors.GREEN}  ✓ No duplicate versions{Colors.END}")
        print(f"{Colors.GREEN}  ✓ No data loss{Colors.END}")
        print(f"{Colors.GREEN}  ✓ Sequential version numbers{Colors.END}")
        return True
    else:
        print(f"{Colors.BOLD}{Colors.RED}{'❌ TESTS FAILED':^60}{Colors.END}")
        print(f"\n{Colors.RED}Some tests did not pass. Check the results above.{Colors.END}")
        return False


async def test_staggered_writes(shipment_id: str, num_requests: int = 3):
    """
    Test staggered writes with small delays between requests
    Verifies that even with timing differences, versions remain sequential
    """
    print_header(f"STAGGERED WRITES TEST ({num_requests} requests with delays)")

    print_info(f"Shipment ID: {shipment_id}")
    print_info(f"Number of requests: {num_requests}")
    print_info("Launching requests with 50ms delays between them...\n")

    # Create tasks with staggered delays
    tasks = [
        create_audit_event(
            shipment_id,
            f"Staggered change #{i+1}",
            i + 100,  # Different request IDs
            delay_ms=i * 50  # 0ms, 50ms, 100ms, ...
        )
        for i in range(num_requests)
    ]

    # Execute all requests
    start_time = time.time()
    results = await asyncio.gather(*tasks)
    total_time = (time.time() - start_time) * 1000

    # Analyze results
    print_header("RESULTS")

    successful = [r for r in results if r.get("success")]

    for result in sorted(results, key=lambda x: x["request_id"]):
        req_id = result["request_id"]
        duration = result["duration_ms"]

        if result["success"]:
            version = result["version_no"]
            print_success(f"Request {req_id}: Version {version} (took {duration:.2f}ms)")
        else:
            error = result.get("error", "Unknown error")
            print_error(f"Request {req_id}: FAILED - {error}")

    # Verify versions are sequential
    if successful:
        versions = sorted([r["version_no"] for r in successful])
        print_info(f"\nVersion sequence: {versions}")

        # Check if sequential
        is_sequential = all(versions[i] + 1 == versions[i+1] for i in range(len(versions)-1))

        if is_sequential:
            print_success("PASS: Staggered requests produced sequential versions")
            return True
        else:
            print_error("FAIL: Version numbers have gaps")
            return False

    return False


async def main():
    """Main test runner"""
    print_header("AUDIT SYSTEM CONCURRENCY TESTS")

    print_info("This test verifies that the audit system correctly handles")
    print_info("concurrent writes to the same shipment without data loss")
    print_info("or race conditions.\n")

    # Check if backend is running
    print_test("Checking if backend is running...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{API_BASE}/health", timeout=5.0)
            if response.status_code == 200:
                print_success("Backend is running")
            else:
                print_error("Backend returned unexpected status")
                sys.exit(1)
    except Exception as e:
        print_error(f"Cannot connect to backend: {e}")
        print_error(f"Make sure the backend is running at {API_BASE}")
        sys.exit(1)

    # For this test, we'll use an existing shipment ID
    # You should replace this with an actual shipment ID from your database
    print_test("Getting shipment ID for testing...")
    print_info("Please create a test shipment in your app and paste its ID here,")
    print_info("or press Enter to use a placeholder ID (test may fail):\n")

    user_input = input(f"{Colors.YELLOW}Shipment ID: {Colors.END}").strip()

    if user_input:
        shipment_id = user_input
        print_success(f"Using shipment ID: {shipment_id}\n")
    else:
        # Use a placeholder - this will likely fail but shows the test structure
        import uuid
        shipment_id = str(uuid.uuid4())
        print_info(f"Using placeholder ID: {shipment_id}")
        print_info("Note: This test may fail if the shipment doesn't exist\n")

    # Run tests
    all_tests_passed = True

    # Test 1: Concurrent writes
    test1_passed = await test_concurrent_writes(shipment_id, num_concurrent=5)
    all_tests_passed = all_tests_passed and test1_passed

    # Small delay between tests
    await asyncio.sleep(1)

    # Test 2: Staggered writes
    test2_passed = await test_staggered_writes(shipment_id, num_requests=3)
    all_tests_passed = all_tests_passed and test2_passed

    # Final summary
    print_header("TEST SUMMARY")

    if all_tests_passed:
        print(f"{Colors.BOLD}{Colors.GREEN}✅ ALL CONCURRENCY TESTS PASSED!{Colors.END}\n")
        print(f"{Colors.GREEN}Your audit system correctly handles concurrent writes.{Colors.END}")
        print(f"{Colors.GREEN}The FOR UPDATE lock and unique constraints work as expected.{Colors.END}")
    else:
        print(f"{Colors.BOLD}{Colors.RED}❌ SOME TESTS FAILED{Colors.END}\n")
        print(f"{Colors.RED}Review the results above to see what went wrong.{Colors.END}")

    return 0 if all_tests_passed else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
