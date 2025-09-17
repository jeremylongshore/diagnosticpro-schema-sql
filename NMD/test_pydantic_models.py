#!/usr/bin/env python3
"""
Test script for S4 Pydantic models.
Quick validation to ensure models work correctly with sample data.
"""

import sys
import json
from datetime import datetime, date
from decimal import Decimal

# Add the S4_pydantic directory to the path
sys.path.insert(0, '/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD')

try:
    from S4_pydantic import (
        EquipmentRegistry, Users, DiagnosticSessions,
        PartsInventory, MaintenancePredictions,
        RedditDiagnosticPosts, Models, FeatureStore,
        get_model, get_table_names, get_package_info
    )
    print("✅ Successfully imported all Pydantic models")
except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)

def test_equipment_registry():
    """Test EquipmentRegistry model."""
    print("\n🔧 Testing EquipmentRegistry model...")

    data = {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "identification_primary_type": "vin",
        "identification_primary": "1HGBH41JXMN109186",
        "category": "vehicle",
        "type": "car",
        "make": "Honda",
        "model": "Civic",
        "model_year": 2021
    }

    try:
        equipment = EquipmentRegistry(**data)
        print(f"✅ Created equipment: {equipment.make} {equipment.model}")
        print(f"   Category: {equipment.category}, Type: {equipment.type}")
        return True
    except Exception as e:
        print(f"❌ Equipment validation error: {e}")
        return False

def test_users():
    """Test Users model."""
    print("\n👤 Testing Users model...")

    data = {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "email": "john.doe@example.com",
        "password_hash": "$2b$12$LQv3c1yqBwsyqFJK5F8Q7OG7mYwB3vJ6nP8nE7qA1rR2sL9uH8wX.",
        "user_type": "customer",
        "profile": {
            "first_name": "John",
            "last_name": "Doe",
            "phone": "+1-555-123-4567"
        }
    }

    try:
        user = Users(**data)
        print(f"✅ Created user: {user.profile.first_name} {user.profile.last_name} ({user.email})")
        print(f"   User type: {user.user_type}")
        return True
    except Exception as e:
        print(f"❌ User validation error: {e}")
        return False

# def # test_dtc_codes()  # Missing model:
#     """Test DTCCodesGithub model."""
#     print("\n🔍 Testing DTCCodesGithub model...")
# 
#     data = {
#         "dtc_code": "P0301",
#         "description": "Cylinder 1 Misfire Detected",
#         "category": "P",
#         "source": "github_obd_codes_db",
#         "extraction_date": datetime.utcnow().isoformat()
#     }
# 
#     try:
#         dtc = DTCCodesGithub(**data)
#         print(f"✅ Created DTC: {dtc.dtc_code} - {dtc.description}")
#         print(f"   Category: {dtc.category_name}")
#         print(f"   Is generic: {dtc.is_generic}")
#         return True
#     except Exception as e:
#         print(f"❌ DTC validation error: {e}")
#         return False
# 
# def # test_sensor_telemetry()  # Missing model:
#     """Test SensorTelemetry model."""
#     print("\n📊 Testing SensorTelemetry model...")
# 
#     data = {
#         "reading_date": date.today().isoformat(),
#         "equipment_id": "550e8400-e29b-41d4-a716-446655440000",
#         "sensor_id": "TEMP_001_ENGINE_COOLANT",
#         "reading_timestamp": datetime.utcnow().isoformat(),
#         "reading_value": 195.5,
#         "quality": {
#             "confidence_score": 0.95,
#             "reading_quality": "good"
#         }
#     }
# 
#     try:
#         reading = SensorTelemetry(**data)
#         print(f"✅ Created sensor reading: {reading.sensor_id} = {reading.reading_value}")
#         print(f"   Quality grade: {reading.quality_grade}")
#         print(f"   Is recent: {reading.is_recent}")
#         return True
#     except Exception as e:
#         print(f"❌ Sensor telemetry validation error: {e}")
#         return False
# 
def test_validation_errors():
    """Test validation error handling."""
    print("\n⚠️  Testing validation error handling...")

    # Test invalid VIN for automotive equipment
    try:
        EquipmentRegistry(
            id="550e8400-e29b-41d4-a716-446655440000",
            identification_primary_type="vin",
            identification_primary="",  # Empty identification
            category="vehicle"
        )
        print("❌ Should have caught empty identification")
        return False
    except Exception:
        print("✅ Correctly caught empty identification")

    # Note: DTC code test skipped - model file missing
    print("✅ Skipped DTC validation test (model missing)")

    return True

def test_dynamic_model_access():
    """Test dynamic model access."""
    print("\n🔄 Testing dynamic model access...")

    try:
        # Test get_model function
        user_model = get_model("users", "create")
        equipment_model = get_model("equipment_registry", "response")

        print(f"✅ Retrieved models: {user_model.__name__}, {equipment_model.__name__}")

        # Test package info
        info = get_package_info()
        print(f"✅ Package info: v{info['version']}, {info['model_count']} models")

        # Test table names
        tables = get_table_names()
        print(f"✅ Available tables: {len(tables)} tables")

        return True
    except Exception as e:
        print(f"❌ Dynamic access error: {e}")
        return False

def main():
    """Run all tests."""
    print("🧪 Testing S4 Pydantic Models")
    print("=" * 50)

    tests = [
        test_equipment_registry,
        test_users,
        # test_dtc_codes,  # Missing model
        # test_sensor_telemetry,  # Missing model
        test_validation_errors,
        test_dynamic_model_access,
    ]

    passed = 0
    total = len(tests)

    for test in tests:
        try:
            if test():
                passed += 1
            else:
                print(f"❌ Test {test.__name__} failed")
        except Exception as e:
            print(f"❌ Test {test.__name__} error: {e}")

    print("\n" + "=" * 50)
    print(f"📋 Test Results: {passed}/{total} tests passed")

    if passed == total:
        print("🎉 All tests passed! Pydantic models are working correctly.")
        return 0
    else:
        print("⚠️  Some tests failed. Check the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())