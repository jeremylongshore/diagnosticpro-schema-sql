-- =====================================================
-- MERGE Template: Equipment Registry
-- =====================================================
-- Description: Parameterized MERGE statement for equipment_registry data
-- Key: identification_primary (unique equipment identifier)
-- Strategy: UPSERT with complex nested structures
-- Source: Universal Equipment Registry consolidation
-- =====================================================

-- Parameter declaration for dynamic SQL execution
DECLARE project_id STRING DEFAULT @project_id;
DECLARE staging_dataset STRING DEFAULT @staging_dataset;
DECLARE prod_dataset STRING DEFAULT @prod_dataset;
DECLARE merge_sql STRING;

-- Dynamic MERGE SQL with parameterization
SET merge_sql = FORMAT("""
MERGE `%s.%s.equipment_registry` AS target
USING `%s.%s.equipment_registry_staging` AS source
ON target.identification_primary = source.identification_primary

-- When matched: Update existing records with enhanced data
WHEN MATCHED THEN
  UPDATE SET
    identification_primary_type = source.identification_primary_type,
    secondary_identifiers = source.secondary_identifiers,
    equipment_category = source.equipment_category,
    manufacturer = source.manufacturer,
    model = source.model,
    model_year = source.model_year,
    production_date = source.production_date,
    specifications = source.specifications,
    ownership = source.ownership,
    location = source.location,
    maintenance_schedule = source.maintenance_schedule,
    warranty = source.warranty,
    regulatory_compliance = source.regulatory_compliance,
    operational_status = source.operational_status,
    metadata = source.metadata,
    data_sources = source.data_sources,
    import_timestamp = CURRENT_TIMESTAMP(),
    updated_at = COALESCE(source.updated_at, CURRENT_TIMESTAMP()),
    -- Audit trail fields
    last_maintenance_date = source.last_maintenance_date,
    next_maintenance_due = source.next_maintenance_due,
    total_operating_hours = source.total_operating_hours,
    mileage = source.mileage

-- When not matched by target: Insert new equipment records
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    id,
    identification_primary_type,
    identification_primary,
    secondary_identifiers,
    equipment_category,
    manufacturer,
    model,
    model_year,
    production_date,
    specifications,
    ownership,
    location,
    maintenance_schedule,
    warranty,
    regulatory_compliance,
    operational_status,
    metadata,
    data_sources,
    import_timestamp,
    created_at,
    updated_at,
    last_maintenance_date,
    next_maintenance_due,
    total_operating_hours,
    mileage
  )
  VALUES (
    COALESCE(source.id, GENERATE_UUID()),
    source.identification_primary_type,
    source.identification_primary,
    source.secondary_identifiers,
    source.equipment_category,
    source.manufacturer,
    source.model,
    source.model_year,
    source.production_date,
    source.specifications,
    source.ownership,
    source.location,
    source.maintenance_schedule,
    source.warranty,
    source.regulatory_compliance,
    COALESCE(source.operational_status, 'active'),
    source.metadata,
    source.data_sources,
    CURRENT_TIMESTAMP(),
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    COALESCE(source.updated_at, CURRENT_TIMESTAMP()),
    source.last_maintenance_date,
    source.next_maintenance_due,
    source.total_operating_hours,
    source.mileage
  )

-- When not matched by source: Mark as inactive (soft delete)
-- WHEN NOT MATCHED BY SOURCE AND target.operational_status = 'active' THEN
--   UPDATE SET
--     operational_status = 'inactive',
--     updated_at = CURRENT_TIMESTAMP(),
--     metadata = JSON_SET(COALESCE(metadata, JSON '{}'), '$.deactivated_at', CURRENT_TIMESTAMP())
""",
project_id, prod_dataset,     -- Target table
project_id, staging_dataset   -- Source table
);

-- Execute the dynamic MERGE statement
EXECUTE IMMEDIATE merge_sql;

-- Log merge completion with equipment analytics
SELECT
  'MERGE COMPLETED' as status,
  'equipment_registry' as table_name,
  CURRENT_TIMESTAMP() as execution_time,
  FORMAT('%s.%s -> %s.%s',
    project_id, staging_dataset,
    project_id, prod_dataset
  ) as operation,
  (
    SELECT COUNT(*)
    FROM `{project_id}.{prod_dataset}.equipment_registry`
    WHERE DATE(import_timestamp) = CURRENT_DATE()
  ) as records_imported_today,
  (
    SELECT COUNT(DISTINCT equipment_category)
    FROM `{project_id}.{prod_dataset}.equipment_registry`
  ) as equipment_categories,
  (
    SELECT COUNT(*)
    FROM `{project_id}.{prod_dataset}.equipment_registry`
    WHERE operational_status = 'active'
  ) as active_equipment;