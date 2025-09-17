#!/bin/bash

# =============================================================================
# BigQuery Data Migration Script: Staging to Production
# =============================================================================
#
# Author: DiagnosticPro Platform Team
# Created: 2025-09-16
#
# Purpose: Migrate data from staging (repair_diagnostics) to production
#          (diagnosticpro_prod) dataset with comprehensive safety checks,
#          rollback capabilities, and detailed logging.
#
# Usage:
#   # Dry run (default - safe mode)
#   ./migrate_staging_to_prod.sh
#
#   # Execute migration
#   DRY_RUN=0 ./migrate_staging_to_prod.sh
#
#   # Custom configuration
#   PROJECT=my-project STAGING_DS=my_staging PROD_DS=my_prod DRY_RUN=0 ./migrate_staging_to_prod.sh
#
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# =============================================================================
# CONFIGURATION - Environment Variables with Defaults
# =============================================================================

PROJECT="${PROJECT:-diagnostic-pro-start-up}"
STAGING_DS="${STAGING_DS:-repair_diagnostics}"
PROD_DS="${PROD_DS:-diagnosticpro_prod}"
DRY_RUN="${DRY_RUN:-1}"  # Default to safe mode

# Script metadata
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/migration_logs"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
LOG_FILE="${LOG_DIR}/migration_${TIMESTAMP}.log"
ROLLBACK_FILE="${LOG_DIR}/rollback_${TIMESTAMP}.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# CORE TABLES CONFIGURATION
# =============================================================================

# Tables that must exist in production (will be created if missing)
REQUIRED_CORE_TABLES=(
    "sensor_telemetry"
    "models"
    "feature_store"
    "maintenance_predictions"
)

# Tables with data to migrate (verified from staging)
TABLES_WITH_DATA=(
    "dtc_codes_github"
    "reddit_diagnostic_posts"
    "youtube_repair_videos"
    "equipment_registry"
)

# Unique key mappings for MERGE operations
declare -A TABLE_KEYS=(
    ["dtc_codes_github"]="dtc_code,source"
    ["reddit_diagnostic_posts"]="url"
    ["youtube_repair_videos"]="video_id"
    ["equipment_registry"]="identification_primary"
)

# =============================================================================
# LOGGING AND UTILITY FUNCTIONS
# =============================================================================

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Write to console with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC}  $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        "STEP")  echo -e "${BOLD}[STEP]${NC}  $message" ;;
        *)       echo -e "[LOG]   $message" ;;
    esac
}

# Error handler
error_exit() {
    log "ERROR" "$1"
    echo -e "\n${RED}Migration failed. Check log file: $LOG_FILE${NC}"
    exit 1
}

# Success banner
success_banner() {
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ MIGRATION COMPLETED SUCCESSFULLY${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "📊 Log file: $LOG_FILE"
    echo -e "🔄 Rollback: $ROLLBACK_FILE"
    echo -e "⏰ Duration: $((SECONDS / 60))m $((SECONDS % 60))s"
    echo ""
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if bq command is available and authenticated
check_bq_auth() {
    log "STEP" "Validating BigQuery authentication..."

    if ! command -v bq >/dev/null 2>&1; then
        error_exit "BigQuery CLI (bq) not found. Please install Google Cloud SDK."
    fi

    if ! bq ls >/dev/null 2>&1; then
        error_exit "BigQuery authentication failed. Run: gcloud auth login"
    fi

    log "INFO" "BigQuery authentication verified"
}

# Verify dataset existence
check_datasets() {
    log "STEP" "Verifying dataset existence..."

    # Check staging dataset
    if ! bq ls -d "${PROJECT}:${STAGING_DS}" >/dev/null 2>&1; then
        error_exit "Staging dataset '${STAGING_DS}' not found in project '${PROJECT}'"
    fi
    log "INFO" "Staging dataset verified: ${PROJECT}:${STAGING_DS}"

    # Check production dataset
    if ! bq ls -d "${PROJECT}:${PROD_DS}" >/dev/null 2>&1; then
        error_exit "Production dataset '${PROD_DS}' not found in project '${PROJECT}'"
    fi
    log "INFO" "Production dataset verified: ${PROJECT}:${PROD_DS}"
}

# Check table existence and get row counts
check_table_status() {
    local dataset="$1"
    local table="$2"

    if bq ls "${PROJECT}:${dataset}" 2>/dev/null | grep -q "^${table} "; then
        local count=$(bq query --use_legacy_sql=false --format=csv --max_rows=1 \
            "SELECT COUNT(*) FROM \`${PROJECT}.${dataset}.${table}\`" 2>/dev/null | tail -n1)
        echo "$count"
    else
        echo "0"
    fi
}

# =============================================================================
# CORE TABLE CREATION FUNCTIONS
# =============================================================================

# Create missing core tables based on schema definitions
create_core_tables() {
    log "STEP" "Ensuring core tables exist in production..."

    for table in "${REQUIRED_CORE_TABLES[@]}"; do
        local exists=$(bq ls "${PROJECT}:${PROD_DS}" 2>/dev/null | grep -c "^${table} " || echo "0")

        if [[ "$exists" == "0" ]]; then
            log "INFO" "Creating missing core table: $table"

            if [[ "$DRY_RUN" == "1" ]]; then
                log "DEBUG" "[DRY RUN] Would create table: ${PROJECT}:${PROD_DS}.${table}"
                continue
            fi

            # Create table based on schema type
            case "$table" in
                "sensor_telemetry")
                    create_sensor_telemetry_table
                    ;;
                "models")
                    create_models_table
                    ;;
                "feature_store")
                    create_feature_store_table
                    ;;
                "maintenance_predictions")
                    create_maintenance_predictions_table
                    ;;
                *)
                    log "WARN" "Unknown core table schema: $table"
                    ;;
            esac
        else
            log "INFO" "Core table exists: $table"
        fi
    done
}

# Individual table creation functions
create_sensor_telemetry_table() {
    log "INFO" "Creating sensor_telemetry table..."

    bq mk --table \
        --description="IoT sensor readings and telemetry data from equipment" \
        --time_partitioning_field=reading_date \
        --time_partitioning_type=DAY \
        --clustering_fields=equipment_id,sensor_id \
        "${PROJECT}:${PROD_DS}.sensor_telemetry" \
        "reading_date:DATE,equipment_id:STRING,sensor_id:STRING,reading_timestamp:TIMESTAMP,sensor_type:STRING,sensor_data:JSON,reading_quality:STRING,metadata:JSON,source:STRING,import_timestamp:TIMESTAMP"
}

create_models_table() {
    log "INFO" "Creating models table..."

    bq mk --table \
        --description="ML model registry and metadata" \
        --clustering_fields=model_name,model_version,framework \
        "${PROJECT}:${PROD_DS}.models" \
        "model_id:STRING,model_name:STRING,model_version:STRING,framework:STRING,model_type:STRING,training_data:JSON,performance_metrics:JSON,deployment_config:JSON,metadata:JSON,created_at:TIMESTAMP,updated_at:TIMESTAMP"
}

create_feature_store_table() {
    log "INFO" "Creating feature_store table..."

    bq mk --table \
        --description="Feature store for ML model features" \
        --time_partitioning_field=feature_date \
        --time_partitioning_type=DAY \
        --clustering_fields=entity_type,entity_id,feature_set_name \
        "${PROJECT}:${PROD_DS}.feature_store" \
        "feature_date:DATE,entity_id:STRING,entity_type:STRING,feature_set_name:STRING,feature_set_version:STRING,features:JSON,computed_at:TIMESTAMP,metadata:JSON,created_at:TIMESTAMP"
}

create_maintenance_predictions_table() {
    log "INFO" "Creating maintenance_predictions table..."

    bq mk --table \
        --description="Predictive maintenance forecasts and recommendations" \
        --time_partitioning_field=prediction_date \
        --time_partitioning_type=DAY \
        --clustering_fields=equipment_id,risk_level \
        "${PROJECT}:${PROD_DS}.maintenance_predictions" \
        "prediction_id:STRING,equipment_id:STRING,prediction_date:DATE,risk_level:STRING,failure_probability:FLOAT,recommended_actions:JSON,confidence_score:FLOAT,model_version:STRING,metadata:JSON,created_at:TIMESTAMP,updated_at:TIMESTAMP"
}

# =============================================================================
# SNAPSHOT AND ROLLBACK FUNCTIONS
# =============================================================================

# Create rollback snapshots before migration
create_rollback_snapshots() {
    log "STEP" "Creating rollback snapshots..."

    # Initialize rollback SQL file
    cat > "$ROLLBACK_FILE" << 'EOF'
-- ROLLBACK SCRIPT
-- Generated automatically before migration
-- Run this script to restore pre-migration state

-- WARNING: This will overwrite current data with pre-migration snapshots
-- Only use if migration failed and you need to restore previous state

SET SESSION_TIMEZONE = 'UTC';

EOF

    for table in "${TABLES_WITH_DATA[@]}"; do
        local snapshot_name="${table}_premigration_${TIMESTAMP}"

        log "INFO" "Creating snapshot for table: $table -> $snapshot_name"

        if [[ "$DRY_RUN" == "1" ]]; then
            log "DEBUG" "[DRY RUN] Would create snapshot: $snapshot_name"
            echo "-- [DRY RUN] bq cp ${PROJECT}:${PROD_DS}.${table} ${PROJECT}:${PROD_DS}.${snapshot_name}" >> "$ROLLBACK_FILE"
            continue
        fi

        # Create snapshot table
        if bq cp "${PROJECT}:${PROD_DS}.${table}" "${PROJECT}:${PROD_DS}.${snapshot_name}" 2>/dev/null; then
            log "INFO" "Snapshot created: $snapshot_name"

            # Add rollback commands
            cat >> "$ROLLBACK_FILE" << EOF

-- Rollback table: $table
DROP TABLE IF EXISTS \`${PROJECT}.${PROD_DS}.${table}\`;
CREATE TABLE \`${PROJECT}.${PROD_DS}.${table}\` AS
SELECT * FROM \`${PROJECT}.${PROD_DS}.${snapshot_name}\`;

EOF
        else
            log "WARN" "Failed to create snapshot for $table (table may not exist)"
        fi
    done

    echo "-- End of rollback script" >> "$ROLLBACK_FILE"
    log "INFO" "Rollback script created: $ROLLBACK_FILE"
}

# =============================================================================
# ROW COUNT LOGGING FUNCTIONS
# =============================================================================

# Log row counts before and after migration
log_row_counts() {
    local phase="$1"  # "pre" or "post"
    local counts_file="${LOG_DIR}/row_counts_${phase}_${TIMESTAMP}.csv"

    log "STEP" "Logging $phase-migration row counts..."

    echo "table_name,staging_count,production_count,timestamp" > "$counts_file"

    for table in "${TABLES_WITH_DATA[@]}"; do
        local staging_count=$(check_table_status "$STAGING_DS" "$table")
        local prod_count=$(check_table_status "$PROD_DS" "$table")

        echo "${table},${staging_count},${prod_count},$(date -Iseconds)" >> "$counts_file"
        log "INFO" "$phase-migration: $table -> staging:$staging_count, prod:$prod_count"
    done

    # Also check core tables
    for table in "${REQUIRED_CORE_TABLES[@]}"; do
        local staging_count=$(check_table_status "$STAGING_DS" "$table")
        local prod_count=$(check_table_status "$PROD_DS" "$table")

        echo "${table},${staging_count},${prod_count},$(date -Iseconds)" >> "$counts_file"
    done

    log "INFO" "Row counts saved to: $counts_file"
}

# =============================================================================
# MERGE OPERATION FUNCTIONS
# =============================================================================

# Execute MERGE operation for a specific table
execute_merge() {
    local table="$1"
    local keys="${TABLE_KEYS[$table]}"

    log "INFO" "Starting MERGE operation for table: $table (keys: $keys)"

    if [[ "$DRY_RUN" == "1" ]]; then
        log "DEBUG" "[DRY RUN] Would execute MERGE for $table using keys: $keys"
        return 0
    fi

    # Generate table-specific MERGE SQL
    local merge_sql=""
    case "$table" in
        "dtc_codes_github")
            merge_sql=$(generate_dtc_codes_merge_sql)
            ;;
        "reddit_diagnostic_posts")
            merge_sql=$(generate_reddit_posts_merge_sql)
            ;;
        "youtube_repair_videos")
            merge_sql=$(generate_youtube_videos_merge_sql)
            ;;
        "equipment_registry")
            merge_sql=$(generate_equipment_registry_merge_sql)
            ;;
        *)
            error_exit "Unknown table for MERGE: $table"
            ;;
    esac

    # Execute the MERGE
    local temp_sql_file="${LOG_DIR}/merge_${table}_${TIMESTAMP}.sql"
    echo "$merge_sql" > "$temp_sql_file"

    log "INFO" "Executing MERGE for $table..."
    if bq query --use_legacy_sql=false --max_rows=0 "$merge_sql"; then
        log "INFO" "MERGE completed successfully for $table"
    else
        error_exit "MERGE failed for $table. Check SQL: $temp_sql_file"
    fi
}

# =============================================================================
# MERGE SQL GENERATION FUNCTIONS
# =============================================================================

generate_dtc_codes_merge_sql() {
    cat << EOF
MERGE \`${PROJECT}.${PROD_DS}.dtc_codes_github\` AS target
USING (
  SELECT DISTINCT
    staging.*
  FROM \`${PROJECT}.${STAGING_DS}.dtc_codes_github\` AS staging
  WHERE staging.dtc_code IS NOT NULL
    AND REGEXP_CONTAINS(staging.dtc_code, r'^[PBCU]\\d{4}\$')  -- Valid DTC format
) AS source
ON target.dtc_code = source.dtc_code
   AND COALESCE(target.source, '') = COALESCE(source.source, '')

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
EOF
}

generate_reddit_posts_merge_sql() {
    cat << EOF
MERGE \`${PROJECT}.${PROD_DS}.reddit_diagnostic_posts\` AS target
USING (
  SELECT DISTINCT
    staging.*
  FROM \`${PROJECT}.${STAGING_DS}.reddit_diagnostic_posts\` AS staging
  WHERE staging.url IS NOT NULL
) AS source
ON target.url = source.url

WHEN MATCHED THEN
  UPDATE SET
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
    equipment, diagnostic_codes, repair_procedure, cost,
    url, author, timestamp, source_type, source, import_timestamp
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
    CURRENT_TIMESTAMP()
  );
EOF
}

generate_youtube_videos_merge_sql() {
    cat << EOF
MERGE \`${PROJECT}.${PROD_DS}.youtube_repair_videos\` AS target
USING (
  SELECT DISTINCT
    staging.*
  FROM \`${PROJECT}.${STAGING_DS}.youtube_repair_videos\` AS staging
  WHERE staging.video_id IS NOT NULL
    AND REGEXP_CONTAINS(staging.video_id, r'^[a-zA-Z0-9_-]{11}\$')  -- Valid YouTube video ID
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
EOF
}

generate_equipment_registry_merge_sql() {
    cat << EOF
MERGE \`${PROJECT}.${PROD_DS}.equipment_registry\` AS target
USING (
  SELECT DISTINCT
    -- Deduplication: Use latest record per identification_primary
    ARRAY_AGG(staging ORDER BY COALESCE(staging.updated_at, staging.created_at) DESC LIMIT 1)[OFFSET(0)].*
  FROM \`${PROJECT}.${STAGING_DS}.equipment_registry\` AS staging
  WHERE staging.identification_primary IS NOT NULL
    AND COALESCE(staging.deleted_at, TIMESTAMP('1970-01-01')) = TIMESTAMP('1970-01-01')  -- Exclude soft-deleted records
  GROUP BY staging.identification_primary
) AS source
ON target.identification_primary = source.identification_primary

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
    source = COALESCE(source.source, target.source),
    created_at = COALESCE(target.created_at, source.created_at),
    updated_at = CURRENT_TIMESTAMP(),
    deleted_at = source.deleted_at

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
EOF
}

# =============================================================================
# VALIDATION AND POST-MIGRATION CHECKS
# =============================================================================

# Validate migration results
validate_migration() {
    log "STEP" "Validating migration results..."

    local validation_errors=0

    # Check for duplicate keys
    for table in "${TABLES_WITH_DATA[@]}"; do
        local keys="${TABLE_KEYS[$table]}"

        case "$table" in
            "dtc_codes_github"|"reddit_diagnostic_posts"|"youtube_repair_videos"|"equipment_registry")
                local duplicate_check_sql=""
                case "$table" in
                    "dtc_codes_github")
                        duplicate_check_sql="SELECT dtc_code, source, COUNT(*) as cnt FROM \`${PROJECT}.${PROD_DS}.${table}\` GROUP BY dtc_code, source HAVING COUNT(*) > 1"
                        ;;
                    "reddit_diagnostic_posts")
                        duplicate_check_sql="SELECT url, COUNT(*) as cnt FROM \`${PROJECT}.${PROD_DS}.${table}\` GROUP BY url HAVING COUNT(*) > 1"
                        ;;
                    "youtube_repair_videos")
                        duplicate_check_sql="SELECT video_id, COUNT(*) as cnt FROM \`${PROJECT}.${PROD_DS}.${table}\` GROUP BY video_id HAVING COUNT(*) > 1"
                        ;;
                    "equipment_registry")
                        duplicate_check_sql="SELECT identification_primary, COUNT(*) as cnt FROM \`${PROJECT}.${PROD_DS}.${table}\` GROUP BY identification_primary HAVING COUNT(*) > 1"
                        ;;
                esac

                if [[ "$DRY_RUN" == "1" ]]; then
                    log "DEBUG" "[DRY RUN] Would check for duplicates in $table"
                    continue
                fi

                local duplicates=$(bq query --use_legacy_sql=false --format=csv --max_rows=1 "$duplicate_check_sql" 2>/dev/null | wc -l)
                if [[ "$duplicates" -gt 1 ]]; then
                    log "ERROR" "Duplicate keys found in $table"
                    ((validation_errors++))
                else
                    log "INFO" "No duplicate keys in $table"
                fi
                ;;
        esac
    done

    if [[ "$validation_errors" -gt 0 ]]; then
        error_exit "Migration validation failed with $validation_errors errors"
    fi

    log "INFO" "Migration validation completed successfully"
}

# =============================================================================
# MAIN EXECUTION FLOW
# =============================================================================

main() {
    echo -e "\n${BOLD}🚀 BigQuery Data Migration: Staging → Production${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "📊 Project: ${BLUE}$PROJECT${NC}"
    echo -e "🔄 Staging: ${BLUE}$STAGING_DS${NC} → Production: ${BLUE}$PROD_DS${NC}"
    echo -e "🛡️  Mode: $([[ "$DRY_RUN" == "1" ]] && echo -e "${YELLOW}DRY RUN${NC}" || echo -e "${GREEN}LIVE EXECUTION${NC}")"
    echo -e "📝 Log: $LOG_FILE"
    echo ""

    log "INFO" "Starting migration process..."
    log "INFO" "Configuration: PROJECT=$PROJECT, STAGING_DS=$STAGING_DS, PROD_DS=$PROD_DS, DRY_RUN=$DRY_RUN"

    # Step 1: Validation
    check_bq_auth
    check_datasets

    # Step 2: Pre-migration logging
    log_row_counts "pre"

    # Step 3: Create rollback snapshots
    create_rollback_snapshots

    # Step 4: Ensure core tables exist
    create_core_tables

    # Step 5: Execute MERGE operations for tables with data
    for table in "${TABLES_WITH_DATA[@]}"; do
        execute_merge "$table"
    done

    # Step 6: Post-migration validation
    validate_migration

    # Step 7: Post-migration logging
    log_row_counts "post"

    # Step 8: Success
    if [[ "$DRY_RUN" == "1" ]]; then
        echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}✅ DRY RUN COMPLETED SUCCESSFULLY${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "📋 All checks passed. Set DRY_RUN=0 to execute migration."
        echo -e "📊 Log file: $LOG_FILE"
        echo ""
    else
        success_banner
    fi

    log "INFO" "Migration process completed in $((SECONDS / 60))m $((SECONDS % 60))s"
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Trap errors for cleanup
trap 'error_exit "Script interrupted or failed at line $LINENO"' ERR

# Track execution time
SECONDS=0

# Execute main function
main "$@"

# Exit successfully
exit 0