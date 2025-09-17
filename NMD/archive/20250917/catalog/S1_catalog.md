# S1 - BigQuery Schema Catalog

**Generated:** 2025-09-16
**Project:** diagnostic-pro-start-up
**Environment:** Google BigQuery Production

## Dataset Inventory

### Primary Production Dataset: `diagnosticpro_prod`
- **Tables:** 264 tables
- **Status:** Deployed and active
- **Purpose:** Main production database for DiagnosticPro platform

### Secondary Dataset: `repair_diagnostics`
- **Tables:** 7 tables
- **Status:** Active with data
- **Purpose:** Diagnostic data from scrapers

## Schema Summary

### Tables with Full Schema Definitions (8 tables)
1. **users** - Core user authentication and profile data
2. **equipment_registry** - Universal equipment registry
3. **sensor_telemetry** - High-volume time-series sensor data
4. **models** - ML model registry and metadata
5. **feature_store** - ML feature store for training/inference
6. **diagnostic_sessions** - Diagnostic session records
7. **parts_inventory** - Parts inventory and supply chain
8. **maintenance_predictions** - Predictive maintenance recommendations

### Tables by Category (264 total)

#### Core Systems (47 tables)
- **Authentication & Security:** 11 tables
- **User Management:** 7 tables
- **Equipment Registry:** 19 tables
- **Vehicle Management:** 11 tables

#### Business Operations (55 tables)
- **Parts & Inventory:** 15 tables
- **Billing & Financial:** 20 tables
- **Subscriptions:** 8 tables
- **Appointments & Scheduling:** 17 tables

#### Service Delivery (32 tables)
- **Shop Management:** 11 tables
- **Workforce Management:** 10 tables
- **Customer Support:** 10 tables
- **Diagnostics:** 12 tables

#### ML & Analytics (22 tables)
- **ML Infrastructure:** 12 tables
- **Mobile & IoT:** 10 tables

#### Content & Knowledge (21 tables)
- **Documentation:** 9 tables
- **Media & Files:** 12 tables

#### System Operations (58 tables)
- **Background Processing:** 14 tables
- **System Monitoring:** 15 tables
- **Notifications:** 12 tables
- **Data Governance:** 10 tables
- **Geographic Data:** 6 tables

#### Supporting Functions (29 tables)
- **Marketing & Growth:** 7 tables
- **Insurance:** 2 tables
- **Fleet Management:** 3 tables
- **Other Support:** 17 tables

## Views and Materialized Views

No CREATE VIEW or CREATE MATERIALIZED VIEW statements found in current deployment.

## Advanced BigQuery Features

### Partitioning Strategy
- **Time-based partitioning:** 7 of 8 defined tables (87.5%)
- **Partition columns:** created_at, reading_date, feature_date, session_date, prediction_date
- **Retention policies:**
  - sensor_telemetry: 730 days
  - feature_store: 90 days
  - diagnostic_sessions: 2555 days

### Clustering Strategy
- **100% clustering coverage** on defined tables
- **Common cluster keys:** user_type, equipment_id, sensor_id, entity_type, part_number
- **Multi-level clustering** for query optimization

### Data Types Used
- **Native types:** STRING, INT64, FLOAT64, BOOL, TIMESTAMP, DATE, JSON
- **Complex types:** STRUCT (nested objects), ARRAY (repeated fields)
- **Geographic types:** GEOGRAPHY (PostGIS-compatible)

### Nested Structures
- **users.profile:** 7 nested fields
- **users.auth:** 7 nested fields
- **users.metadata:** 6 nested fields
- **equipment_registry:** 10+ nested STRUCTs for complex equipment data
- **diagnostic_sessions.findings:** Arrays of symptoms, codes, recommendations

## Schema Characteristics

### Naming Conventions
- **Primary keys:** `id` or `{table_singular}_id` pattern
- **Timestamps:** `created_at`, `updated_at`, `deleted_at`
- **Foreign keys:** `{referenced_table}_id` pattern
- **Boolean flags:** `is_active`, `is_deleted` prefix

### Data Governance
- **Soft deletes:** `deleted_at` timestamp pattern
- **Audit trails:** `created_at`, `updated_at` on all tables
- **Metadata tracking:** Structured metadata fields for source tracking

### Performance Optimizations
- **Partition pruning:** Required filters on high-volume tables
- **Cost controls:** Automatic partition expiration
- **Query optimization:** Strategic clustering on join/filter columns

## Data Population Status

### Tables with Data (4 tables)
1. **dtc_codes_github:** 1,000 records
2. **reddit_diagnostic_posts:** 11,462 records
3. **youtube_repair_videos:** 1,000 records
4. **equipment_registry:** 1 sample record

### Empty Tables
260 tables are schema-ready but await data population

---
**Generated:** 2025-09-16
**Status:** Production deployment complete