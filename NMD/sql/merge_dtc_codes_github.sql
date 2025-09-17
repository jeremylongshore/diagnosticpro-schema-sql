-- =====================================================
-- MERGE Template: DTC Codes from GitHub
-- =====================================================
-- Description: Parameterized MERGE statement for dtc_codes_github data
-- Key: (dtc_code, source)
-- Strategy: UPSERT with updated_at timestamp handling
-- Source: GitHub DTC code repositories
-- =====================================================

-- Parameter declaration for dynamic SQL execution
DECLARE project_id STRING DEFAULT @project_id;
DECLARE staging_dataset STRING DEFAULT @staging_dataset;
DECLARE prod_dataset STRING DEFAULT @prod_dataset;
DECLARE merge_sql STRING;

-- Dynamic MERGE SQL with parameterization
SET merge_sql = FORMAT("""
MERGE `%s.%s.dtc_codes_github` AS target
USING `%s.%s.dtc_codes_github_staging` AS source
ON target.dtc_code = source.dtc_code
   AND target.source = source.source

-- When matched: Update existing records with new data
WHEN MATCHED THEN
  UPDATE SET
    description = source.description,
    category = source.category,
    category_desc = source.category_desc,
    extraction_date = source.extraction_date,
    import_timestamp = CURRENT_TIMESTAMP(),
    updated_at = COALESCE(source.updated_at, CURRENT_TIMESTAMP())

-- When not matched by target: Insert new records
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    dtc_code,
    description,
    category,
    category_desc,
    source,
    extraction_date,
    import_timestamp,
    created_at,
    updated_at
  )
  VALUES (
    source.dtc_code,
    source.description,
    source.category,
    source.category_desc,
    source.source,
    source.extraction_date,
    CURRENT_TIMESTAMP(),
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    COALESCE(source.updated_at, CURRENT_TIMESTAMP())
  )

-- When not matched by source: Optional cleanup (commented out for safety)
-- WHEN NOT MATCHED BY SOURCE AND target.source = 'github' THEN
--   DELETE
""",
project_id, prod_dataset,     -- Target table
project_id, staging_dataset   -- Source table
);

-- Execute the dynamic MERGE statement
EXECUTE IMMEDIATE merge_sql;

-- Log merge completion
SELECT
  'MERGE COMPLETED' as status,
  'dtc_codes_github' as table_name,
  CURRENT_TIMESTAMP() as execution_time,
  FORMAT('%s.%s -> %s.%s',
    project_id, staging_dataset,
    project_id, prod_dataset
  ) as operation;