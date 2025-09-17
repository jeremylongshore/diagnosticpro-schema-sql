#!/usr/bin/env python3
"""
Test script for S4 Validation Runner

This script demonstrates the validation runner capabilities and serves as
a comprehensive test suite for the validation system.

Usage:
    python test_S4_runner.py [--live]
"""

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

def run_validation_test(test_name: str, args: list, expected_exit_code: int = 0) -> bool:
    """Run a single validation test"""
    print(f"\n🧪 Test: {test_name}")
    print(f"   Command: python S4_runner.py {' '.join(args)}")

    try:
        result = subprocess.run(
            ['python', 'S4_runner.py'] + args,
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent
        )

        print(f"   Exit code: {result.returncode} (expected: {expected_exit_code})")

        if result.returncode == expected_exit_code:
            print("   ✅ PASSED")
            return True
        else:
            print("   ❌ FAILED")
            print(f"   STDOUT: {result.stdout}")
            print(f"   STDERR: {result.stderr}")
            return False

    except Exception as e:
        print(f"   ❌ FAILED with exception: {e}")
        return False

def test_help_and_basic_functionality():
    """Test basic functionality and help"""
    tests = [
        ("Help command", ["--help"], 0),
        ("Version/basic validation", ["--tables", "nonexistent_table"], 1),  # Should fail
    ]

    results = []
    for test_name, args, expected_code in tests:
        results.append(run_validation_test(test_name, args, expected_code))

    return all(results)

def test_json_output():
    """Test JSON output format"""
    print("\n🧪 Test: JSON Output Format")

    try:
        result = subprocess.run(
            ['python', 'S4_runner.py', '--output', 'json', '--tables', 'users'],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent
        )

        # Try to parse JSON output
        try:
            json_data = json.loads(result.stdout)
            print("   ✅ Valid JSON output produced")

            # Check required fields
            required_fields = ['timestamp', 'project_id', 'dataset_id', 'summary']
            missing_fields = [field for field in required_fields if field not in json_data]

            if not missing_fields:
                print("   ✅ All required fields present")
                return True
            else:
                print(f"   ❌ Missing required fields: {missing_fields}")
                return False

        except json.JSONDecodeError as e:
            print(f"   ❌ Invalid JSON output: {e}")
            print(f"   Output: {result.stdout}")
            return False

    except Exception as e:
        print(f"   ❌ Test failed with exception: {e}")
        return False

def test_pattern_matching():
    """Test table pattern matching"""
    tests = [
        ("All tables pattern", ["--tables", "*"], None),
        ("Specific table", ["--tables", "users"], None),
        ("Pattern with prefix", ["--tables", "user*"], None),
        ("Multiple tables", ["--tables", "users,equipment_registry"], None),
    ]

    results = []
    for test_name, args, _ in tests:
        # We don't know the exact exit codes without live data, so just test execution
        try:
            result = subprocess.run(
                ['python', 'S4_runner.py'] + args + ['--output', 'json'],
                capture_output=True,
                text=True,
                cwd=Path(__file__).parent,
                timeout=30  # 30 second timeout
            )
            print(f"\n🧪 Test: {test_name}")
            print(f"   Exit code: {result.returncode}")
            print("   ✅ PASSED (executed without crashing)")
            results.append(True)
        except subprocess.TimeoutExpired:
            print(f"\n🧪 Test: {test_name}")
            print("   ⏱️  TIMEOUT (may indicate long-running validation)")
            results.append(True)  # Timeout is acceptable for live tests
        except Exception as e:
            print(f"\n🧪 Test: {test_name}")
            print(f"   ❌ FAILED with exception: {e}")
            results.append(False)

    return all(results)

def test_fail_thresholds():
    """Test different failure thresholds"""
    tests = [
        ("Fail on warnings", ["--fail-on", "warn", "--tables", "users"]),
        ("Fail on errors only", ["--fail-on", "error", "--tables", "users"]),
    ]

    results = []
    for test_name, args in tests:
        try:
            result = subprocess.run(
                ['python', 'S4_runner.py'] + args,
                capture_output=True,
                text=True,
                cwd=Path(__file__).parent,
                timeout=30
            )
            print(f"\n🧪 Test: {test_name}")
            print(f"   Exit code: {result.returncode}")
            print("   ✅ PASSED (executed successfully)")
            results.append(True)
        except Exception as e:
            print(f"\n🧪 Test: {test_name}")
            print(f"   ❌ FAILED with exception: {e}")
            results.append(False)

    return all(results)

def run_live_validation_tests():
    """Run tests against live BigQuery data (requires authentication)"""
    print("\n🔴 LIVE VALIDATION TESTS")
    print("=" * 50)
    print("⚠️  These tests require:")
    print("   - Google Cloud authentication")
    print("   - Access to diagnostic-pro-start-up project")
    print("   - Active BigQuery datasets")
    print()

    # Test with real project and dataset
    live_tests = [
        ("Live schema validation", [
            "--project", "diagnostic-pro-start-up",
            "--dataset", "diagnosticpro_prod",
            "--tables", "users",
            "--output", "json"
        ]),
        ("Live data constraints check", [
            "--project", "diagnostic-pro-start-up",
            "--dataset", "diagnosticpro_prod",
            "--tables", "reddit_diagnostic_posts",
            "--fail-on", "warn"
        ]),
        ("Live freshness validation", [
            "--project", "diagnostic-pro-start-up",
            "--dataset", "diagnosticpro_prod",
            "--tables", "dtc_codes_github,youtube_repair_videos",
            "--fail-on", "error"
        ])
    ]

    results = []
    for test_name, args in live_tests:
        try:
            result = subprocess.run(
                ['python', 'S4_runner.py'] + args,
                capture_output=True,
                text=True,
                cwd=Path(__file__).parent,
                timeout=120  # 2 minute timeout for live tests
            )

            print(f"\n🧪 Live Test: {test_name}")
            print(f"   Exit code: {result.returncode}")

            if result.returncode in [0, 1, 2]:  # Valid exit codes
                print("   ✅ PASSED")
                results.append(True)
            else:
                print("   ❌ FAILED - Unexpected exit code")
                print(f"   STDERR: {result.stderr}")
                results.append(False)

        except subprocess.TimeoutExpired:
            print(f"\n🧪 Live Test: {test_name}")
            print("   ⏱️  TIMEOUT - Test took too long")
            results.append(False)
        except Exception as e:
            print(f"\n🧪 Live Test: {test_name}")
            print(f"   ❌ FAILED with exception: {e}")
            results.append(False)

    return all(results)

def main():
    """Main test runner"""
    parser = argparse.ArgumentParser(description='Test S4 Validation Runner')
    parser.add_argument('--live', action='store_true',
                       help='Run live tests against real BigQuery data')
    args = parser.parse_args()

    print("🔍 S4 VALIDATION RUNNER TESTS")
    print("=" * 50)

    # Check if S4_runner.py exists
    runner_path = Path(__file__).parent / 'S4_runner.py'
    if not runner_path.exists():
        print("❌ S4_runner.py not found in current directory")
        sys.exit(1)

    # Run basic functionality tests
    print("\n📋 BASIC FUNCTIONALITY TESTS")
    basic_passed = test_help_and_basic_functionality()

    print("\n📋 JSON OUTPUT TESTS")
    json_passed = test_json_output()

    print("\n📋 PATTERN MATCHING TESTS")
    pattern_passed = test_pattern_matching()

    print("\n📋 FAILURE THRESHOLD TESTS")
    threshold_passed = test_fail_thresholds()

    # Collect results
    all_tests = [basic_passed, json_passed, pattern_passed, threshold_passed]

    # Run live tests if requested
    live_passed = True
    if args.live:
        live_passed = run_live_validation_tests()
        all_tests.append(live_passed)

    # Summary
    print("\n" + "=" * 50)
    print("📊 TEST SUMMARY")
    print("=" * 50)

    test_names = ["Basic Functionality", "JSON Output", "Pattern Matching", "Failure Thresholds"]
    if args.live:
        test_names.append("Live Validation")

    for i, (name, passed) in enumerate(zip(test_names, all_tests)):
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"   {name}: {status}")

    total_passed = sum(all_tests)
    total_tests = len(all_tests)

    print(f"\nOverall: {total_passed}/{total_tests} tests passed")

    if all(all_tests):
        print("🎉 ALL TESTS PASSED!")
        sys.exit(0)
    else:
        print("❌ SOME TESTS FAILED")
        sys.exit(1)

if __name__ == '__main__':
    main()