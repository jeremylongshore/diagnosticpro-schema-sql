# JSON Schema Validators for DiagnosticPro Platform

**Generated:** 2025-09-16
**Source:** S2b_table_contracts_full.yaml and S2_quality_rules.yaml
**Purpose:** Comprehensive JSON Schema validation for critical diagnostic platform tables

## Overview

This directory contains JSON Schema validators for the 11 most critical tables in the DiagnosticPro platform. Each schema provides comprehensive validation rules based on the table contracts and quality rules defined in the platform specifications.

## Schema Files

| Schema File | Description | Lines | Features |
|-------------|-------------|-------|----------|
| `equipment_registry.schema.json` | Universal equipment tracking and management | 277 | VIN validation, equipment categories, ownership tracking |
| `users.schema.json` | User authentication and profile management | 233 | Email validation, MFA support, profile management |
| `diagnostic_sessions.schema.json` | Equipment diagnostic session tracking | 286 | Session workflow, DTC codes, resolution tracking |
| `sensor_telemetry.schema.json` | IoT sensor readings and telemetry data | 332 | Time-series validation, quality metrics, anomaly detection |
| `parts_inventory.schema.json` | Parts catalog and inventory management | 430 | Part compatibility, pricing, inventory tracking |
| `maintenance_predictions.schema.json` | Predictive maintenance recommendations | 401 | Risk assessment, ML predictions, cost estimation |
| `dtc_codes_github.schema.json` | Diagnostic trouble codes from GitHub | 401 | DTC format validation, source tracking, vehicle compatibility |
| `reddit_diagnostic_posts.schema.json` | Reddit posts with diagnostic information | 389 | URL validation, content extraction, sentiment analysis |
| `youtube_repair_videos.schema.json` | YouTube repair and diagnostic videos | 458 | Video metadata, transcript processing, quality metrics |
| `models.schema.json` | ML model registry and metadata | 591 | Model versioning, deployment tracking, performance metrics |
| `feature_store.schema.json` | ML feature storage and versioning | 460 | Feature validation, lineage tracking, quality monitoring |

**Total:** 4,258 lines of comprehensive validation rules

## Key Features

### Universal Patterns
- **UUID Validation**: `^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`
- **DTC Code Validation**: `^[PBCU]\\d{4}$` (P=Powertrain, B=Body, C=Chassis, U=Network)
- **VIN Validation**: `^[A-HJ-NPR-Z0-9]{17}$`
- **Email Validation**: RFC 5322 compliant patterns
- **Timestamp Validation**: ISO 8601 date-time format

### Business Logic Validation
- **Conditional Requirements**: Email verification requires verification timestamp
- **Cross-field Validation**: DTC category must match first character of code
- **Range Constraints**: Normalized scores (0-1), reasonable maximums
- **Referential Integrity**: Foreign key pattern validation

### Data Quality Rules
- **Completeness Scoring**: 0-1 normalized quality metrics
- **Freshness Tracking**: Configurable data age limits
- **Validation Status**: Pending/validated/rejected workflows
- **Source Attribution**: Comprehensive metadata tracking

## Usage Examples

### Validating Equipment Registry Data
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "identification_primary_type": "vin",
  "identification_primary": "1HGBH41JXMN109186",
  "equipment_category": "automotive",
  "equipment_details": {
    "manufacturer": "Honda",
    "model": "Civic",
    "model_year": 2023
  },
  "created_at": "2025-09-16T23:35:00Z",
  "updated_at": "2025-09-16T23:35:00Z"
}
```

### Validating DTC Code Data
```json
{
  "dtc_code": "P0301",
  "description": "Cylinder 1 Misfire Detected",
  "category": "P",
  "source": "github_obd_codes_db",
  "extraction_date": "2025-09-16T20:00:00Z",
  "import_timestamp": "2025-09-16T23:35:00Z"
}
```

## Implementation Notes

### Schema Compliance
- All schemas use JSON Schema Draft 2020-12
- Consistent `$id` format: `https://diagnosticpro.com/schemas/{table_name}.json`
- Comprehensive `allOf` constraints for business logic
- Detailed property descriptions for documentation

### Validation Levels
1. **Structural Validation**: Required fields, data types, formats
2. **Pattern Validation**: Regex patterns for identifiers and codes
3. **Business Rule Validation**: Cross-field dependencies and logic
4. **Range Validation**: Min/max constraints, enum values
5. **Referential Validation**: Foreign key pattern matching

### Performance Considerations
- Efficient regex patterns for high-volume validation
- Optional fields to allow incremental data loading
- Partitioning-aware date field validation
- Clustering-optimized field ordering

## Maintenance

### Schema Updates
- Update version in `$id` when making breaking changes
- Maintain backward compatibility where possible
- Document changes in schema descriptions
- Validate against existing data before deployment

### Quality Monitoring
- Monitor validation failure rates by field
- Track schema drift and evolution
- Maintain test datasets for each schema
- Regular review of business rule effectiveness

---

**Generated with comprehensive validation rules based on:**
- Table contracts from S2b_table_contracts_full.yaml
- Quality rules from S2_quality_rules.yaml
- BigQuery schema definitions
- Business logic requirements
- Data quality standards

**Schema Standard:** JSON Schema Draft 2020-12
**Validation Coverage:** 100% of critical table fields
**Business Logic:** Comprehensive cross-field validation