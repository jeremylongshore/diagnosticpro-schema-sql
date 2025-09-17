#!/bin/bash

# BigQuery Data Import Pipeline for Diagnostic Data
# Author: Data Pipeline Agent
# Date: 2025-09-02

set -e

# Configuration
PROJECT_ID="diagnostic-pro-start-up"
DATASET_ID="repair_diagnostics"
DATA_DIR="/home/jeremy/projects/scraper/export_gateway/cloud_ready"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting BigQuery Import Pipeline${NC}"
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET_ID"
echo "Data Directory: $DATA_DIR"
echo ""

# Function to log messages
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error_message() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warn_message() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Function to check file exists
check_file() {
    if [ ! -f "$1" ]; then
        error_message "File not found: $1"
        exit 1
    fi
}

# Verify data files exist
log_message "Verifying data files..."
check_file "$DATA_DIR/github_dtc_codes.ndjson"
check_file "$DATA_DIR/reddit_dtc_posts.ndjson" 
check_file "$DATA_DIR/youtube_repairs.ndjson"

# 1. Import GitHub DTC Codes
log_message "Creating table: dtc_codes_github"
bq load \
    --source_format=NEWLINE_DELIMITED_JSON \
    --autodetect \
    --write_disposition=WRITE_TRUNCATE \
    $PROJECT_ID:$DATASET_ID.dtc_codes_github \
    $DATA_DIR/github_dtc_codes.ndjson

if [ $? -eq 0 ]; then
    log_message "Successfully imported GitHub DTC codes"
    # Get row count
    ROW_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(*) as count FROM $PROJECT_ID.$DATASET_ID.dtc_codes_github" | tail -n 1)
    log_message "Imported $ROW_COUNT records to dtc_codes_github"
else
    error_message "Failed to import GitHub DTC codes"
fi

# 2. Import Reddit Diagnostic Posts
log_message "Creating table: reddit_diagnostic_posts"
bq load \
    --source_format=NEWLINE_DELIMITED_JSON \
    --autodetect \
    --write_disposition=WRITE_TRUNCATE \
    $PROJECT_ID:$DATASET_ID.reddit_diagnostic_posts \
    $DATA_DIR/reddit_dtc_posts.ndjson

if [ $? -eq 0 ]; then
    log_message "Successfully imported Reddit diagnostic posts"
    # Get row count
    ROW_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(*) as count FROM $PROJECT_ID.$DATASET_ID.reddit_diagnostic_posts" | tail -n 1)
    log_message "Imported $ROW_COUNT records to reddit_diagnostic_posts"
else
    error_message "Failed to import Reddit diagnostic posts"
fi

# 3. Import YouTube Repair Videos
log_message "Creating table: youtube_repair_videos"
bq load \
    --source_format=NEWLINE_DELIMITED_JSON \
    --autodetect \
    --write_disposition=WRITE_TRUNCATE \
    $PROJECT_ID:$DATASET_ID.youtube_repair_videos \
    $DATA_DIR/youtube_repairs.ndjson

if [ $? -eq 0 ]; then
    log_message "Successfully imported YouTube repair videos"
    # Get row count
    ROW_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(*) as count FROM $PROJECT_ID.$DATASET_ID.youtube_repair_videos" | tail -n 1)
    log_message "Imported $ROW_COUNT records to youtube_repair_videos"
else
    error_message "Failed to import YouTube repair videos"
fi

# 4. Data Validation Queries
log_message "Running data validation queries..."

echo ""
log_message "=== IMPORT SUMMARY ==="

# DTC Codes Summary
echo "GitHub DTC Codes:"
bq query --use_legacy_sql=false --format=prettyjson \
"SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT dtc_code) as unique_dtc_codes,
  COUNT(DISTINCT category) as categories,
  MIN(extraction_date) as earliest_extraction,
  MAX(extraction_date) as latest_extraction
FROM $PROJECT_ID.$DATASET_ID.dtc_codes_github" | head -20

# Reddit Posts Summary  
echo ""
echo "Reddit Diagnostic Posts:"
bq query --use_legacy_sql=false --format=prettyjson \
"SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT equipment.make) as unique_makes,
  COUNT(CASE WHEN equipment.make != 'Unknown' THEN 1 END) as records_with_known_make,
  COUNT(CASE WHEN ARRAY_LENGTH(diagnostic_codes) > 0 THEN 1 END) as records_with_dtc_codes,
  MIN(timestamp) as earliest_post,
  MAX(timestamp) as latest_post
FROM $PROJECT_ID.$DATASET_ID.reddit_diagnostic_posts" | head -20

# YouTube Videos Summary
echo ""
echo "YouTube Repair Videos:"
bq query --use_legacy_sql=false --format=prettyjson \
"SELECT 
  COUNT(*) as total_records,
  COUNT(CASE WHEN title != '' THEN 1 END) as records_with_title,
  COUNT(CASE WHEN video_id != '' THEN 1 END) as records_with_video_id,
  MIN(import_timestamp) as earliest_import,
  MAX(import_timestamp) as latest_import
FROM $PROJECT_ID.$DATASET_ID.youtube_repair_videos" | head -20

log_message "Import pipeline completed successfully!"
echo ""