-- =====================================================
-- MERGE Template: YouTube Repair Videos
-- =====================================================
-- Description: Parameterized MERGE statement for youtube_repair_videos data
-- Key: video_id (unique YouTube video identifier)
-- Strategy: UPSERT with metadata enhancement
-- Source: YouTube automotive repair channels
-- =====================================================

-- Parameter declaration for dynamic SQL execution
DECLARE project_id STRING DEFAULT @project_id;
DECLARE staging_dataset STRING DEFAULT @staging_dataset;
DECLARE prod_dataset STRING DEFAULT @prod_dataset;
DECLARE merge_sql STRING;

-- Dynamic MERGE SQL with parameterization
SET merge_sql = FORMAT("""
MERGE `%s.%s.youtube_repair_videos` AS target
USING `%s.%s.youtube_repair_videos_staging` AS source
ON target.video_id = source.video_id

-- When matched: Update existing records with enhanced metadata
WHEN MATCHED THEN
  UPDATE SET
    title = source.title,
    channel = source.channel,
    description = source.description,
    source = source.source,
    import_timestamp = CURRENT_TIMESTAMP(),
    updated_at = COALESCE(source.updated_at, CURRENT_TIMESTAMP()),
    -- Enhanced fields for video metadata
    duration = source.duration,
    view_count = source.view_count,
    like_count = source.like_count,
    published_at = source.published_at,
    channel_id = source.channel_id,
    tags = source.tags,
    transcript = source.transcript,
    thumbnail_url = source.thumbnail_url,
    video_quality = source.video_quality,
    language = source.language

-- When not matched by target: Insert new records
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    video_id,
    title,
    channel,
    description,
    source,
    import_timestamp,
    created_at,
    updated_at,
    duration,
    view_count,
    like_count,
    published_at,
    channel_id,
    tags,
    transcript,
    thumbnail_url,
    video_quality,
    language
  )
  VALUES (
    source.video_id,
    source.title,
    source.channel,
    source.description,
    source.source,
    CURRENT_TIMESTAMP(),
    COALESCE(source.created_at, CURRENT_TIMESTAMP()),
    COALESCE(source.updated_at, CURRENT_TIMESTAMP()),
    source.duration,
    source.view_count,
    source.like_count,
    source.published_at,
    source.channel_id,
    source.tags,
    source.transcript,
    source.thumbnail_url,
    source.video_quality,
    source.language
  )

-- When not matched by source: Optional cleanup for deleted videos
-- WHEN NOT MATCHED BY SOURCE AND target.source = 'youtube_scraper' THEN
--   UPDATE SET
--     is_deleted = true,
--     deleted_at = CURRENT_TIMESTAMP(),
--     updated_at = CURRENT_TIMESTAMP()
""",
project_id, prod_dataset,     -- Target table
project_id, staging_dataset   -- Source table
);

-- Execute the dynamic MERGE statement
EXECUTE IMMEDIATE merge_sql;

-- Log merge completion with video analytics
SELECT
  'MERGE COMPLETED' as status,
  'youtube_repair_videos' as table_name,
  CURRENT_TIMESTAMP() as execution_time,
  FORMAT('%s.%s -> %s.%s',
    project_id, staging_dataset,
    project_id, prod_dataset
  ) as operation,
  (
    SELECT COUNT(*)
    FROM `{project_id}.{prod_dataset}.youtube_repair_videos`
    WHERE DATE(import_timestamp) = CURRENT_DATE()
  ) as records_imported_today,
  (
    SELECT COUNT(DISTINCT channel)
    FROM `{project_id}.{prod_dataset}.youtube_repair_videos`
  ) as unique_channels;