-- BigQuery Table Restore from Snapshots
-- Generated: 2025-09-16
-- Purpose: Restore tables from snapshots created by rollback_snapshots.sql
--
-- Usage:
--   bq query --use_legacy_sql=false --parameter="project:STRING:diagnostic-pro-start-up" \
--           --parameter="prod:STRING:diagnosticpro_prod" \
--           --parameter="staging:STRING:repair_diagnostics" \
--           --parameter="snapshot_suffix:STRING:20250916_223000" \
--           < rollback_restore.sql

-- =============================================================================
-- RESTORE CONFIGURATION
-- =============================================================================

DECLARE project_id STRING DEFAULT @project;
DECLARE prod_dataset STRING DEFAULT @prod;
DECLARE staging_dataset STRING DEFAULT @staging;
DECLARE snapshot_suffix STRING DEFAULT @snapshot_suffix;

-- Validation: Ensure snapshot_suffix is provided
IF snapshot_suffix IS NULL OR snapshot_suffix = '' THEN
  SELECT ERROR('CRITICAL: snapshot_suffix parameter is required. Use the same suffix from rollback_snapshots.sql');
END IF;

-- =============================================================================
-- PRE-RESTORE VALIDATION
-- =============================================================================

-- Verify snapshots exist before attempting restore
DECLARE snapshot_count INT64;

SET snapshot_count = (
  SELECT COUNT(*)
  FROM (
    SELECT table_name FROM `{project_id}.{staging_dataset}.INFORMATION_SCHEMA.TABLES`
    WHERE table_name LIKE CONCAT('%_snapshot_', snapshot_suffix)
    UNION ALL
    SELECT table_name FROM `{project_id}.{prod_dataset}.INFORMATION_SCHEMA.TABLES`
    WHERE table_name LIKE CONCAT('%_snapshot_', snapshot_suffix)
  )
);

IF snapshot_count < 4 THEN
  SELECT ERROR(FORMAT('CRITICAL: Only %d snapshots found for suffix %s. Expected at least 4. Check snapshot_suffix parameter.', snapshot_count, snapshot_suffix));
END IF;

-- Display restore plan before execution
SELECT
  'RESTORE_PLAN' as operation,
  snapshot_suffix as batch_id,
  snapshot_count as snapshots_found,
  'Ready to restore 4 data tables from snapshots' as status,
  'CRITICAL: This will REPLACE current table data with snapshot data' as warning;

-- =============================================================================
-- DATA TABLES RESTORE (Primary Restoration)
-- =============================================================================

-- 1. Restore DTC Codes GitHub Data
EXECUTE IMMEDIATE FORMAT("""
  CREATE OR REPLACE TABLE `%s.%s.dtc_codes_github`
  CLONE `%s.%s.dtc_codes_github_snapshot_%s`
""",
  project_id, staging_dataset,
  project_id, staging_dataset, snapshot_suffix
);

SELECT 'RESTORED' as status, 'dtc_codes_github' as table_name, 'repair_diagnostics' as dataset;

-- 2. Restore Reddit Diagnostic Posts
EXECUTE IMMEDIATE FORMAT("""
  CREATE OR REPLACE TABLE `%s.%s.reddit_diagnostic_posts`
  CLONE `%s.%s.reddit_diagnostic_posts_snapshot_%s`
""",
  project_id, staging_dataset,
  project_id, staging_dataset, snapshot_suffix
);

SELECT 'RESTORED' as status, 'reddit_diagnostic_posts' as table_name, 'repair_diagnostics' as dataset;

-- 3. Restore YouTube Repair Videos
EXECUTE IMMEDIATE FORMAT("""
  CREATE OR REPLACE TABLE `%s.%s.youtube_repair_videos`
  CLONE `%s.%s.youtube_repair_videos_snapshot_%s`
""",
  project_id, staging_dataset,
  project_id, staging_dataset, snapshot_suffix
);

SELECT 'RESTORED' as status, 'youtube_repair_videos' as table_name, 'repair_diagnostics' as dataset;

-- 4. Restore Equipment Registry (Production)
EXECUTE IMMEDIATE FORMAT("""
  CREATE OR REPLACE TABLE `%s.%s.equipment_registry`
  CLONE `%s.%s.equipment_registry_snapshot_%s`
""",
  project_id, prod_dataset,
  project_id, prod_dataset, snapshot_suffix
);

SELECT 'RESTORED' as status, 'equipment_registry' as table_name, 'diagnosticpro_prod' as dataset;

-- =============================================================================
-- PRODUCTION TABLES RESTORE (If Needed)
-- =============================================================================

-- Restore production data tables if they were modified during migration
-- Only restore if production snapshots exist

-- Check if production DTC codes snapshot exists and restore if found
EXECUTE IMMEDIATE FORMAT("""
  IF EXISTS(
    SELECT 1 FROM `%s.%s.INFORMATION_SCHEMA.TABLES`
    WHERE table_name = 'dtc_codes_github_prod_snapshot_%s'
  ) THEN
    CREATE OR REPLACE TABLE `%s.%s.dtc_codes_github`
    CLONE `%s.%s.dtc_codes_github_prod_snapshot_%s`;

    SELECT 'RESTORED' as status, 'dtc_codes_github' as table_name, 'diagnosticpro_prod' as dataset;
  END IF;
""",
  project_id, prod_dataset, snapshot_suffix,
  project_id, prod_dataset,
  project_id, prod_dataset, snapshot_suffix
);

-- Check if production Reddit posts snapshot exists and restore if found
EXECUTE IMMEDIATE FORMAT("""
  IF EXISTS(
    SELECT 1 FROM `%s.%s.INFORMATION_SCHEMA.TABLES`
    WHERE table_name = 'reddit_diagnostic_posts_prod_snapshot_%s'
  ) THEN
    CREATE OR REPLACE TABLE `%s.%s.reddit_diagnostic_posts`
    CLONE `%s.%s.reddit_diagnostic_posts_prod_snapshot_%s`;

    SELECT 'RESTORED' as status, 'reddit_diagnostic_posts' as table_name, 'diagnosticpro_prod' as dataset;
  END IF;
""",
  project_id, prod_dataset, snapshot_suffix,
  project_id, prod_dataset,
  project_id, prod_dataset, snapshot_suffix
);

-- Check if production YouTube videos snapshot exists and restore if found
EXECUTE IMMEDIATE FORMAT("""
  IF EXISTS(
    SELECT 1 FROM `%s.%s.INFORMATION_SCHEMA.TABLES`
    WHERE table_name = 'youtube_repair_videos_prod_snapshot_%s'
  ) THEN
    CREATE OR REPLACE TABLE `%s.%s.youtube_repair_videos`
    CLONE `%s.%s.youtube_repair_videos_prod_snapshot_%s`;

    SELECT 'RESTORED' as status, 'youtube_repair_videos' as table_name, 'diagnosticpro_prod' as dataset;
  END IF;
""",
  project_id, prod_dataset, snapshot_suffix,
  project_id, prod_dataset,
  project_id, prod_dataset, snapshot_suffix
);

-- =============================================================================
-- POST-RESTORE VALIDATION
-- =============================================================================

-- Verify restored tables have expected data
SELECT
  'POST_RESTORE_VALIDATION' as check_type,
  table_name,
  table_type,
  row_count,
  CASE
    WHEN table_name = 'dtc_codes_github' AND row_count = 1000 THEN 'VALID'
    WHEN table_name = 'reddit_diagnostic_posts' AND row_count = 11462 THEN 'VALID'
    WHEN table_name = 'youtube_repair_videos' AND row_count = 1000 THEN 'VALID'
    WHEN table_name = 'equipment_registry' AND row_count = 1 THEN 'VALID'
    ELSE 'CHECK_REQUIRED'
  END as validation_status,
  creation_time as restored_at
FROM `{project_id}.{staging_dataset}.INFORMATION_SCHEMA.TABLES`
WHERE table_name IN ('dtc_codes_github', 'reddit_diagnostic_posts', 'youtube_repair_videos')
UNION ALL
SELECT
  'POST_RESTORE_VALIDATION' as check_type,
  table_name,
  table_type,
  row_count,
  CASE
    WHEN table_name = 'equipment_registry' AND row_count = 1 THEN 'VALID'
    WHEN table_name = 'dtc_codes_github' AND row_count >= 0 THEN 'CHECK_REQUIRED'
    WHEN table_name = 'reddit_diagnostic_posts' AND row_count >= 0 THEN 'CHECK_REQUIRED'
    WHEN table_name = 'youtube_repair_videos' AND row_count >= 0 THEN 'CHECK_REQUIRED'
    ELSE 'CHECK_REQUIRED'
  END as validation_status,
  creation_time as restored_at
FROM `{project_id}.{prod_dataset}.INFORMATION_SCHEMA.TABLES`
WHERE table_name IN ('dtc_codes_github', 'reddit_diagnostic_posts', 'youtube_repair_videos', 'equipment_registry')
ORDER BY table_name, check_type;

-- =============================================================================
-- RESTORE COMPLETION REPORT
-- =============================================================================

SELECT
  'RESTORE_COMPLETE' as status,
  CURRENT_TIMESTAMP() as completion_time,
  snapshot_suffix as restored_from_batch,
  '4 data tables restored from snapshots' as summary,
  'Verify row counts match expected values from validation report' as next_steps,
  'Original snapshots remain available until expiration' as notes;

-- Row count verification summary
SELECT
  'EXPECTED_ROW_COUNTS' as check_type,
  'dtc_codes_github: 1000, reddit_diagnostic_posts: 11462, youtube_repair_videos: 1000, equipment_registry: 1' as expected_values,
  'Compare actual row counts from validation query above' as instruction;

-- =============================================================================
-- CLEANUP RECOMMENDATIONS
-- =============================================================================

SELECT
  'CLEANUP_OPTIONS' as operation,
  'Snapshots will auto-expire in 24 hours' as automatic_cleanup,
  FORMAT('To manually delete snapshots: DROP TABLE `{project}.{dataset}.{table}_snapshot_{suffix}`',
    project_id, staging_dataset, snapshot_suffix) as manual_cleanup,
  'Keep snapshots until migration is confirmed successful' as recommendation;

-- =============================================================================
-- USAGE NOTES
-- =============================================================================

/*
CRITICAL RESTORATION RULES:

1. Use the EXACT same snapshot_suffix from rollback_snapshots.sql
2. This script REPLACES existing table data with snapshot data
3. Verify row counts after restoration match expected values
4. Keep snapshots until migration success is confirmed
5. All restored tables retain original partitioning and clustering

PARAMETER DEFINITIONS:
- @project: GCP project ID (must match snapshot creation)
- @prod: Production dataset name (must match snapshot creation)
- @staging: Staging dataset name (must match snapshot creation)
- @snapshot_suffix: Exact suffix from snapshot creation (format: YYYYMMDD_HHMMSS)

EXPECTED ROW COUNTS AFTER RESTORE:
- dtc_codes_github: 1,000 records (repair_diagnostics)
- reddit_diagnostic_posts: 11,462 records (repair_diagnostics)
- youtube_repair_videos: 1,000 records (repair_diagnostics)
- equipment_registry: 1 record (diagnosticpro_prod)

EXAMPLE EXECUTION:
bq query --use_legacy_sql=false \
  --parameter="project:STRING:diagnostic-pro-start-up" \
  --parameter="prod:STRING:diagnosticpro_prod" \
  --parameter="staging:STRING:repair_diagnostics" \
  --parameter="snapshot_suffix:STRING:20250916_223000" \
  < rollback_restore.sql

RECOVERY VERIFICATION:
After restoration, run these queries to verify data integrity:

SELECT COUNT(*) FROM `diagnostic-pro-start-up.repair_diagnostics.dtc_codes_github`;        -- Should be 1000
SELECT COUNT(*) FROM `diagnostic-pro-start-up.repair_diagnostics.reddit_diagnostic_posts`; -- Should be 11462
SELECT COUNT(*) FROM `diagnostic-pro-start-up.repair_diagnostics.youtube_repair_videos`;   -- Should be 1000
SELECT COUNT(*) FROM `diagnostic-pro-start-up.diagnosticpro_prod.equipment_registry`;      -- Should be 1

DANGER WARNINGS:
- CREATE OR REPLACE TABLE completely replaces table contents
- This operation is IRREVERSIBLE without additional snapshots
- Always verify snapshot_suffix parameter before execution
- Test in staging environment first if possible
*/