#!/bin/bash

# Enhanced BigQuery Data Import Pipeline with Explicit Schemas
# Author: Data Pipeline Agent
# Date: 2025-09-02

set -e

# Configuration
PROJECT_ID="diagnostic-pro-start-up"
DATASET_ID="repair_diagnostics"
DATA_DIR="/home/jeremy/projects/scraper/export_gateway/cloud_ready"
SCHEMA_DIR="/home/jeremy/projects/schema"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Enhanced BigQuery Import Pipeline${NC}"
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET_ID"
echo "Data Directory: $DATA_DIR"
echo "Schema Directory: $SCHEMA_DIR"
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

info_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to check file exists
check_file() {
    if [ ! -f "$1" ]; then
        error_message "File not found: $1"
        exit 1
    fi
}

# Function to import table with schema and error handling
import_table() {
    local table_name=$1
    local data_file=$2
    local schema_file=$3
    local description=$4
    
    log_message "Importing $description..."
    info_message "Table: $table_name"
    info_message "Data: $data_file"
    info_message "Schema: $schema_file"
    
    # First, let's see if we can load with auto-detect and compare
    local temp_table="${table_name}_temp"
    
    # Load with explicit schema
    if bq load \
        --source_format=NEWLINE_DELIMITED_JSON \
        --schema="$schema_file" \
        --write_disposition=WRITE_TRUNCATE \
        --max_bad_records=100 \
        "$PROJECT_ID:$DATASET_ID.$table_name" \
        "$data_file"; then
        
        # Get row count and basic stats
        local row_count
        row_count=$(bq query --use_legacy_sql=false --format=csv --quiet \
            "SELECT COUNT(*) as count FROM \`$PROJECT_ID.$DATASET_ID.$table_name\`" | tail -n 1)
        
        log_message "Successfully imported $description"
        info_message "Records imported: $row_count"
        
        # Sample a few records to verify structure
        echo ""
        info_message "Sample records from $table_name:"
        bq query --use_legacy_sql=false --format=prettyjson --max_rows=2 \
            "SELECT * FROM \`$PROJECT_ID.$DATASET_ID.$table_name\` LIMIT 2" | head -30
        echo ""
        
        return 0
    else
        error_message "Failed to import $description with explicit schema"
        warn_message "Attempting import with auto-detection..."
        
        # Fallback to auto-detect
        if bq load \
            --source_format=NEWLINE_DELIMITED_JSON \
            --autodetect \
            --write_disposition=WRITE_TRUNCATE \
            --max_bad_records=100 \
            "$PROJECT_ID:$DATASET_ID.$table_name" \
            "$data_file"; then
            
            warn_message "Successfully imported $description with auto-detection"
            local row_count
            row_count=$(bq query --use_legacy_sql=false --format=csv --quiet \
                "SELECT COUNT(*) as count FROM \`$PROJECT_ID.$DATASET_ID.$table_name\`" | tail -n 1)
            info_message "Records imported: $row_count"
            return 0
        else
            error_message "Failed to import $description even with auto-detection"
            return 1
        fi
    fi
}

# Verify all files exist
log_message "Verifying files..."
check_file "$DATA_DIR/github_dtc_codes.ndjson"
check_file "$DATA_DIR/reddit_dtc_posts.ndjson" 
check_file "$DATA_DIR/youtube_repairs.ndjson"
check_file "$SCHEMA_DIR/dtc_codes_github_schema.json"
check_file "$SCHEMA_DIR/reddit_diagnostic_posts_schema.json"
check_file "$SCHEMA_DIR/youtube_repair_videos_schema.json"

# Show data file stats
log_message "Data file statistics:"
echo "GitHub DTC codes: $(wc -l < $DATA_DIR/github_dtc_codes.ndjson) records, $(du -h $DATA_DIR/github_dtc_codes.ndjson | cut -f1) size"
echo "Reddit posts: $(wc -l < $DATA_DIR/reddit_dtc_posts.ndjson) records, $(du -h $DATA_DIR/reddit_dtc_posts.ndjson | cut -f1) size"
echo "YouTube videos: $(wc -l < $DATA_DIR/youtube_repairs.ndjson) records, $(du -h $DATA_DIR/youtube_repairs.ndjson | cut -f1) size"
echo ""

# Track import results
declare -A import_results

# 1. Import GitHub DTC Codes
if import_table "dtc_codes_github" \
    "$DATA_DIR/github_dtc_codes.ndjson" \
    "$SCHEMA_DIR/dtc_codes_github_schema.json" \
    "GitHub DTC Codes"; then
    import_results["dtc_codes_github"]="SUCCESS"
else
    import_results["dtc_codes_github"]="FAILED"
fi

# 2. Import Reddit Diagnostic Posts  
if import_table "reddit_diagnostic_posts" \
    "$DATA_DIR/reddit_dtc_posts.ndjson" \
    "$SCHEMA_DIR/reddit_diagnostic_posts_schema.json" \
    "Reddit Diagnostic Posts"; then
    import_results["reddit_diagnostic_posts"]="SUCCESS"
else
    import_results["reddit_diagnostic_posts"]="FAILED"
fi

# 3. Import YouTube Repair Videos
if import_table "youtube_repair_videos" \
    "$DATA_DIR/youtube_repairs.ndjson" \
    "$SCHEMA_DIR/youtube_repair_videos_schema.json" \
    "YouTube Repair Videos"; then
    import_results["youtube_repair_videos"]="SUCCESS"
else
    import_results["youtube_repair_videos"]="FAILED"
fi

# Final Summary
echo ""
log_message "=== IMPORT PIPELINE SUMMARY ==="
echo ""

for table in "${!import_results[@]}"; do
    status=${import_results[$table]}
    if [ "$status" == "SUCCESS" ]; then
        echo -e "${GREEN}✓ $table: $status${NC}"
    else
        echo -e "${RED}✗ $table: $status${NC}"
    fi
done

echo ""

# Run comprehensive validation queries if any imports succeeded
successful_imports=0
for status in "${import_results[@]}"; do
    if [ "$status" == "SUCCESS" ]; then
        ((successful_imports++))
    fi
done

if [ $successful_imports -gt 0 ]; then
    log_message "Running validation queries on successful imports..."
    
    # DTC Codes Analysis (if successful)
    if [ "${import_results[dtc_codes_github]}" == "SUCCESS" ]; then
        echo ""
        info_message "GitHub DTC Codes Analysis:"
        bq query --use_legacy_sql=false --format=prettyjson \
        "SELECT 
          COUNT(*) as total_records,
          COUNT(DISTINCT dtc_code) as unique_dtc_codes,
          COUNT(DISTINCT category) as categories,
          COUNTIF(category = 'P') as powertrain_codes,
          COUNTIF(category = 'B') as body_codes,
          COUNTIF(category = 'C') as chassis_codes,
          COUNTIF(category = 'U') as network_codes,
          MIN(extraction_date) as earliest_extraction,
          MAX(extraction_date) as latest_extraction
        FROM \`$PROJECT_ID.$DATASET_ID.dtc_codes_github\`"
    fi
    
    # Reddit Posts Analysis (if successful)
    if [ "${import_results[reddit_diagnostic_posts]}" == "SUCCESS" ]; then
        echo ""
        info_message "Reddit Diagnostic Posts Analysis:"
        bq query --use_legacy_sql=false --format=prettyjson \
        "SELECT 
          COUNT(*) as total_records,
          COUNT(DISTINCT equipment.make) as unique_makes,
          COUNT(CASE WHEN equipment.make != 'Unknown' THEN 1 END) as records_with_known_make,
          COUNT(CASE WHEN ARRAY_LENGTH(diagnostic_codes) > 0 THEN 1 END) as records_with_dtc_codes,
          COUNTIF(source_type = 'post') as posts,
          COUNTIF(source_type = 'comment') as comments,
          MIN(timestamp) as earliest_post,
          MAX(timestamp) as latest_post
        FROM \`$PROJECT_ID.$DATASET_ID.reddit_diagnostic_posts\`"
    fi
    
    # YouTube Videos Analysis (if successful)
    if [ "${import_results[youtube_repair_videos]}" == "SUCCESS" ]; then
        echo ""
        info_message "YouTube Repair Videos Analysis:"
        bq query --use_legacy_sql=false --format=prettyjson \
        "SELECT 
          COUNT(*) as total_records,
          COUNT(CASE WHEN title != '' THEN 1 END) as records_with_title,
          COUNT(CASE WHEN video_id != '' THEN 1 END) as records_with_video_id,
          COUNT(CASE WHEN channel != '' THEN 1 END) as records_with_channel,
          MIN(import_timestamp) as earliest_import,
          MAX(import_timestamp) as latest_import
        FROM \`$PROJECT_ID.$DATASET_ID.youtube_repair_videos\`"
    fi
fi

echo ""
if [ $successful_imports -eq 3 ]; then
    log_message "All imports completed successfully! 🎉"
elif [ $successful_imports -gt 0 ]; then
    warn_message "$successful_imports out of 3 imports completed successfully"
else
    error_message "All imports failed"
    exit 1
fi

log_message "BigQuery import pipeline completed"