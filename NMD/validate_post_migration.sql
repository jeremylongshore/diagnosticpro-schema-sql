-- validate_post_migration.sql
-- Post-Migration Validation Script for DiagnosticPro BigQuery Platform
-- Version: 1.0.0
-- Generated: 2025-09-16
-- Purpose: Comprehensive validation of data integrity, quality, and freshness after migration

-- ==============================================================================
-- PARAMETERS (to be substituted by bash script)
-- ==============================================================================
-- @project_id     - GCP project ID (e.g. diagnostic-pro-start-up)
-- @staging_dataset - Staging dataset name (e.g. diagnosticpro_staging)
-- @prod_dataset   - Production dataset name (e.g. diagnosticpro_prod)
-- @validation_timestamp - Timestamp for this validation run

-- ==============================================================================
-- 1. ROW COUNT COMPARISONS (Staging vs Production)
-- ==============================================================================
WITH staging_counts AS (
  SELECT
    'dtc_codes_github' as table_name,
    COUNT(*) as staging_count,
    MAX(updated_at) as max_staging_timestamp
  FROM `@project_id.@staging_dataset.dtc_codes_github`

  UNION ALL

  SELECT
    'reddit_diagnostic_posts' as table_name,
    COUNT(*) as staging_count,
    MAX(updated_at) as max_staging_timestamp
  FROM `@project_id.@staging_dataset.reddit_diagnostic_posts`

  UNION ALL

  SELECT
    'youtube_repair_videos' as table_name,
    COUNT(*) as staging_count,
    MAX(updated_at) as max_staging_timestamp
  FROM `@project_id.@staging_dataset.youtube_repair_videos`

  UNION ALL

  SELECT
    'equipment_registry' as table_name,
    COUNT(*) as staging_count,
    MAX(updated_at) as max_staging_timestamp
  FROM `@project_id.@staging_dataset.equipment_registry`

  UNION ALL

  SELECT
    'users' as table_name,
    COUNT(*) as staging_count,
    MAX(updated_at) as max_staging_timestamp
  FROM `@project_id.@staging_dataset.users`

  UNION ALL

  SELECT
    'diagnostic_sessions' as table_name,
    COUNT(*) as staging_count,
    MAX(updated_at) as max_staging_timestamp
  FROM `@project_id.@staging_dataset.diagnostic_sessions`
),

prod_counts AS (
  SELECT
    'dtc_codes_github' as table_name,
    COUNT(*) as prod_count,
    MAX(updated_at) as max_prod_timestamp
  FROM `@project_id.@prod_dataset.dtc_codes_github`

  UNION ALL

  SELECT
    'reddit_diagnostic_posts' as table_name,
    COUNT(*) as prod_count,
    MAX(updated_at) as max_prod_timestamp
  FROM `@project_id.@prod_dataset.reddit_diagnostic_posts`

  UNION ALL

  SELECT
    'youtube_repair_videos' as table_name,
    COUNT(*) as prod_count,
    MAX(updated_at) as max_prod_timestamp
  FROM `@project_id.@prod_dataset.youtube_repair_videos`

  UNION ALL

  SELECT
    'equipment_registry' as table_name,
    COUNT(*) as prod_count,
    MAX(updated_at) as max_prod_timestamp
  FROM `@project_id.@prod_dataset.equipment_registry`

  UNION ALL

  SELECT
    'users' as table_name,
    COUNT(*) as prod_count,
    MAX(updated_at) as max_prod_timestamp
  FROM `@project_id.@prod_dataset.users`

  UNION ALL

  SELECT
    'diagnostic_sessions' as table_name,
    COUNT(*) as prod_count,
    MAX(updated_at) as max_prod_timestamp
  FROM `@project_id.@prod_dataset.diagnostic_sessions`
),

row_count_validation AS (
  SELECT
    s.table_name,
    s.staging_count,
    p.prod_count,
    s.staging_count - p.prod_count as count_diff,
    CASE
      WHEN s.staging_count >= p.prod_count THEN 'PASS'
      WHEN s.staging_count < p.prod_count THEN 'FAIL - DATA LOSS'
      ELSE 'UNKNOWN'
    END as validation_status,
    s.max_staging_timestamp,
    p.max_prod_timestamp,
    DATETIME_DIFF(s.max_staging_timestamp, p.max_prod_timestamp, MINUTE) as timestamp_diff_minutes
  FROM staging_counts s
  JOIN prod_counts p ON s.table_name = p.table_name
)

SELECT
  'ROW_COUNT_VALIDATION' as validation_type,
  table_name,
  staging_count,
  prod_count,
  count_diff,
  validation_status,
  max_staging_timestamp,
  max_prod_timestamp,
  timestamp_diff_minutes,
  CURRENT_DATETIME() as validation_timestamp
FROM row_count_validation
ORDER BY validation_status DESC, table_name;

-- ==============================================================================
-- 2. PRIMARY KEY UNIQUENESS CHECKS
-- ==============================================================================

-- Check for duplicate primary keys in production tables
WITH pk_duplicates AS (
  -- DTC Codes GitHub
  SELECT
    'dtc_codes_github' as table_name,
    'id' as primary_key_field,
    COUNT(*) as total_rows,
    COUNT(DISTINCT id) as unique_keys,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_count
  FROM `@project_id.@prod_dataset.dtc_codes_github`

  UNION ALL

  -- Reddit Diagnostic Posts
  SELECT
    'reddit_diagnostic_posts' as table_name,
    'id' as primary_key_field,
    COUNT(*) as total_rows,
    COUNT(DISTINCT id) as unique_keys,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_count
  FROM `@project_id.@prod_dataset.reddit_diagnostic_posts`

  UNION ALL

  -- YouTube Repair Videos
  SELECT
    'youtube_repair_videos' as table_name,
    'id' as primary_key_field,
    COUNT(*) as total_rows,
    COUNT(DISTINCT id) as unique_keys,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_count
  FROM `@project_id.@prod_dataset.youtube_repair_videos`

  UNION ALL

  -- Equipment Registry
  SELECT
    'equipment_registry' as table_name,
    'identification_number' as primary_key_field,
    COUNT(*) as total_rows,
    COUNT(DISTINCT identification_number) as unique_keys,
    COUNT(*) - COUNT(DISTINCT identification_number) as duplicate_count
  FROM `@project_id.@prod_dataset.equipment_registry`

  UNION ALL

  -- Users
  SELECT
    'users' as table_name,
    'id' as primary_key_field,
    COUNT(*) as total_rows,
    COUNT(DISTINCT id) as unique_keys,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_count
  FROM `@project_id.@prod_dataset.users`

  UNION ALL

  -- Diagnostic Sessions
  SELECT
    'diagnostic_sessions' as table_name,
    'id' as primary_key_field,
    COUNT(*) as total_rows,
    COUNT(DISTINCT id) as unique_keys,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_count
  FROM `@project_id.@prod_dataset.diagnostic_sessions`
)

SELECT
  'PRIMARY_KEY_VALIDATION' as validation_type,
  table_name,
  primary_key_field,
  total_rows,
  unique_keys,
  duplicate_count,
  CASE
    WHEN duplicate_count = 0 THEN 'PASS'
    WHEN duplicate_count > 0 THEN 'FAIL - DUPLICATES FOUND'
    ELSE 'UNKNOWN'
  END as validation_status,
  CURRENT_DATETIME() as validation_timestamp
FROM pk_duplicates
ORDER BY duplicate_count DESC, table_name;

-- ==============================================================================
-- 3. DATA FRESHNESS CHECKS (Based on SLA Requirements)
-- ==============================================================================

WITH freshness_validation AS (
  -- DTC Codes GitHub (SLA: 48h max staleness, daily cadence)
  SELECT
    'dtc_codes_github' as table_name,
    'daily' as expected_cadence,
    48 as max_staleness_hours,
    MAX(updated_at) as latest_record,
    DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) as staleness_hours,
    CASE
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) <= 48 THEN 'PASS'
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) > 48 THEN 'FAIL - STALE DATA'
      ELSE 'NO DATA'
    END as freshness_status,
    COUNT(*) as total_records
  FROM `@project_id.@prod_dataset.dtc_codes_github`

  UNION ALL

  -- Reddit Diagnostic Posts (SLA: 6h max staleness, hourly cadence)
  SELECT
    'reddit_diagnostic_posts' as table_name,
    'hourly' as expected_cadence,
    6 as max_staleness_hours,
    MAX(updated_at) as latest_record,
    DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) as staleness_hours,
    CASE
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) <= 6 THEN 'PASS'
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) > 6 THEN 'FAIL - STALE DATA'
      ELSE 'NO DATA'
    END as freshness_status,
    COUNT(*) as total_records
  FROM `@project_id.@prod_dataset.reddit_diagnostic_posts`

  UNION ALL

  -- YouTube Repair Videos (SLA: 24h max staleness, daily cadence)
  SELECT
    'youtube_repair_videos' as table_name,
    'daily' as expected_cadence,
    24 as max_staleness_hours,
    MAX(updated_at) as latest_record,
    DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) as staleness_hours,
    CASE
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) <= 24 THEN 'PASS'
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) > 24 THEN 'FAIL - STALE DATA'
      ELSE 'NO DATA'
    END as freshness_status,
    COUNT(*) as total_records
  FROM `@project_id.@prod_dataset.youtube_repair_videos`

  UNION ALL

  -- Equipment Registry (SLA: 7d max staleness, on_demand cadence)
  SELECT
    'equipment_registry' as table_name,
    'on_demand' as expected_cadence,
    168 as max_staleness_hours, -- 7 days
    MAX(updated_at) as latest_record,
    DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) as staleness_hours,
    CASE
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) <= 168 THEN 'PASS'
      WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(updated_at), HOUR) > 168 THEN 'FAIL - STALE DATA'
      ELSE 'NO DATA'
    END as freshness_status,
    COUNT(*) as total_records
  FROM `@project_id.@prod_dataset.equipment_registry`
)

SELECT
  'FRESHNESS_VALIDATION' as validation_type,
  table_name,
  expected_cadence,
  max_staleness_hours,
  latest_record,
  staleness_hours,
  freshness_status,
  total_records,
  CURRENT_DATETIME() as validation_timestamp
FROM freshness_validation
ORDER BY staleness_hours DESC;

-- ==============================================================================
-- 4. DATA QUALITY ASSERTIONS
-- ==============================================================================

WITH quality_checks AS (
  -- Check for null primary keys
  SELECT
    'dtc_codes_github' as table_name,
    'null_primary_keys' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) as failing_rows,
    CASE
      WHEN SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
      ELSE 'FAIL - NULL PRIMARY KEYS'
    END as status
  FROM `@project_id.@prod_dataset.dtc_codes_github`

  UNION ALL

  -- Check DTC code format validation
  SELECT
    'dtc_codes_github' as table_name,
    'dtc_format_validation' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE
      WHEN dtc_code IS NOT NULL
      AND NOT REGEXP_CONTAINS(dtc_code, r'^[PBCU]\d{4}$')
      THEN 1 ELSE 0
    END) as failing_rows,
    CASE
      WHEN SUM(CASE
        WHEN dtc_code IS NOT NULL
        AND NOT REGEXP_CONTAINS(dtc_code, r'^[PBCU]\d{4}$')
        THEN 1 ELSE 0
      END) = 0 THEN 'PASS'
      ELSE 'FAIL - INVALID DTC FORMAT'
    END as status
  FROM `@project_id.@prod_dataset.dtc_codes_github`

  UNION ALL

  -- Check for null primary keys in Reddit posts
  SELECT
    'reddit_diagnostic_posts' as table_name,
    'null_primary_keys' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) as failing_rows,
    CASE
      WHEN SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
      ELSE 'FAIL - NULL PRIMARY KEYS'
    END as status
  FROM `@project_id.@prod_dataset.reddit_diagnostic_posts`

  UNION ALL

  -- Check Reddit URL format
  SELECT
    'reddit_diagnostic_posts' as table_name,
    'reddit_url_validation' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE
      WHEN reddit_url IS NOT NULL
      AND NOT REGEXP_CONTAINS(reddit_url, r'^https?://(?:www\.)?reddit\.com/r/.+')
      THEN 1 ELSE 0
    END) as failing_rows,
    CASE
      WHEN SUM(CASE
        WHEN reddit_url IS NOT NULL
        AND NOT REGEXP_CONTAINS(reddit_url, r'^https?://(?:www\.)?reddit\.com/r/.+')
        THEN 1 ELSE 0
      END) = 0 THEN 'PASS'
      ELSE 'FAIL - INVALID REDDIT URL FORMAT'
    END as status
  FROM `@project_id.@prod_dataset.reddit_diagnostic_posts`

  UNION ALL

  -- Check for null primary keys in YouTube videos
  SELECT
    'youtube_repair_videos' as table_name,
    'null_primary_keys' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) as failing_rows,
    CASE
      WHEN SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
      ELSE 'FAIL - NULL PRIMARY KEYS'
    END as status
  FROM `@project_id.@prod_dataset.youtube_repair_videos`

  UNION ALL

  -- Check YouTube video ID format
  SELECT
    'youtube_repair_videos' as table_name,
    'youtube_video_id_validation' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE
      WHEN video_id IS NOT NULL
      AND NOT REGEXP_CONTAINS(video_id, r'^[a-zA-Z0-9_-]{11}$')
      THEN 1 ELSE 0
    END) as failing_rows,
    CASE
      WHEN SUM(CASE
        WHEN video_id IS NOT NULL
        AND NOT REGEXP_CONTAINS(video_id, r'^[a-zA-Z0-9_-]{11}$')
        THEN 1 ELSE 0
      END) = 0 THEN 'PASS'
      ELSE 'FAIL - INVALID YOUTUBE VIDEO ID FORMAT'
    END as status
  FROM `@project_id.@prod_dataset.youtube_repair_videos`

  UNION ALL

  -- Check equipment registry VIN format (if applicable)
  SELECT
    'equipment_registry' as table_name,
    'vin_format_validation' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE
      WHEN identification_number IS NOT NULL
      AND equipment_type = 'vehicle'
      AND NOT REGEXP_CONTAINS(identification_number, r'^[A-HJ-NPR-Z0-9]{17}$')
      THEN 1 ELSE 0
    END) as failing_rows,
    CASE
      WHEN SUM(CASE
        WHEN identification_number IS NOT NULL
        AND equipment_type = 'vehicle'
        AND NOT REGEXP_CONTAINS(identification_number, r'^[A-HJ-NPR-Z0-9]{17}$')
        THEN 1 ELSE 0
      END) = 0 THEN 'PASS'
      ELSE 'FAIL - INVALID VIN FORMAT'
    END as status
  FROM `@project_id.@prod_dataset.equipment_registry`

  UNION ALL

  -- Check for future timestamps (data integrity)
  SELECT
    'dtc_codes_github' as table_name,
    'future_timestamp_check' as check_type,
    COUNT(*) as total_rows,
    SUM(CASE WHEN created_at > CURRENT_DATETIME() THEN 1 ELSE 0 END) as failing_rows,
    CASE
      WHEN SUM(CASE WHEN created_at > CURRENT_DATETIME() THEN 1 ELSE 0 END) = 0 THEN 'PASS'
      ELSE 'FAIL - FUTURE TIMESTAMPS'
    END as status
  FROM `@project_id.@prod_dataset.dtc_codes_github`
)

SELECT
  'QUALITY_VALIDATION' as validation_type,
  table_name,
  check_type,
  total_rows,
  failing_rows,
  status,
  ROUND((failing_rows / NULLIF(total_rows, 0)) * 100, 2) as failure_percentage,
  CURRENT_DATETIME() as validation_timestamp
FROM quality_checks
ORDER BY failing_rows DESC, table_name;

-- ==============================================================================
-- 5. VALIDATION SUMMARY
-- ==============================================================================

WITH validation_summary AS (
  SELECT
    'MIGRATION_VALIDATION_SUMMARY' as summary_type,
    '@project_id' as project_id,
    '@staging_dataset' as staging_dataset,
    '@prod_dataset' as prod_dataset,
    CURRENT_DATETIME() as validation_completed_at,
    'Post-migration data integrity, quality, and freshness validation' as description
)

SELECT
  summary_type,
  project_id,
  staging_dataset,
  prod_dataset,
  validation_completed_at,
  description
FROM validation_summary;