-- S4_checks.sql
-- Comprehensive BigQuery Data Quality Checks for DiagnosticPro Platform
-- Generated: 2025-09-16
-- Based on: S2_quality_rules.yaml and S2_sla_retention.yaml

-- =============================================================================
-- CONFIGURATION AND PARAMETERS
-- =============================================================================

DECLARE project STRING DEFAULT '@project';
DECLARE dataset STRING DEFAULT '@dataset';

-- Quality check result summary table
CREATE TEMP TABLE quality_check_results (
  check_category STRING,
  check_name STRING,
  table_name STRING,
  status STRING,
  records_checked INT64,
  records_failed INT64,
  failure_rate NUMERIC,
  check_timestamp TIMESTAMP,
  details STRING
);

-- =============================================================================
-- 1. NOT NULL CHECKS FOR REQUIRED FIELDS
-- =============================================================================

-- Users table NOT NULL checks
INSERT INTO quality_check_results
WITH users_null_checks AS (
  SELECT
    'NOT_NULL' as check_category,
    'users_required_fields' as check_name,
    'users' as table_name,
    COUNT(*) as total_records,
    COUNTIF(id IS NULL) as id_nulls,
    COUNTIF(email IS NULL) as email_nulls,
    COUNTIF(password_hash IS NULL) as password_hash_nulls,
    COUNTIF(user_type IS NULL) as user_type_nulls,
    COUNTIF(created_at IS NULL) as created_at_nulls,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.users`
)
SELECT
  check_category,
  CONCAT(check_name, '_', field_name) as check_name,
  table_name,
  CASE WHEN null_count = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  null_count as records_failed,
  ROUND(SAFE_DIVIDE(null_count, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Required field "', field_name, '" has ', CAST(null_count AS STRING), ' NULL values') as details
FROM users_null_checks
CROSS JOIN UNNEST([
  STRUCT('id' as field_name, id_nulls as null_count),
  ('email', email_nulls),
  ('password_hash', password_hash_nulls),
  ('user_type', user_type_nulls),
  ('created_at', created_at_nulls)
]) AS field_checks;

-- Equipment Registry NOT NULL checks
INSERT INTO quality_check_results
WITH equipment_null_checks AS (
  SELECT
    'NOT_NULL' as check_category,
    'equipment_registry_required_fields' as check_name,
    'equipment_registry' as table_name,
    COUNT(*) as total_records,
    COUNTIF(id IS NULL) as id_nulls,
    COUNTIF(identification_primary IS NULL) as identification_primary_nulls,
    COUNTIF(identification_primary_type IS NULL) as identification_primary_type_nulls,
    COUNTIF(equipment_category IS NULL) as equipment_category_nulls,
    COUNTIF(created_at IS NULL) as created_at_nulls,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.equipment_registry`
)
SELECT
  check_category,
  CONCAT(check_name, '_', field_name) as check_name,
  table_name,
  CASE WHEN null_count = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  null_count as records_failed,
  ROUND(SAFE_DIVIDE(null_count, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Required field "', field_name, '" has ', CAST(null_count AS STRING), ' NULL values') as details
FROM equipment_null_checks
CROSS JOIN UNNEST([
  STRUCT('id' as field_name, id_nulls as null_count),
  ('identification_primary', identification_primary_nulls),
  ('identification_primary_type', identification_primary_type_nulls),
  ('equipment_category', equipment_category_nulls),
  ('created_at', created_at_nulls)
]) AS field_checks;

-- DTC Codes GitHub NOT NULL checks
INSERT INTO quality_check_results
WITH dtc_null_checks AS (
  SELECT
    'NOT_NULL' as check_category,
    'dtc_codes_github_required_fields' as check_name,
    'dtc_codes_github' as table_name,
    COUNT(*) as total_records,
    COUNTIF(dtc_code IS NULL) as dtc_code_nulls,
    COUNTIF(description IS NULL) as description_nulls,
    COUNTIF(category IS NULL) as category_nulls,
    COUNTIF(source IS NULL) as source_nulls,
    COUNTIF(extraction_date IS NULL) as extraction_date_nulls,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.dtc_codes_github`
)
SELECT
  check_category,
  CONCAT(check_name, '_', field_name) as check_name,
  table_name,
  CASE WHEN null_count = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  null_count as records_failed,
  ROUND(SAFE_DIVIDE(null_count, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Required field "', field_name, '" has ', CAST(null_count AS STRING), ' NULL values') as details
FROM dtc_null_checks
CROSS JOIN UNNEST([
  STRUCT('dtc_code' as field_name, dtc_code_nulls as null_count),
  ('description', description_nulls),
  ('category', category_nulls),
  ('source', source_nulls),
  ('extraction_date', extraction_date_nulls)
]) AS field_checks;

-- =============================================================================
-- 2. UNIQUE CHECKS FOR PRIMARY KEYS
-- =============================================================================

-- Users table unique constraints
INSERT INTO quality_check_results
WITH users_unique_checks AS (
  SELECT
    'UNIQUE' as check_category,
    'users_unique_constraints' as check_name,
    'users' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT id) as unique_ids,
    COUNT(DISTINCT email) as unique_emails,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.users`
)
SELECT
  check_category,
  CONCAT(check_name, '_', field_name) as check_name,
  table_name,
  CASE WHEN duplicate_count = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  duplicate_count as records_failed,
  ROUND(SAFE_DIVIDE(duplicate_count, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Field "', field_name, '" has ', CAST(duplicate_count AS STRING), ' duplicate values') as details
FROM users_unique_checks
CROSS JOIN UNNEST([
  STRUCT('id' as field_name, total_records - unique_ids as duplicate_count),
  ('email', total_records - unique_emails)
]) AS field_checks;

-- Equipment Registry unique constraints
INSERT INTO quality_check_results
WITH equipment_unique_checks AS (
  SELECT
    'UNIQUE' as check_category,
    'equipment_registry_unique_constraints' as check_name,
    'equipment_registry' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT id) as unique_ids,
    COUNT(DISTINCT identification_primary) as unique_identification_primary,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.equipment_registry`
)
SELECT
  check_category,
  CONCAT(check_name, '_', field_name) as check_name,
  table_name,
  CASE WHEN duplicate_count = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  duplicate_count as records_failed,
  ROUND(SAFE_DIVIDE(duplicate_count, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Field "', field_name, '" has ', CAST(duplicate_count AS STRING), ' duplicate values') as details
FROM equipment_unique_checks
CROSS JOIN UNNEST([
  STRUCT('id' as field_name, total_records - unique_ids as duplicate_count),
  ('identification_primary', total_records - unique_identification_primary)
]) AS field_checks;

-- =============================================================================
-- 3. FOREIGN KEY LOGICAL CHECKS
-- =============================================================================

-- Equipment Registry foreign key checks (owner_id -> users.id)
INSERT INTO quality_check_results
WITH equipment_fk_checks AS (
  SELECT
    'FOREIGN_KEY' as check_category,
    'equipment_registry_owner_fk' as check_name,
    'equipment_registry' as table_name,
    COUNT(*) as total_records,
    COUNTIF(ownership.owner_id IS NOT NULL) as records_with_owner,
    COUNTIF(ownership.owner_id IS NOT NULL AND u.id IS NULL) as orphaned_records,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.equipment_registry` e
  LEFT JOIN `@project.@dataset.users` u ON e.ownership.owner_id = u.id
)
SELECT
  check_category,
  check_name,
  table_name,
  CASE WHEN orphaned_records = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  records_with_owner as records_checked,
  orphaned_records as records_failed,
  ROUND(SAFE_DIVIDE(orphaned_records, records_with_owner) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(orphaned_records AS STRING), ' orphaned owner_id references') as details
FROM equipment_fk_checks;

-- Diagnostic Sessions foreign key checks
INSERT INTO quality_check_results
WITH sessions_fk_checks AS (
  SELECT
    'FOREIGN_KEY' as check_category,
    'diagnostic_sessions_equipment_fk' as check_name,
    'diagnostic_sessions' as table_name,
    COUNT(*) as total_records,
    COUNTIF(equipment_id IS NOT NULL AND e.id IS NULL) as orphaned_equipment,
    COUNTIF(technician_id IS NOT NULL AND t.id IS NULL) as orphaned_technician,
    COUNTIF(customer_id IS NOT NULL AND c.id IS NULL) as orphaned_customer,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.diagnostic_sessions` ds
  LEFT JOIN `@project.@dataset.equipment_registry` e ON ds.equipment_id = e.id
  LEFT JOIN `@project.@dataset.users` t ON ds.technician_id = t.id
  LEFT JOIN `@project.@dataset.users` c ON ds.customer_id = c.id
)
SELECT
  check_category,
  CONCAT(check_name, '_', fk_type) as check_name,
  table_name,
  CASE WHEN orphaned_count = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  orphaned_count as records_failed,
  ROUND(SAFE_DIVIDE(orphaned_count, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(orphaned_count AS STRING), ' orphaned ', fk_type, ' references') as details
FROM sessions_fk_checks
CROSS JOIN UNNEST([
  STRUCT('equipment' as fk_type, orphaned_equipment as orphaned_count),
  ('technician', orphaned_technician),
  ('customer', orphaned_customer)
]) AS fk_checks;

-- =============================================================================
-- 4. FRESHNESS CHECKS BASED ON SLAs
-- =============================================================================

-- DTC Codes GitHub freshness (48h SLA)
INSERT INTO quality_check_results
WITH dtc_freshness AS (
  SELECT
    'FRESHNESS' as check_category,
    'dtc_codes_github_freshness' as check_name,
    'dtc_codes_github' as table_name,
    COUNT(*) as total_records,
    MAX(import_timestamp) as latest_import,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(import_timestamp), HOUR) as hours_since_latest,
    COUNTIF(TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), import_timestamp, HOUR) > 48) as stale_records,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.dtc_codes_github`
)
SELECT
  check_category,
  check_name,
  table_name,
  CASE WHEN hours_since_latest <= 48 AND stale_records = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  stale_records as records_failed,
  ROUND(SAFE_DIVIDE(stale_records, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Latest import: ', CAST(hours_since_latest AS STRING), 'h ago. SLA: 48h. Stale records: ', CAST(stale_records AS STRING)) as details
FROM dtc_freshness;

-- Reddit Diagnostic Posts freshness (6h SLA)
INSERT INTO quality_check_results
WITH reddit_freshness AS (
  SELECT
    'FRESHNESS' as check_category,
    'reddit_diagnostic_posts_freshness' as check_name,
    'reddit_diagnostic_posts' as table_name,
    COUNT(*) as total_records,
    MAX(import_timestamp) as latest_import,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(import_timestamp), HOUR) as hours_since_latest,
    COUNTIF(TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), import_timestamp, HOUR) > 6) as stale_records,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.reddit_diagnostic_posts`
)
SELECT
  check_category,
  check_name,
  table_name,
  CASE WHEN hours_since_latest <= 6 AND stale_records = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  stale_records as records_failed,
  ROUND(SAFE_DIVIDE(stale_records, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Latest import: ', CAST(hours_since_latest AS STRING), 'h ago. SLA: 6h. Stale records: ', CAST(stale_records AS STRING)) as details
FROM reddit_freshness;

-- YouTube Repair Videos freshness (24h SLA)
INSERT INTO quality_check_results
WITH youtube_freshness AS (
  SELECT
    'FRESHNESS' as check_category,
    'youtube_repair_videos_freshness' as check_name,
    'youtube_repair_videos' as table_name,
    COUNT(*) as total_records,
    MAX(import_timestamp) as latest_import,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(import_timestamp), HOUR) as hours_since_latest,
    COUNTIF(TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), import_timestamp, HOUR) > 24) as stale_records,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.youtube_repair_videos`
)
SELECT
  check_category,
  check_name,
  table_name,
  CASE WHEN hours_since_latest <= 24 AND stale_records = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  stale_records as records_failed,
  ROUND(SAFE_DIVIDE(stale_records, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Latest import: ', CAST(hours_since_latest AS STRING), 'h ago. SLA: 24h. Stale records: ', CAST(stale_records AS STRING)) as details
FROM youtube_freshness;

-- Equipment Registry freshness (7d SLA)
INSERT INTO quality_check_results
WITH equipment_freshness AS (
  SELECT
    'FRESHNESS' as check_category,
    'equipment_registry_freshness' as check_name,
    'equipment_registry' as table_name,
    COUNT(*) as total_records,
    MAX(updated_at) as latest_update,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(updated_at), HOUR) as hours_since_latest,
    COUNTIF(TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), updated_at, HOUR) > 168) as stale_records,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.equipment_registry`
)
SELECT
  check_category,
  check_name,
  table_name,
  CASE WHEN hours_since_latest <= 168 AND stale_records = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  stale_records as records_failed,
  ROUND(SAFE_DIVIDE(stale_records, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Latest update: ', CAST(hours_since_latest AS STRING), 'h ago. SLA: 168h (7d). Stale records: ', CAST(stale_records AS STRING)) as details
FROM equipment_freshness;

-- =============================================================================
-- 5. FORMAT VALIDATION CHECKS
-- =============================================================================

-- UUID Pattern validation
INSERT INTO quality_check_results
WITH uuid_checks AS (
  SELECT
    'FORMAT' as check_category,
    'uuid_validation' as check_name,
    table_name,
    COUNT(*) as total_records,
    COUNTIF(NOT REGEXP_CONTAINS(id, r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')) as invalid_uuids,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM (
    SELECT 'users' as table_name, id FROM `@project.@dataset.users`
    UNION ALL
    SELECT 'equipment_registry' as table_name, id FROM `@project.@dataset.equipment_registry`
    UNION ALL
    SELECT 'diagnostic_sessions' as table_name, session_id as id FROM `@project.@dataset.diagnostic_sessions`
  )
  GROUP BY table_name
)
SELECT
  check_category,
  CONCAT(check_name, '_', table_name) as check_name,
  table_name,
  CASE WHEN invalid_uuids = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  invalid_uuids as records_failed,
  ROUND(SAFE_DIVIDE(invalid_uuids, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(invalid_uuids AS STRING), ' invalid UUID formats') as details
FROM uuid_checks;

-- VIN Format validation
INSERT INTO quality_check_results
WITH vin_checks AS (
  SELECT
    'FORMAT' as check_category,
    'vin_format_validation' as check_name,
    table_name,
    COUNT(*) as total_records,
    COUNTIF(vin IS NOT NULL AND NOT REGEXP_CONTAINS(vin, r'^[A-HJ-NPR-Z0-9]{17}$')) as invalid_vins,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM (
    SELECT 'equipment_registry' as table_name, identification_primary as vin
    FROM `@project.@dataset.equipment_registry`
    WHERE identification_primary_type = 'vin'
    UNION ALL
    SELECT 'reddit_diagnostic_posts' as table_name, equipment.vin
    FROM `@project.@dataset.reddit_diagnostic_posts`
  )
  GROUP BY table_name
)
SELECT
  check_category,
  CONCAT(check_name, '_', table_name) as check_name,
  table_name,
  CASE WHEN invalid_vins = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  invalid_vins as records_failed,
  ROUND(SAFE_DIVIDE(invalid_vins, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(invalid_vins AS STRING), ' invalid VIN formats') as details
FROM vin_checks;

-- DTC Code Format validation
INSERT INTO quality_check_results
WITH dtc_format_checks AS (
  SELECT
    'FORMAT' as check_category,
    'dtc_code_format_validation' as check_name,
    table_name,
    COUNT(*) as total_records,
    COUNTIF(dtc_code IS NOT NULL AND NOT REGEXP_CONTAINS(dtc_code, r'^[PBCU]\d{4}$')) as invalid_dtc_codes,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM (
    SELECT 'dtc_codes_github' as table_name, dtc_code FROM `@project.@dataset.dtc_codes_github`
    UNION ALL
    SELECT 'reddit_diagnostic_posts' as table_name, code as dtc_code
    FROM `@project.@dataset.reddit_diagnostic_posts`, UNNEST(diagnostic_codes) as codes
    WHERE codes.code IS NOT NULL
  )
  GROUP BY table_name
)
SELECT
  check_category,
  CONCAT(check_name, '_', table_name) as check_name,
  table_name,
  CASE WHEN invalid_dtc_codes = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  invalid_dtc_codes as records_failed,
  ROUND(SAFE_DIVIDE(invalid_dtc_codes, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(invalid_dtc_codes AS STRING), ' invalid DTC code formats') as details
FROM dtc_format_checks;

-- Email Format validation
INSERT INTO quality_check_results
WITH email_checks AS (
  SELECT
    'FORMAT' as check_category,
    'email_format_validation' as check_name,
    'users' as table_name,
    COUNT(*) as total_records,
    COUNTIF(NOT REGEXP_CONTAINS(email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')) as invalid_emails,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM `@project.@dataset.users`
)
SELECT
  check_category,
  check_name,
  table_name,
  CASE WHEN invalid_emails = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  invalid_emails as records_failed,
  ROUND(SAFE_DIVIDE(invalid_emails, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(invalid_emails AS STRING), ' invalid email formats') as details
FROM email_checks;

-- URL Pattern validation
INSERT INTO quality_check_results
WITH url_checks AS (
  SELECT
    'FORMAT' as check_category,
    'url_format_validation' as check_name,
    table_name,
    COUNT(*) as total_records,
    COUNTIF(NOT REGEXP_CONTAINS(url, url_pattern)) as invalid_urls,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM (
    SELECT 'reddit_diagnostic_posts' as table_name, url, r'^https?://(?:www\.)?reddit\.com/r/.+' as url_pattern
    FROM `@project.@dataset.reddit_diagnostic_posts`
  )
  GROUP BY table_name, url_pattern
)
SELECT
  check_category,
  CONCAT(check_name, '_', table_name) as check_name,
  table_name,
  CASE WHEN invalid_urls = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  invalid_urls as records_failed,
  ROUND(SAFE_DIVIDE(invalid_urls, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(invalid_urls AS STRING), ' invalid URL formats') as details
FROM url_checks;

-- =============================================================================
-- 6. BUSINESS RULE CHECKS
-- =============================================================================

-- Enum validation checks
INSERT INTO quality_check_results
WITH enum_checks AS (
  SELECT
    'BUSINESS_RULE' as check_category,
    'enum_validation' as check_name,
    table_name,
    field_name,
    COUNT(*) as total_records,
    COUNTIF(field_value NOT IN UNNEST(valid_values)) as invalid_enum_values,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM (
    SELECT 'users' as table_name, 'user_type' as field_name, user_type as field_value,
           ['customer', 'technician', 'administrator', 'shop_owner', 'fleet_manager'] as valid_values
    FROM `@project.@dataset.users`
    UNION ALL
    SELECT 'equipment_registry' as table_name, 'equipment_category' as field_name, equipment_category as field_value,
           ['automotive', 'heavy_equipment', 'electronics', 'machinery', 'appliances', 'marine', 'agricultural'] as valid_values
    FROM `@project.@dataset.equipment_registry`
    UNION ALL
    SELECT 'dtc_codes_github' as table_name, 'category' as field_name, category as field_value,
           ['P', 'B', 'C', 'U'] as valid_values
    FROM `@project.@dataset.dtc_codes_github`
  )
  GROUP BY table_name, field_name, valid_values
)
SELECT
  check_category,
  CONCAT(check_name, '_', table_name, '_', field_name) as check_name,
  table_name,
  CASE WHEN invalid_enum_values = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  invalid_enum_values as records_failed,
  ROUND(SAFE_DIVIDE(invalid_enum_values, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(invalid_enum_values AS STRING), ' invalid enum values in ', field_name) as details
FROM enum_checks;

-- Range validation checks
INSERT INTO quality_check_results
WITH range_checks AS (
  SELECT
    'BUSINESS_RULE' as check_category,
    'range_validation' as check_name,
    table_name,
    field_name,
    COUNT(*) as total_records,
    COUNTIF(field_value < min_value OR field_value > max_value) as out_of_range_values,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM (
    SELECT 'equipment_registry' as table_name, 'model_year' as field_name,
           CAST(equipment_details.model_year AS NUMERIC) as field_value, 1900 as min_value, 2030 as max_value
    FROM `@project.@dataset.equipment_registry`
    WHERE equipment_details.model_year IS NOT NULL
    UNION ALL
    SELECT 'reddit_diagnostic_posts' as table_name, 'cost' as field_name,
           cost as field_value, 0 as min_value, 100000 as max_value
    FROM `@project.@dataset.reddit_diagnostic_posts`
    WHERE cost IS NOT NULL
  )
  GROUP BY table_name, field_name, min_value, max_value
)
SELECT
  check_category,
  CONCAT(check_name, '_', table_name, '_', field_name) as check_name,
  table_name,
  CASE WHEN out_of_range_values = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  out_of_range_values as records_failed,
  ROUND(SAFE_DIVIDE(out_of_range_values, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(out_of_range_values AS STRING), ' out-of-range values in ', field_name) as details
FROM range_checks;

-- Cross-field validation checks
INSERT INTO quality_check_results
WITH cross_field_checks AS (
  SELECT
    'BUSINESS_RULE' as check_category,
    'cross_field_validation' as check_name,
    table_name,
    rule_name,
    COUNT(*) as total_records,
    COUNTIF(NOT rule_passed) as rule_violations,
    CURRENT_TIMESTAMP() as check_timestamp
  FROM (
    -- Users: email_verified_at must be set when email_verified is true
    SELECT 'users' as table_name, 'email_verified_consistency' as rule_name,
           (email_verified IS FALSE OR email_verified_at IS NOT NULL) as rule_passed
    FROM `@project.@dataset.users`
    UNION ALL
    -- DTC Codes: category must match first character of code
    SELECT 'dtc_codes_github' as table_name, 'dtc_category_consistency' as rule_name,
           (SUBSTR(dtc_code, 1, 1) = category) as rule_passed
    FROM `@project.@dataset.dtc_codes_github`
    UNION ALL
    -- Equipment Registry: VIN format required for automotive equipment
    SELECT 'equipment_registry' as table_name, 'automotive_vin_requirement' as rule_name,
           (equipment_category != 'automotive' OR REGEXP_CONTAINS(identification_primary, r'^[A-HJ-NPR-Z0-9]{17}$')) as rule_passed
    FROM `@project.@dataset.equipment_registry`
  )
  GROUP BY table_name, rule_name
)
SELECT
  check_category,
  CONCAT(check_name, '_', table_name, '_', rule_name) as check_name,
  table_name,
  CASE WHEN rule_violations = 0 THEN 'PASS' ELSE 'FAIL' END as status,
  total_records as records_checked,
  rule_violations as records_failed,
  ROUND(SAFE_DIVIDE(rule_violations, total_records) * 100, 2) as failure_rate,
  check_timestamp,
  CONCAT('Found ', CAST(rule_violations AS STRING), ' violations of rule: ', rule_name) as details
FROM cross_field_checks;

-- =============================================================================
-- AGGREGATED RESULT SUMMARY
-- =============================================================================

-- Final summary report
SELECT
  'SUMMARY' as report_type,
  'Data Quality Check Summary' as report_title,
  CURRENT_TIMESTAMP() as report_timestamp,
  COUNT(*) as total_checks,
  COUNTIF(status = 'PASS') as checks_passed,
  COUNTIF(status = 'FAIL') as checks_failed,
  ROUND(COUNTIF(status = 'PASS') / COUNT(*) * 100, 2) as pass_rate_percent,
  SUM(records_checked) as total_records_checked,
  SUM(records_failed) as total_records_failed,
  ROUND(SAFE_DIVIDE(SUM(records_failed), SUM(records_checked)) * 100, 4) as overall_failure_rate_percent
FROM quality_check_results;

-- Summary by check category
SELECT
  'CATEGORY_SUMMARY' as report_type,
  check_category,
  COUNT(*) as total_checks,
  COUNTIF(status = 'PASS') as checks_passed,
  COUNTIF(status = 'FAIL') as checks_failed,
  ROUND(COUNTIF(status = 'PASS') / COUNT(*) * 100, 2) as pass_rate_percent,
  SUM(records_checked) as total_records_checked,
  SUM(records_failed) as total_records_failed,
  ROUND(SAFE_DIVIDE(SUM(records_failed), SUM(records_checked)) * 100, 4) as failure_rate_percent
FROM quality_check_results
GROUP BY check_category
ORDER BY check_category;

-- Summary by table
SELECT
  'TABLE_SUMMARY' as report_type,
  table_name,
  COUNT(*) as total_checks,
  COUNTIF(status = 'PASS') as checks_passed,
  COUNTIF(status = 'FAIL') as checks_failed,
  ROUND(COUNTIF(status = 'PASS') / COUNT(*) * 100, 2) as pass_rate_percent,
  SUM(records_checked) as total_records_checked,
  SUM(records_failed) as total_records_failed,
  ROUND(SAFE_DIVIDE(SUM(records_failed), SUM(records_checked)) * 100, 4) as failure_rate_percent
FROM quality_check_results
GROUP BY table_name
ORDER BY table_name;

-- Detailed failures report (top 20 most critical)
SELECT
  'CRITICAL_FAILURES' as report_type,
  check_category,
  check_name,
  table_name,
  status,
  records_checked,
  records_failed,
  failure_rate,
  details
FROM quality_check_results
WHERE status = 'FAIL'
ORDER BY failure_rate DESC, records_failed DESC
LIMIT 20;

-- Performance and execution info
SELECT
  'EXECUTION_INFO' as report_type,
  'Query execution completed' as message,
  CURRENT_TIMESTAMP() as completion_time,
  @@script.bytes_processed as bytes_processed,
  @@script.slot_ms as slot_milliseconds,
  ROUND(@@script.slot_ms / 1000.0, 2) as slot_seconds
FROM quality_check_results
LIMIT 1;