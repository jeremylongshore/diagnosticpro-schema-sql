-- =====================================================
-- MERGE Template: Reddit Diagnostic Posts
-- =====================================================
-- Description: Parameterized MERGE statement for reddit_diagnostic_posts data
-- Key: url (unique Reddit post URL)
-- Strategy: UPSERT with nested field handling
-- Source: Reddit automotive/diagnostic subreddits
-- =====================================================

-- Parameter declaration for dynamic SQL execution
DECLARE project_id STRING DEFAULT @project_id;
DECLARE staging_dataset STRING DEFAULT @staging_dataset;
DECLARE prod_dataset STRING DEFAULT @prod_dataset;
DECLARE merge_sql STRING;

-- Dynamic MERGE SQL with parameterization
SET merge_sql = FORMAT("""
MERGE `%s.%s.reddit_diagnostic_posts` AS target
USING `%s.%s.reddit_diagnostic_posts_staging` AS source
ON target.url = source.url

-- When matched: Update existing records with new data
WHEN MATCHED THEN
  UPDATE SET
    equipment = source.equipment,
    diagnostic_codes = source.diagnostic_codes,
    repair_procedure = source.repair_procedure,
    cost = source.cost,
    author = source.author,
    timestamp = source.timestamp,
    source_type = source.source_type,
    source = source.source,
    import_timestamp = CURRENT_TIMESTAMP(),
    updated_at = COALESCE(source.updated_at, CURRENT_TIMESTAMP()),
    -- Handle nested equipment fields
    title = source.title,
    content = source.content,
    upvotes = source.upvotes,
    comments_count = source.comments_count,
    subreddit = source.subreddit

-- When not matched by target: Insert new records
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    equipment,
    diagnostic_codes,
    repair_procedure,
    cost,
    url,
    author,
    timestamp,
    source_type,
    source,
    import_timestamp,
    created_at,
    updated_at,
    title,
    content,
    upvotes,
    comments_count,
    subreddit
  )
  VALUES (
    source.equipment,
    source.diagnostic_codes,
    source.repair_procedure,
    source.cost,
    source.url,
    source.author,
    source.timestamp,
    source.source_type,
    source.source,
    CURRENT_TIMESTAMP(),
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    COALESCE(source.updated_at, CURRENT_TIMESTAMP()),
    source.title,
    source.content,
    source.upvotes,
    source.comments_count,
    source.subreddit
  )

-- When not matched by source: Optional cleanup (commented out for safety)
-- WHEN NOT MATCHED BY SOURCE AND target.source = 'reddit_collector' THEN
--   DELETE
""",
project_id, prod_dataset,     -- Target table
project_id, staging_dataset   -- Source table
);

-- Execute the dynamic MERGE statement
EXECUTE IMMEDIATE merge_sql;

-- Log merge completion with nested field summary
SELECT
  'MERGE COMPLETED' as status,
  'reddit_diagnostic_posts' as table_name,
  CURRENT_TIMESTAMP() as execution_time,
  FORMAT('%s.%s -> %s.%s',
    project_id, staging_dataset,
    project_id, prod_dataset
  ) as operation,
  (
    SELECT COUNT(*)
    FROM `{project_id}.{prod_dataset}.reddit_diagnostic_posts`
    WHERE DATE(import_timestamp) = CURRENT_DATE()
  ) as records_imported_today;