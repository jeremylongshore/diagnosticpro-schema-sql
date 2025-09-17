#!/bin/bash

# BigQuery Import Pipeline for Sandbox Mode
# Author: Data Pipeline Agent
# Date: 2025-09-02

set -e

# Configuration
PROJECT_ID="diagnostic-pro-start-up"
DATASET_ID="repair_diagnostics"
DATA_DIR="/tmp"
SCHEMA_DIR="/tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Sandbox-Compatible BigQuery Import Pipeline${NC}"
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET_ID"
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

# Update dataset for sandbox compatibility
log_message "Configuring dataset for sandbox mode..."
bq update \
    --default_table_expiration=5184000 \
    --default_partition_expiration=5184000 \
    $PROJECT_ID:$DATASET_ID || warn_message "Failed to update dataset configuration"

# Function to import table with sandbox-compatible settings
import_table() {
    local table_name=$1
    local data_file=$2
    local description=$3
    
    log_message "Importing $description..."
    info_message "Table: $table_name"
    info_message "Data: $data_file"
    
    # Use simple auto-detection for sandbox mode
    if bq load \
        --source_format=NEWLINE_DELIMITED_JSON \
        --autodetect \
        --replace \
        --max_bad_records=100 \
        --expiration=5184000 \
        "$PROJECT_ID:$DATASET_ID.$table_name" \
        "$data_file"; then
        
        # Get row count
        local row_count
        row_count=$(bq query --use_legacy_sql=false --format=csv --quiet --max_rows=1 \
            "SELECT COUNT(*) as count FROM \`$PROJECT_ID.$DATASET_ID.$table_name\`" | tail -n 1)
        
        log_message "Successfully imported $description"
        info_message "Records imported: $row_count"
        
        # Show sample data
        info_message "Sample data:"
        bq query --use_legacy_sql=false --format=table --max_rows=3 \
        "SELECT * FROM \`$PROJECT_ID.$DATASET_ID.$table_name\` LIMIT 3"
        
        return 0
    else
        error_message "Failed to import $description"
        return 1
    fi
}

# Show data file stats
log_message "Data file statistics:"
if [ -f "$DATA_DIR/github_dtc_codes.ndjson" ]; then
    echo "GitHub DTC codes: $(wc -l < $DATA_DIR/github_dtc_codes.ndjson) records, $(du -h $DATA_DIR/github_dtc_codes.ndjson | cut -f1) size"
fi
if [ -f "$DATA_DIR/reddit_dtc_posts.ndjson" ]; then
    echo "Reddit posts: $(wc -l < $DATA_DIR/reddit_dtc_posts.ndjson) records, $(du -h $DATA_DIR/reddit_dtc_posts.ndjson | cut -f1) size"
fi
if [ -f "$DATA_DIR/youtube_repairs.ndjson" ]; then
    echo "YouTube videos: $(wc -l < $DATA_DIR/youtube_repairs.ndjson) records, $(du -h $DATA_DIR/youtube_repairs.ndjson | cut -f1) size"
fi
echo ""

# Track import results
declare -A import_results

# 1. Import GitHub DTC Codes
if [ -f "$DATA_DIR/github_dtc_codes.ndjson" ]; then
    if import_table "dtc_codes_github" \
        "$DATA_DIR/github_dtc_codes.ndjson" \
        "GitHub DTC Codes"; then
        import_results["dtc_codes_github"]="SUCCESS"
    else
        import_results["dtc_codes_github"]="FAILED"
    fi
else
    warn_message "GitHub DTC codes file not found, skipping"
    import_results["dtc_codes_github"]="SKIPPED"
fi

# 2. Import Reddit Diagnostic Posts  
if [ -f "$DATA_DIR/reddit_dtc_posts.ndjson" ]; then
    if import_table "reddit_diagnostic_posts" \
        "$DATA_DIR/reddit_dtc_posts.ndjson" \
        "Reddit Diagnostic Posts"; then
        import_results["reddit_diagnostic_posts"]="SUCCESS"
    else
        import_results["reddit_diagnostic_posts"]="FAILED"
    fi
else
    warn_message "Reddit posts file not found, skipping"
    import_results["reddit_diagnostic_posts"]="SKIPPED"
fi

# 3. Import YouTube Repair Videos
if [ -f "$DATA_DIR/youtube_repairs.ndjson" ]; then
    if import_table "youtube_repair_videos" \
        "$DATA_DIR/youtube_repairs.ndjson" \
        "YouTube Repair Videos"; then
        import_results["youtube_repair_videos"]="SUCCESS"
    else
        import_results["youtube_repair_videos"]="FAILED"
    fi
else
    warn_message "YouTube videos file not found, skipping"
    import_results["youtube_repair_videos"]="SKIPPED"
fi

# Final Summary
echo ""
log_message "=== IMPORT PIPELINE SUMMARY ==="
echo ""

successful_imports=0
for table in "${!import_results[@]}"; do
    status=${import_results[$table]}
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✓ $table: $status${NC}"
            ((successful_imports++))
            ;;
        "FAILED")
            echo -e "${RED}✗ $table: $status${NC}"
            ;;
        "SKIPPED")
            echo -e "${YELLOW}- $table: $status${NC}"
            ;;
    esac
done

echo ""

# Run validation queries if any imports succeeded
if [ $successful_imports -gt 0 ]; then
    log_message "Running validation queries on successful imports..."
    
    # List all tables in the dataset
    info_message "Tables in dataset:"
    bq ls $PROJECT_ID:$DATASET_ID
    
    # DTC Codes Analysis (if successful)
    if [ "${import_results[dtc_codes_github]}" == "SUCCESS" ]; then
        echo ""
        info_message "GitHub DTC Codes Analysis:"
        bq query --use_legacy_sql=false --format=prettyjson --max_rows=1 \
        "SELECT 
          COUNT(*) as total_records,
          COUNT(DISTINCT dtc_code) as unique_dtc_codes,
          COUNT(DISTINCT category) as categories
        FROM \`$PROJECT_ID.$DATASET_ID.dtc_codes_github\`"
    fi
    
    # Reddit Posts Analysis (if successful)
    if [ "${import_results[reddit_diagnostic_posts]}" == "SUCCESS" ]; then
        echo ""
        info_message "Reddit Diagnostic Posts Analysis:"
        bq query --use_legacy_sql=false --format=prettyjson --max_rows=1 \
        "SELECT 
          COUNT(*) as total_records,
          COUNTIF(source_type = 'post') as posts,
          COUNTIF(source_type = 'comment') as comments
        FROM \`$PROJECT_ID.$DATASET_ID.reddit_diagnostic_posts\`"
    fi
    
    # YouTube Videos Analysis (if successful)
    if [ "${import_results[youtube_repair_videos]}" == "SUCCESS" ]; then
        echo ""
        info_message "YouTube Repair Videos Analysis:"
        bq query --use_legacy_sql=false --format=prettyjson --max_rows=1 \
        "SELECT 
          COUNT(*) as total_records,
          COUNT(CASE WHEN title != '' THEN 1 END) as records_with_title
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