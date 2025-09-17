-- BigQuery MERGE Statement Templates for Data Migration
-- From staging (repair_diagnostics) to production (diagnosticpro_prod)
--
-- Production-ready templates with error handling and deduplication
-- Supports upsert patterns, append-only patterns, and soft deletes
--
-- Author: DiagnosticPro Schema Management Team
-- Date: 2025-09-16
-- BigQuery Project: diagnostic-pro-start-up

-- =============================================================================
-- 1. EQUIPMENT REGISTRY UPSERT PATTERN
-- Uses identification_primary as match key with conflict resolution
-- =============================================================================

-- Equipment Registry Upsert Template
MERGE `diagnostic-pro-start-up.diagnosticpro_prod.equipment_registry` AS target
USING (
  SELECT DISTINCT
    -- Deduplication: Use latest record per identification_primary
    ARRAY_AGG(staging LIMIT 1)[OFFSET(0)].*
  FROM `diagnostic-pro-start-up.repair_diagnostics.equipment_registry` AS staging
  WHERE staging.identification_primary IS NOT NULL
    AND staging.deleted_at IS NULL  -- Exclude soft-deleted records
  GROUP BY staging.identification_primary
) AS source
ON target.identification_primary = source.identification_primary

-- When record exists - update all fields
WHEN MATCHED THEN
  UPDATE SET
    id = COALESCE(source.id, target.id),
    equipment_category = COALESCE(source.equipment_category, target.equipment_category),
    equipment_details = source.equipment_details,
    identification_primary = source.identification_primary,
    identification_secondary = source.identification_secondary,
    ownership = source.ownership,
    location = source.location,
    condition = source.condition,
    specifications = source.specifications,
    warranty = source.warranty,
    service_history = source.service_history,
    compliance_certifications = source.compliance_certifications,
    metadata = source.metadata,
    -- Preserve source tracking and update timestamps
    source = COALESCE(source.source, target.source),
    created_at = COALESCE(target.created_at, source.created_at),
    updated_at = CURRENT_TIMESTAMP(),
    deleted_at = source.deleted_at

-- When record doesn't exist - insert new record
WHEN NOT MATCHED THEN
  INSERT (
    id, equipment_category, equipment_details, identification_primary,
    identification_secondary, ownership, location, condition, specifications,
    warranty, service_history, compliance_certifications, metadata,
    source, created_at, updated_at, deleted_at
  )
  VALUES (
    COALESCE(source.id, GENERATE_UUID()),
    source.equipment_category,
    source.equipment_details,
    source.identification_primary,
    source.identification_secondary,
    source.ownership,
    source.location,
    source.condition,
    source.specifications,
    source.warranty,
    source.service_history,
    source.compliance_certifications,
    source.metadata,
    source.source,
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP(),
    source.deleted_at
  );

-- Error Handling: Check for merge conflicts and duplicate keys
-- Run this after the MERGE to validate success:
-- SELECT identification_primary, COUNT(*) as cnt
-- FROM `diagnostic-pro-start-up.diagnosticpro_prod.equipment_registry`
-- GROUP BY identification_primary
-- HAVING COUNT(*) > 1;

-- =============================================================================
-- 2. USERS TABLE UPSERT PATTERN
-- Uses email as match key with user type handling
-- =============================================================================

MERGE `diagnostic-pro-start-up.diagnosticpro_prod.users` AS target
USING (
  SELECT DISTINCT
    -- Deduplication: Use latest record per email
    ARRAY_AGG(staging ORDER BY staging.updated_at DESC LIMIT 1)[OFFSET(0)].*
  FROM `diagnostic-pro-start-up.repair_diagnostics.users` AS staging
  WHERE staging.email IS NOT NULL
    AND REGEXP_CONTAINS(staging.email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    AND staging.deleted_at IS NULL
  GROUP BY staging.email
) AS source
ON target.email = source.email

WHEN MATCHED THEN
  UPDATE SET
    id = COALESCE(source.id, target.id),
    email = source.email,
    username = COALESCE(source.username, target.username),
    user_type = COALESCE(source.user_type, target.user_type),
    profile = source.profile,
    preferences = source.preferences,
    subscription = source.subscription,
    contact_info = source.contact_info,
    verification = source.verification,
    privacy_settings = source.privacy_settings,
    activity_tracking = source.activity_tracking,
    metadata = source.metadata,
    source = COALESCE(source.source, target.source),
    created_at = COALESCE(target.created_at, source.created_at),
    updated_at = CURRENT_TIMESTAMP(),
    deleted_at = source.deleted_at

WHEN NOT MATCHED THEN
  INSERT (
    id, email, username, user_type, profile, preferences, subscription,
    contact_info, verification, privacy_settings, activity_tracking,
    metadata, source, created_at, updated_at, deleted_at
  )
  VALUES (
    COALESCE(source.id, GENERATE_UUID()),
    source.email,
    source.username,
    COALESCE(source.user_type, 'customer'),
    source.profile,
    source.preferences,
    source.subscription,
    source.contact_info,
    source.verification,
    source.privacy_settings,
    source.activity_tracking,
    source.metadata,
    source.source,
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP(),
    source.deleted_at
  );

-- =============================================================================
-- 3. SENSOR TELEMETRY APPEND PATTERN
-- Time-series data - append only, no updates
-- =============================================================================

-- Sensor Telemetry Append Template (Insert Only)
INSERT INTO `diagnostic-pro-start-up.diagnosticpro_prod.sensor_telemetry` (
  reading_date, equipment_id, sensor_id, reading_timestamp, sensor_type,
  sensor_data, reading_quality, metadata, source, import_timestamp
)
SELECT DISTINCT
  staging.reading_date,
  staging.equipment_id,
  staging.sensor_id,
  staging.reading_timestamp,
  staging.sensor_type,
  staging.sensor_data,
  staging.reading_quality,
  staging.metadata,
  staging.source,
  CURRENT_TIMESTAMP() as import_timestamp
FROM `diagnostic-pro-start-up.repair_diagnostics.sensor_telemetry` AS staging
WHERE staging.equipment_id IS NOT NULL
  AND staging.sensor_id IS NOT NULL
  AND staging.reading_timestamp IS NOT NULL
  AND staging.reading_date IS NOT NULL
  -- Exclude records that already exist (based on composite key)
  AND NOT EXISTS (
    SELECT 1
    FROM `diagnostic-pro-start-up.diagnosticpro_prod.sensor_telemetry` AS existing
    WHERE existing.reading_date = staging.reading_date
      AND existing.equipment_id = staging.equipment_id
      AND existing.sensor_id = staging.sensor_id
      AND existing.reading_timestamp = staging.reading_timestamp
  );

-- =============================================================================
-- 4. DIAGNOSTIC SESSIONS UPSERT PATTERN
-- Uses session_id as primary key
-- =============================================================================

MERGE `diagnostic-pro-start-up.diagnosticpro_prod.diagnostic_sessions` AS target
USING (
  SELECT DISTINCT
    -- Deduplication: Use latest record per session_id
    ARRAY_AGG(staging ORDER BY staging.updated_at DESC LIMIT 1)[OFFSET(0)].*
  FROM `diagnostic-pro-start-up.repair_diagnostics.diagnostic_sessions` AS staging
  WHERE staging.session_id IS NOT NULL
  GROUP BY staging.session_id
) AS source
ON target.session_id = source.session_id

WHEN MATCHED THEN
  UPDATE SET
    session_id = source.session_id,
    session_date = COALESCE(source.session_date, target.session_date),
    equipment_id = COALESCE(source.equipment_id, target.equipment_id),
    technician_id = source.technician_id,
    customer_id = source.customer_id,
    session_type = source.session_type,
    session_status = source.session_status,
    diagnostic_data = source.diagnostic_data,
    test_results = source.test_results,
    recommendations = source.recommendations,
    repair_actions = source.repair_actions,
    costs = source.costs,
    duration_minutes = source.duration_minutes,
    metadata = source.metadata,
    source = COALESCE(source.source, target.source),
    created_at = COALESCE(target.created_at, source.created_at),
    updated_at = CURRENT_TIMESTAMP(),
    deleted_at = source.deleted_at

WHEN NOT MATCHED THEN
  INSERT (
    session_id, session_date, equipment_id, technician_id, customer_id,
    session_type, session_status, diagnostic_data, test_results,
    recommendations, repair_actions, costs, duration_minutes, metadata,
    source, created_at, updated_at, deleted_at
  )
  VALUES (
    source.session_id,
    source.session_date,
    source.equipment_id,
    source.technician_id,
    source.customer_id,
    source.session_type,
    source.session_status,
    source.diagnostic_data,
    source.test_results,
    source.recommendations,
    source.repair_actions,
    source.costs,
    source.duration_minutes,
    source.metadata,
    source.source,
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP(),
    source.deleted_at
  );

-- =============================================================================
-- 5. PARTS INVENTORY UPSERT PATTERN
-- Uses part_number as natural key
-- =============================================================================

MERGE `diagnostic-pro-start-up.diagnosticpro_prod.parts_inventory` AS target
USING (
  SELECT DISTINCT
    -- Deduplication: Use latest record per part_number
    ARRAY_AGG(staging ORDER BY staging.updated_at DESC LIMIT 1)[OFFSET(0)].*
  FROM `diagnostic-pro-start-up.repair_diagnostics.parts_inventory` AS staging
  WHERE staging.part_number IS NOT NULL
    AND staging.deleted_at IS NULL
  GROUP BY staging.part_number
) AS source
ON target.part_number = source.part_number

WHEN MATCHED THEN
  UPDATE SET
    part_id = COALESCE(source.part_id, target.part_id),
    part_number = source.part_number,
    part_name = source.part_name,
    description = source.description,
    manufacturer = source.manufacturer,
    category = source.category,
    specifications = source.specifications,
    pricing = source.pricing,
    supplier = source.supplier,
    location = source.location,
    inventory_levels = source.inventory_levels,
    compatibility = source.compatibility,
    images = source.images,
    metadata = source.metadata,
    source = COALESCE(source.source, target.source),
    created_at = COALESCE(target.created_at, source.created_at),
    updated_at = CURRENT_TIMESTAMP(),
    deleted_at = source.deleted_at

WHEN NOT MATCHED THEN
  INSERT (
    part_id, part_number, part_name, description, manufacturer, category,
    specifications, pricing, supplier, location, inventory_levels,
    compatibility, images, metadata, source, created_at, updated_at, deleted_at
  )
  VALUES (
    COALESCE(source.part_id, GENERATE_UUID()),
    source.part_number,
    source.part_name,
    source.description,
    source.manufacturer,
    source.category,
    source.specifications,
    source.pricing,
    source.supplier,
    source.location,
    source.inventory_levels,
    source.compatibility,
    source.images,
    source.metadata,
    source.source,
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP(),
    source.deleted_at
  );

-- =============================================================================
-- 6. REDDIT DATA MERGE PATTERN
-- Uses Reddit post/comment IDs as unique keys
-- =============================================================================

MERGE `diagnostic-pro-start-up.diagnosticpro_prod.reddit_diagnostic_posts` AS target
USING (
  SELECT DISTINCT
    -- Extract Reddit ID from URL or use explicit ID field
    COALESCE(
      staging.reddit_id,
      REGEXP_EXTRACT(staging.url, r'/comments/([a-z0-9]+)/'),
      REGEXP_EXTRACT(staging.url, r'/([a-z0-9]+)/?$')
    ) as reddit_id,
    staging.*
  FROM `diagnostic-pro-start-up.repair_diagnostics.reddit_diagnostic_posts` AS staging
  WHERE staging.url IS NOT NULL
    AND (staging.reddit_id IS NOT NULL OR REGEXP_CONTAINS(staging.url, r'/comments/[a-z0-9]+/'))
) AS source
ON target.reddit_id = source.reddit_id OR target.url = source.url

WHEN MATCHED THEN
  UPDATE SET
    reddit_id = COALESCE(source.reddit_id, target.reddit_id),
    equipment = source.equipment,
    diagnostic_codes = source.diagnostic_codes,
    repair_procedure = source.repair_procedure,
    cost = source.cost,
    url = source.url,
    author = source.author,
    timestamp = COALESCE(source.timestamp, target.timestamp),
    source_type = source.source_type,
    source = COALESCE(source.source, target.source),
    import_timestamp = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
  INSERT (
    reddit_id, equipment, diagnostic_codes, repair_procedure, cost,
    url, author, timestamp, source_type, source, import_timestamp
  )
  VALUES (
    source.reddit_id,
    source.equipment,
    source.diagnostic_codes,
    source.repair_procedure,
    source.cost,
    source.url,
    source.author,
    source.timestamp,
    source.source_type,
    source.source,
    CURRENT_TIMESTAMP()
  );

-- =============================================================================
-- 7. YOUTUBE DATA MERGE PATTERN
-- Uses video_id as unique key
-- =============================================================================

MERGE `diagnostic-pro-start-up.diagnosticpro_prod.youtube_repair_videos` AS target
USING (
  SELECT DISTINCT
    staging.*
  FROM `diagnostic-pro-start-up.repair_diagnostics.youtube_repair_videos` AS staging
  WHERE staging.video_id IS NOT NULL
    AND REGEXP_CONTAINS(staging.video_id, r'^[a-zA-Z0-9_-]{11}$')  -- Valid YouTube video ID format
) AS source
ON target.video_id = source.video_id

WHEN MATCHED THEN
  UPDATE SET
    video_id = source.video_id,
    title = source.title,
    channel = source.channel,
    description = source.description,
    source = COALESCE(source.source, target.source),
    import_timestamp = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
  INSERT (video_id, title, channel, description, source, import_timestamp)
  VALUES (
    source.video_id,
    source.title,
    source.channel,
    source.description,
    source.source,
    CURRENT_TIMESTAMP()
  );

-- =============================================================================
-- 8. GITHUB DATA MERGE PATTERN
-- Uses repository and file path combination as unique key
-- =============================================================================

MERGE `diagnostic-pro-start-up.diagnosticpro_prod.dtc_codes_github` AS target
USING (
  SELECT DISTINCT
    staging.*,
    -- Create composite key for GitHub data
    CONCAT(COALESCE(staging.repository, 'unknown'), '/', COALESCE(staging.file_path, '')) as composite_key
  FROM `diagnostic-pro-start-up.repair_diagnostics.dtc_codes_github` AS staging
  WHERE staging.dtc_code IS NOT NULL
    AND REGEXP_CONTAINS(staging.dtc_code, r'^[PBCU]\d{4}$')  -- Valid DTC format
) AS source
ON target.dtc_code = source.dtc_code
   AND COALESCE(target.repository, '') = COALESCE(source.repository, '')

WHEN MATCHED THEN
  UPDATE SET
    dtc_code = source.dtc_code,
    description = source.description,
    category = source.category,
    category_desc = source.category_desc,
    repository = source.repository,
    file_path = source.file_path,
    source = COALESCE(source.source, target.source),
    extraction_date = COALESCE(source.extraction_date, target.extraction_date),
    import_timestamp = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
  INSERT (
    dtc_code, description, category, category_desc, repository, file_path,
    source, extraction_date, import_timestamp
  )
  VALUES (
    source.dtc_code,
    source.description,
    source.category,
    source.category_desc,
    source.repository,
    source.file_path,
    source.source,
    source.extraction_date,
    CURRENT_TIMESTAMP()
  );

-- =============================================================================
-- 9. GENERIC ID-BASED UPSERT TEMPLATE
-- Use this template for tables with standard ID-based primary keys
-- =============================================================================

/*
-- Generic ID-Based Upsert Template
-- Replace TABLE_NAME, PRIMARY_KEY_FIELD, and field lists as needed

MERGE `diagnostic-pro-start-up.diagnosticpro_prod.{TABLE_NAME}` AS target
USING (
  SELECT DISTINCT
    -- Deduplication by primary key
    ARRAY_AGG(staging ORDER BY staging.updated_at DESC LIMIT 1)[OFFSET(0)].*
  FROM `diagnostic-pro-start-up.repair_diagnostics.{TABLE_NAME}` AS staging
  WHERE staging.{PRIMARY_KEY_FIELD} IS NOT NULL
    AND staging.deleted_at IS NULL  -- Exclude soft-deleted records
  GROUP BY staging.{PRIMARY_KEY_FIELD}
) AS source
ON target.{PRIMARY_KEY_FIELD} = source.{PRIMARY_KEY_FIELD}

WHEN MATCHED THEN
  UPDATE SET
    -- Add all relevant fields here
    field1 = COALESCE(source.field1, target.field1),
    field2 = source.field2,
    -- Always update these standard fields
    source = COALESCE(source.source, target.source),
    created_at = COALESCE(target.created_at, source.created_at),
    updated_at = CURRENT_TIMESTAMP(),
    deleted_at = source.deleted_at

WHEN NOT MATCHED THEN
  INSERT (
    {PRIMARY_KEY_FIELD}, field1, field2, ...,
    source, created_at, updated_at, deleted_at
  )
  VALUES (
    source.{PRIMARY_KEY_FIELD},
    source.field1,
    source.field2,
    -- ... other fields
    source.source,
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP(),
    source.deleted_at
  );
*/

-- =============================================================================
-- 10. GENERIC APPEND-ONLY TEMPLATE
-- Use this template for time-series or log data that should never be updated
-- =============================================================================

/*
-- Generic Append-Only Template
-- Replace TABLE_NAME and UNIQUE_KEY_FIELDS as needed

INSERT INTO `diagnostic-pro-start-up.diagnosticpro_prod.{TABLE_NAME}` (
  -- List all target columns here
  field1, field2, timestamp_field, source, import_timestamp
)
SELECT DISTINCT
  staging.field1,
  staging.field2,
  staging.timestamp_field,
  staging.source,
  CURRENT_TIMESTAMP() as import_timestamp
FROM `diagnostic-pro-start-up.repair_diagnostics.{TABLE_NAME}` AS staging
WHERE staging.{REQUIRED_FIELD} IS NOT NULL
  -- Prevent duplicates based on business logic
  AND NOT EXISTS (
    SELECT 1
    FROM `diagnostic-pro-start-up.diagnosticpro_prod.{TABLE_NAME}` AS existing
    WHERE existing.{UNIQUE_KEY_FIELD1} = staging.{UNIQUE_KEY_FIELD1}
      AND existing.{UNIQUE_KEY_FIELD2} = staging.{UNIQUE_KEY_FIELD2}
      -- Add more unique key conditions as needed
  );
*/

-- =============================================================================
-- ERROR HANDLING AND VALIDATION QUERIES
-- Run these after merge operations to validate success
-- =============================================================================

-- Check for duplicate primary keys after merge
/*
SELECT
  table_name,
  primary_key_field,
  COUNT(*) as duplicate_count
FROM (
  SELECT 'equipment_registry' as table_name, identification_primary as primary_key_field
  FROM `diagnostic-pro-start-up.diagnosticpro_prod.equipment_registry`

  UNION ALL

  SELECT 'users' as table_name, email as primary_key_field
  FROM `diagnostic-pro-start-up.diagnosticpro_prod.users`

  UNION ALL

  SELECT 'parts_inventory' as table_name, part_number as primary_key_field
  FROM `diagnostic-pro-start-up.diagnosticpro_prod.parts_inventory`
)
GROUP BY table_name, primary_key_field
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
*/

-- Validate data integrity after merge
/*
SELECT
  'equipment_registry' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT identification_primary) as unique_identifiers,
  COUNT(*) - COUNT(DISTINCT identification_primary) as duplicates
FROM `diagnostic-pro-start-up.diagnosticpro_prod.equipment_registry`

UNION ALL

SELECT
  'users' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT email) as unique_emails,
  COUNT(*) - COUNT(DISTINCT email) as duplicates
FROM `diagnostic-pro-start-up.diagnosticpro_prod.users`;
*/

-- =============================================================================
-- PERFORMANCE OPTIMIZATION NOTES
-- =============================================================================

/*
PERFORMANCE TIPS:

1. Use CLUSTER BY on target tables for merge operations:
   - equipment_registry: CLUSTER BY equipment_category, manufacturer
   - users: CLUSTER BY user_type, email
   - sensor_telemetry: CLUSTER BY equipment_id, sensor_id

2. Partition large tables by date:
   - sensor_telemetry: PARTITION BY reading_date
   - diagnostic_sessions: PARTITION BY session_date
   - feature_store: PARTITION BY feature_date

3. Use LIMIT in ARRAY_AGG for deduplication to avoid memory issues

4. Consider using streaming inserts for high-volume append operations

5. Run MERGE operations during low-traffic periods

6. Monitor slot usage and optimize query structure for large datasets

7. Use APPROX_COUNT_DISTINCT for validation queries on large tables
*/

-- =============================================================================
-- SOFT DELETE HANDLING
-- =============================================================================

/*
SOFT DELETE PATTERN:

For tables supporting soft deletes, use this pattern in your WHERE clauses:

-- Include soft-deleted records in merge for status tracking
WHERE staging.deleted_at IS NULL OR staging.deleted_at IS NOT NULL

-- Exclude soft-deleted records from normal operations
WHERE staging.deleted_at IS NULL

-- Handle soft delete restoration
WHEN MATCHED AND target.deleted_at IS NOT NULL AND source.deleted_at IS NULL THEN
  UPDATE SET
    deleted_at = NULL,
    updated_at = CURRENT_TIMESTAMP()

-- Handle new soft deletes
WHEN MATCHED AND target.deleted_at IS NULL AND source.deleted_at IS NOT NULL THEN
  UPDATE SET
    deleted_at = source.deleted_at,
    updated_at = CURRENT_TIMESTAMP()
*/