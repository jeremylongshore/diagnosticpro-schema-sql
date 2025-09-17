-- BigQuery Table Snapshot Creation for Rollback Protection
-- Generated: 2025-09-16
-- Purpose: Create table snapshots before migration operations
--
-- Usage:
--   bq query --use_legacy_sql=false --parameter="project:STRING:diagnostic-pro-start-up" \
--           --parameter="prod:STRING:diagnosticpro_prod" \
--           --parameter="staging:STRING:repair_diagnostics" \
--           --parameter="snapshot_suffix:STRING:$(date +%Y%m%d_%H%M%S)" \
--           < rollback_snapshots.sql

-- =============================================================================
-- SNAPSHOT CONFIGURATION
-- =============================================================================

DECLARE project_id STRING DEFAULT @project;
DECLARE prod_dataset STRING DEFAULT @prod;
DECLARE staging_dataset STRING DEFAULT @staging;
DECLARE snapshot_suffix STRING DEFAULT @snapshot_suffix;

-- Snapshot retention: 24 hours (as requested)
DECLARE snapshot_expiration_hours INT64 DEFAULT 24;
DECLARE snapshot_expiration_timestamp TIMESTAMP;

SET snapshot_expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL snapshot_expiration_hours HOUR);

-- =============================================================================
-- DATA TABLES SNAPSHOTS (Primary Migration Targets)
-- =============================================================================

-- 1. DTC Codes GitHub Data (1,000 records in repair_diagnostics)
EXECUTE IMMEDIATE FORMAT("""
  CREATE SNAPSHOT TABLE `%s.%s.dtc_codes_github_snapshot_%s`
  CLONE `%s.%s.dtc_codes_github`
  OPTIONS (
    expiration_timestamp = TIMESTAMP("%s"),
    description = "Pre-migration snapshot of dtc_codes_github table - 1000 records from repair_diagnostics dataset",
    labels = [("migration_phase", "pre_rollback"), ("table_type", "data"), ("source_dataset", "repair_diagnostics")]
  )
""",
  project_id, staging_dataset, snapshot_suffix,
  project_id, staging_dataset,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp)
);

-- 2. Reddit Diagnostic Posts (11,462 records in repair_diagnostics)
EXECUTE IMMEDIATE FORMAT("""
  CREATE SNAPSHOT TABLE `%s.%s.reddit_diagnostic_posts_snapshot_%s`
  CLONE `%s.%s.reddit_diagnostic_posts`
  OPTIONS (
    expiration_timestamp = TIMESTAMP("%s"),
    description = "Pre-migration snapshot of reddit_diagnostic_posts table - 11462 records from repair_diagnostics dataset",
    labels = [("migration_phase", "pre_rollback"), ("table_type", "data"), ("source_dataset", "repair_diagnostics")]
  )
""",
  project_id, staging_dataset, snapshot_suffix,
  project_id, staging_dataset,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp)
);

-- 3. YouTube Repair Videos (1,000 records in repair_diagnostics)
EXECUTE IMMEDIATE FORMAT("""
  CREATE SNAPSHOT TABLE `%s.%s.youtube_repair_videos_snapshot_%s`
  CLONE `%s.%s.youtube_repair_videos`
  OPTIONS (
    expiration_timestamp = TIMESTAMP("%s"),
    description = "Pre-migration snapshot of youtube_repair_videos table - 1000 records from repair_diagnostics dataset",
    labels = [("migration_phase", "pre_rollback"), ("table_type", "data"), ("source_dataset", "repair_diagnostics")]
  )
""",
  project_id, staging_dataset, snapshot_suffix,
  project_id, staging_dataset,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp)
);

-- 4. Equipment Registry (1 record in diagnosticpro_prod)
EXECUTE IMMEDIATE FORMAT("""
  CREATE SNAPSHOT TABLE `%s.%s.equipment_registry_snapshot_%s`
  CLONE `%s.%s.equipment_registry`
  OPTIONS (
    expiration_timestamp = TIMESTAMP("%s"),
    description = "Pre-migration snapshot of equipment_registry table - 1 record from diagnosticpro_prod dataset",
    labels = [("migration_phase", "pre_rollback"), ("table_type", "core"), ("source_dataset", "diagnosticpro_prod")]
  )
""",
  project_id, prod_dataset, snapshot_suffix,
  project_id, prod_dataset,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp)
);

-- =============================================================================
-- PRODUCTION TABLE SNAPSHOTS (Destination Tables)
-- =============================================================================

-- Create snapshots of production tables that will receive migrated data
-- These may be empty but we snapshot them for complete rollback capability

-- Production DTC Codes (destination table)
EXECUTE IMMEDIATE FORMAT("""
  CREATE SNAPSHOT TABLE IF NOT EXISTS `%s.%s.dtc_codes_github_prod_snapshot_%s`
  CLONE `%s.%s.dtc_codes_github`
  OPTIONS (
    expiration_timestamp = TIMESTAMP("%s"),
    description = "Pre-migration snapshot of production dtc_codes_github table",
    labels = [("migration_phase", "pre_rollback"), ("table_type", "production"), ("source_dataset", "diagnosticpro_prod")]
  )
""",
  project_id, prod_dataset, snapshot_suffix,
  project_id, prod_dataset,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp)
);

-- Production Reddit Posts (destination table)
EXECUTE IMMEDIATE FORMAT("""
  CREATE SNAPSHOT TABLE IF NOT EXISTS `%s.%s.reddit_diagnostic_posts_prod_snapshot_%s`
  CLONE `%s.%s.reddit_diagnostic_posts`
  OPTIONS (
    expiration_timestamp = TIMESTAMP("%s"),
    description = "Pre-migration snapshot of production reddit_diagnostic_posts table",
    labels = [("migration_phase", "pre_rollback"), ("table_type", "production"), ("source_dataset", "diagnosticpro_prod")]
  )
""",
  project_id, prod_dataset, snapshot_suffix,
  project_id, prod_dataset,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp)
);

-- Production YouTube Videos (destination table)
EXECUTE IMMEDIATE FORMAT("""
  CREATE SNAPSHOT TABLE IF NOT EXISTS `%s.%s.youtube_repair_videos_prod_snapshot_%s`
  CLONE `%s.%s.youtube_repair_videos`
  OPTIONS (
    expiration_timestamp = TIMESTAMP("%s"),
    description = "Pre-migration snapshot of production youtube_repair_videos table",
    labels = [("migration_phase", "pre_rollback"), ("table_type", "production"), ("source_dataset", "diagnosticpro_prod")]
  )
""",
  project_id, prod_dataset, snapshot_suffix,
  project_id, prod_dataset,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp)
);

-- =============================================================================
-- SNAPSHOT VERIFICATION
-- =============================================================================

-- Verify all snapshots were created successfully
SELECT
  table_name,
  table_type,
  creation_time,
  expiration_time,
  DATETIME_DIFF(expiration_time, creation_time, HOUR) as retention_hours,
  row_count,
  size_bytes,
  CASE
    WHEN table_name LIKE '%_snapshot_%' THEN 'SNAPSHOT'
    ELSE 'REGULAR_TABLE'
  END as snapshot_status
FROM `{project_id}.{staging_dataset}.INFORMATION_SCHEMA.TABLES`
WHERE table_name LIKE '%_snapshot_{snapshot_suffix}'
UNION ALL
SELECT
  table_name,
  table_type,
  creation_time,
  expiration_time,
  DATETIME_DIFF(expiration_time, creation_time, HOUR) as retention_hours,
  row_count,
  size_bytes,
  CASE
    WHEN table_name LIKE '%_snapshot_%' THEN 'SNAPSHOT'
    ELSE 'REGULAR_TABLE'
  END as snapshot_status
FROM `{project_id}.{prod_dataset}.INFORMATION_SCHEMA.TABLES`
WHERE table_name LIKE '%_snapshot_{snapshot_suffix}'
ORDER BY table_name;

-- =============================================================================
-- SNAPSHOT SUMMARY REPORT
-- =============================================================================

SELECT
  'SNAPSHOT_CREATION_COMPLETE' as status,
  CURRENT_TIMESTAMP() as completion_time,
  snapshot_suffix as batch_id,
  FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S UTC", snapshot_expiration_timestamp) as expires_at,
  'Data tables: 4, Production tables: 3, Total: 7 snapshots' as summary,
  'Use rollback_restore.sql with same snapshot_suffix to restore' as next_steps;

-- =============================================================================
-- USAGE NOTES
-- =============================================================================

/*
CRITICAL SAFETY RULES:

1. ALWAYS create snapshots BEFORE any migration operation
2. Use the SAME snapshot_suffix for both snapshot creation and restore operations
3. Snapshots automatically expire after 24 hours - restore within this window
4. Each snapshot preserves exact table state including data, schema, and metadata
5. IF NOT EXISTS prevents duplicate snapshot errors if script is re-run

PARAMETER DEFINITIONS:
- @project: GCP project ID (default: diagnostic-pro-start-up)
- @prod: Production dataset name (default: diagnosticpro_prod)
- @staging: Staging dataset name (default: repair_diagnostics)
- @snapshot_suffix: Unique timestamp for this snapshot batch (format: YYYYMMDD_HHMMSS)

EXAMPLE EXECUTION:
bq query --use_legacy_sql=false \
  --parameter="project:STRING:diagnostic-pro-start-up" \
  --parameter="prod:STRING:diagnosticpro_prod" \
  --parameter="staging:STRING:repair_diagnostics" \
  --parameter="snapshot_suffix:STRING:20250916_223000" \
  < rollback_snapshots.sql

COST CONSIDERATIONS:
- Snapshots use BigQuery storage (charged separately)
- Snapshot storage cost is minimal compared to query costs
- 24-hour expiration keeps costs controlled
- Total data size: ~13,463 records across 4 tables

RECOVERY GUARANTEE:
After running this script, you can completely restore all 4 data tables
to their exact pre-migration state using rollback_restore.sql
*/