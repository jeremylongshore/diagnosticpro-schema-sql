#!/bin/bash

# validate_post_migration.sh
# Post-Migration Validation Script for DiagnosticPro BigQuery Platform
# Version: 1.0.0
# Generated: 2025-09-16
# Purpose: Execute comprehensive post-migration validation with logging

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ==============================================================================
# CONFIGURATION AND DEFAULTS
# ==============================================================================

# Default values (can be overridden by environment variables or arguments)
PROJECT_ID="${PROJECT_ID:-diagnostic-pro-start-up}"
STAGING_DATASET="${STAGING_DATASET:-diagnosticpro_staging}"
PROD_DATASET="${PROD_DATASET:-diagnosticpro_prod}"
REPAIR_DATASET="${REPAIR_DATASET:-repair_diagnostics}"

# Script directory and log directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../migration_logs"
VALIDATION_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/validate_${VALIDATION_TIMESTAMP}.txt"
TEMP_SQL_FILE="${SCRIPT_DIR}/validate_post_migration_${VALIDATION_TIMESTAMP}.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} - ${message}" | tee -a "${LOG_FILE}"
}

log_error() {
    local message="$1"
    log "${RED}ERROR: ${message}${NC}"
}

log_success() {
    local message="$1"
    log "${GREEN}SUCCESS: ${message}${NC}"
}

log_warning() {
    local message="$1"
    log "${YELLOW}WARNING: ${message}${NC}"
}

log_info() {
    local message="$1"
    log "${BLUE}INFO: ${message}${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Post-migration validation script for DiagnosticPro BigQuery platform.

OPTIONS:
    -p, --project PROJECT_ID        GCP project ID (default: ${PROJECT_ID})
    -s, --staging STAGING_DATASET   Staging dataset name (default: ${STAGING_DATASET})
    -d, --prod PROD_DATASET         Production dataset name (default: ${PROD_DATASET})
    -r, --repair REPAIR_DATASET     Repair dataset name (default: ${REPAIR_DATASET})
    -l, --log-dir LOG_DIR           Log directory (default: ${LOG_DIR})
    -h, --help                      Show this help message

EXAMPLES:
    # Run with defaults
    $0

    # Run with custom project and datasets
    $0 --project my-project --staging my_staging --prod my_prod

    # Run with environment variables
    PROJECT_ID=my-project STAGING_DATASET=my_staging $0

ENVIRONMENT VARIABLES:
    PROJECT_ID       - GCP project ID
    STAGING_DATASET  - Staging dataset name
    PROD_DATASET     - Production dataset name
    REPAIR_DATASET   - Repair dataset name

EXIT CODES:
    0 - All validations passed
    1 - Validation failures detected
    2 - Script execution error
    3 - Missing dependencies
EOF
}

check_dependencies() {
    log_info "Checking dependencies..."

    # Check if bq command is available
    if ! command -v bq &> /dev/null; then
        log_error "Google Cloud SDK 'bq' command not found. Please install Google Cloud SDK."
        return 3
    fi

    # Check if authenticated
    if ! bq ls &> /dev/null; then
        log_error "Not authenticated with Google Cloud. Please run 'gcloud auth login' and 'gcloud auth application-default login'."
        return 3
    fi

    # Check if SQL file exists
    if [[ ! -f "${SCRIPT_DIR}/validate_post_migration.sql" ]]; then
        log_error "SQL validation file not found: ${SCRIPT_DIR}/validate_post_migration.sql"
        return 3
    fi

    log_success "All dependencies satisfied"
    return 0
}

create_log_directory() {
    if [[ ! -d "${LOG_DIR}" ]]; then
        log_info "Creating log directory: ${LOG_DIR}"
        mkdir -p "${LOG_DIR}" || {
            log_error "Failed to create log directory: ${LOG_DIR}"
            return 2
        }
    fi
}

substitute_parameters() {
    log_info "Substituting parameters in SQL file..."

    # Create a temporary SQL file with substituted parameters
    sed -e "s/@project_id/${PROJECT_ID}/g" \
        -e "s/@staging_dataset/${STAGING_DATASET}/g" \
        -e "s/@prod_dataset/${PROD_DATASET}/g" \
        -e "s/@validation_timestamp/${VALIDATION_TIMESTAMP}/g" \
        "${SCRIPT_DIR}/validate_post_migration.sql" > "${TEMP_SQL_FILE}" || {
        log_error "Failed to substitute parameters in SQL file"
        return 2
    }

    log_success "Parameters substituted successfully"
    return 0
}

verify_datasets_exist() {
    log_info "Verifying that required datasets exist..."

    local datasets=("${STAGING_DATASET}" "${PROD_DATASET}" "${REPAIR_DATASET}")
    local missing_datasets=()

    for dataset in "${datasets[@]}"; do
        if ! bq ls "${PROJECT_ID}:${dataset}" &> /dev/null; then
            missing_datasets+=("${dataset}")
        fi
    done

    if [[ ${#missing_datasets[@]} -gt 0 ]]; then
        log_warning "The following datasets do not exist: ${missing_datasets[*]}"
        log_warning "Validation will continue but may fail for missing datasets"
    else
        log_success "All required datasets exist"
    fi

    return 0
}

execute_validation() {
    log_info "Executing post-migration validation queries..."

    local validation_output="${LOG_DIR}/validation_results_${VALIDATION_TIMESTAMP}.csv"
    local error_output="${LOG_DIR}/validation_errors_${VALIDATION_TIMESTAMP}.txt"

    # Execute the validation SQL
    if bq query \
        --use_legacy_sql=false \
        --format=csv \
        --max_rows=1000 \
        --project_id="${PROJECT_ID}" \
        < "${TEMP_SQL_FILE}" > "${validation_output}" 2> "${error_output}"; then

        log_success "Validation queries executed successfully"
        log_info "Results saved to: ${validation_output}"

        # Check if there were any warnings in stderr
        if [[ -s "${error_output}" ]]; then
            log_warning "Warnings during execution:"
            cat "${error_output}" | tee -a "${LOG_FILE}"
        fi

        return 0
    else
        log_error "Validation queries failed"
        if [[ -s "${error_output}" ]]; then
            log_error "Error details:"
            cat "${error_output}" | tee -a "${LOG_FILE}"
        fi
        return 1
    fi
}

analyze_results() {
    local validation_output="${LOG_DIR}/validation_results_${VALIDATION_TIMESTAMP}.csv"

    if [[ ! -f "${validation_output}" ]]; then
        log_error "Validation results file not found: ${validation_output}"
        return 2
    fi

    log_info "Analyzing validation results..."

    # Count total validations and failures
    local total_validations=$(grep -c "," "${validation_output}" 2>/dev/null || echo "0")
    local failed_validations=$(grep -c "FAIL" "${validation_output}" 2>/dev/null || echo "0")
    local passed_validations=$((total_validations - failed_validations))

    log_info "=== VALIDATION SUMMARY ==="
    log_info "Total validations: ${total_validations}"
    log_info "Passed: ${passed_validations}"
    log_info "Failed: ${failed_validations}"

    # Show specific failures
    if [[ ${failed_validations} -gt 0 ]]; then
        log_error "=== VALIDATION FAILURES ==="
        grep "FAIL" "${validation_output}" | while IFS=',' read -r line; do
            log_error "${line}"
        done

        # Check for critical failures
        local critical_failures=$(grep -E "(NULL PRIMARY KEYS|DATA LOSS|DUPLICATES FOUND)" "${validation_output}" 2>/dev/null | wc -l)
        if [[ ${critical_failures} -gt 0 ]]; then
            log_error "CRITICAL: ${critical_failures} critical data integrity failures detected!"
            return 1
        fi

        # Check for staleness failures
        local staleness_failures=$(grep "STALE DATA" "${validation_output}" 2>/dev/null | wc -l)
        if [[ ${staleness_failures} -gt 0 ]]; then
            log_warning "WARNING: ${staleness_failures} data freshness SLA violations detected"
        fi

        return 1
    else
        log_success "All validations passed!"
        return 0
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."

    if [[ -f "${TEMP_SQL_FILE}" ]]; then
        rm -f "${TEMP_SQL_FILE}"
        log_info "Removed temporary SQL file: ${TEMP_SQL_FILE}"
    fi
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -s|--staging)
            STAGING_DATASET="$2"
            shift 2
            ;;
        -d|--prod)
            PROD_DATASET="$2"
            shift 2
            ;;
        -r|--repair)
            REPAIR_DATASET="$2"
            shift 2
            ;;
        -l|--log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
done

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "=== DiagnosticPro Post-Migration Validation Started ==="
    log_info "Project ID: ${PROJECT_ID}"
    log_info "Staging Dataset: ${STAGING_DATASET}"
    log_info "Production Dataset: ${PROD_DATASET}"
    log_info "Repair Dataset: ${REPAIR_DATASET}"
    log_info "Log Directory: ${LOG_DIR}"
    log_info "Validation Timestamp: ${VALIDATION_TIMESTAMP}"

    # Setup and checks
    create_log_directory || return $?
    check_dependencies || return $?
    verify_datasets_exist || return $?

    # Execute validation
    substitute_parameters || return $?
    execute_validation || return $?
    analyze_results || return $?

    log_success "=== Post-Migration Validation Completed Successfully ==="
    return 0
}

# Trap to ensure cleanup happens even on script interruption
trap cleanup EXIT

# Execute main function
if main "$@"; then
    log_success "Post-migration validation completed with no critical failures"
    exit 0
else
    exit_code=$?
    log_error "Post-migration validation completed with failures (exit code: ${exit_code})"
    exit ${exit_code}
fi