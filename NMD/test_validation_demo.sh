#!/bin/bash

# test_validation_demo.sh
# Demo script to show validation functionality without requiring BigQuery access
# Version: 1.0.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_LOG_DIR="${SCRIPT_DIR}/demo_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== DiagnosticPro Post-Migration Validation Demo ===${NC}"
echo -e "${BLUE}Timestamp: ${TIMESTAMP}${NC}"
echo

# Create demo log directory
mkdir -p "${DEMO_LOG_DIR}"

# Simulate validation results
echo -e "${GREEN}Creating sample validation results...${NC}"

cat > "${DEMO_LOG_DIR}/validation_results_${TIMESTAMP}.csv" << 'EOF'
validation_type,table_name,staging_count,prod_count,count_diff,validation_status,max_staging_timestamp,max_prod_timestamp,timestamp_diff_minutes,validation_timestamp
ROW_COUNT_VALIDATION,dtc_codes_github,1000,1000,0,PASS,2025-09-16 10:30:00,2025-09-16 10:30:00,0,2025-09-16 22:56:00
ROW_COUNT_VALIDATION,reddit_diagnostic_posts,11462,11462,0,PASS,2025-09-16 09:15:00,2025-09-16 09:15:00,0,2025-09-16 22:56:00
ROW_COUNT_VALIDATION,youtube_repair_videos,1000,1000,0,PASS,2025-09-16 08:45:00,2025-09-16 08:45:00,0,2025-09-16 22:56:00
ROW_COUNT_VALIDATION,equipment_registry,1,1,0,PASS,2025-09-16 07:00:00,2025-09-16 07:00:00,0,2025-09-16 22:56:00
ROW_COUNT_VALIDATION,users,0,0,0,PASS,NULL,NULL,NULL,2025-09-16 22:56:00
ROW_COUNT_VALIDATION,diagnostic_sessions,0,0,0,PASS,NULL,NULL,NULL,2025-09-16 22:56:00
PRIMARY_KEY_VALIDATION,dtc_codes_github,id,1000,1000,0,PASS,2025-09-16 22:56:00
PRIMARY_KEY_VALIDATION,reddit_diagnostic_posts,id,11462,11462,0,PASS,2025-09-16 22:56:00
PRIMARY_KEY_VALIDATION,youtube_repair_videos,id,1000,1000,0,PASS,2025-09-16 22:56:00
PRIMARY_KEY_VALIDATION,equipment_registry,identification_number,1,1,0,PASS,2025-09-16 22:56:00
PRIMARY_KEY_VALIDATION,users,id,0,0,0,PASS,2025-09-16 22:56:00
PRIMARY_KEY_VALIDATION,diagnostic_sessions,id,0,0,0,PASS,2025-09-16 22:56:00
FRESHNESS_VALIDATION,dtc_codes_github,daily,48,2025-09-16 10:30:00,12,PASS,1000,2025-09-16 22:56:00
FRESHNESS_VALIDATION,reddit_diagnostic_posts,hourly,6,2025-09-16 09:15:00,13,FAIL - STALE DATA,11462,2025-09-16 22:56:00
FRESHNESS_VALIDATION,youtube_repair_videos,daily,24,2025-09-16 08:45:00,14,PASS,1000,2025-09-16 22:56:00
FRESHNESS_VALIDATION,equipment_registry,on_demand,168,2025-09-16 07:00:00,15,PASS,1,2025-09-16 22:56:00
QUALITY_VALIDATION,dtc_codes_github,null_primary_keys,1000,0,PASS,0.0,2025-09-16 22:56:00
QUALITY_VALIDATION,dtc_codes_github,dtc_format_validation,1000,0,PASS,0.0,2025-09-16 22:56:00
QUALITY_VALIDATION,reddit_diagnostic_posts,null_primary_keys,11462,0,PASS,0.0,2025-09-16 22:56:00
QUALITY_VALIDATION,reddit_diagnostic_posts,reddit_url_validation,11462,2,FAIL - INVALID REDDIT URL FORMAT,0.017,2025-09-16 22:56:00
QUALITY_VALIDATION,youtube_repair_videos,null_primary_keys,1000,0,PASS,0.0,2025-09-16 22:56:00
QUALITY_VALIDATION,youtube_repair_videos,youtube_video_id_validation,1000,0,PASS,0.0,2025-09-16 22:56:00
QUALITY_VALIDATION,equipment_registry,vin_format_validation,1,0,PASS,0.0,2025-09-16 22:56:00
QUALITY_VALIDATION,dtc_codes_github,future_timestamp_check,1000,0,PASS,0.0,2025-09-16 22:56:00
EOF

echo -e "${GREEN}Sample results created: ${DEMO_LOG_DIR}/validation_results_${TIMESTAMP}.csv${NC}"
echo

# Analyze the demo results
echo -e "${BLUE}=== ANALYZING VALIDATION RESULTS ===${NC}"

results_file="${DEMO_LOG_DIR}/validation_results_${TIMESTAMP}.csv"
total_validations=$(grep -c "," "${results_file}")
failed_validations=$(grep -c "FAIL" "${results_file}")
passed_validations=$((total_validations - failed_validations))

echo -e "${BLUE}Total validations: ${total_validations}${NC}"
echo -e "${GREEN}Passed: ${passed_validations}${NC}"
echo -e "${RED}Failed: ${failed_validations}${NC}"
echo

if [[ ${failed_validations} -gt 0 ]]; then
    echo -e "${RED}=== VALIDATION FAILURES ===${NC}"
    grep "FAIL" "${results_file}" | while IFS=',' read -r line; do
        echo -e "${RED}${line}${NC}"
    done
    echo

    # Check for critical failures
    critical_failures=$(grep -E "(NULL PRIMARY KEYS|DATA LOSS|DUPLICATES FOUND)" "${results_file}" | wc -l)
    if [[ ${critical_failures} -gt 0 ]]; then
        echo -e "${RED}CRITICAL: ${critical_failures} critical data integrity failures detected!${NC}"
    fi

    # Check for staleness failures
    staleness_failures=$(grep "STALE DATA" "${results_file}" | wc -l)
    if [[ ${staleness_failures} -gt 0 ]]; then
        echo -e "${YELLOW}WARNING: ${staleness_failures} data freshness SLA violations detected${NC}"
    fi
else
    echo -e "${GREEN}All validations passed!${NC}"
fi

echo
echo -e "${BLUE}=== DEMO COMPLETE ===${NC}"
echo -e "${BLUE}In a real scenario, this would:${NC}"
echo -e "${BLUE}1. Connect to BigQuery with actual credentials${NC}"
echo -e "${BLUE}2. Execute validation queries against real data${NC}"
echo -e "${BLUE}3. Return appropriate exit codes for CI/CD integration${NC}"
echo -e "${BLUE}4. Generate detailed logs for troubleshooting${NC}"

# Clean up demo files
echo
read -p "Clean up demo files? (y/N): " cleanup_choice
if [[ "${cleanup_choice}" =~ ^[Yy]$ ]]; then
    rm -rf "${DEMO_LOG_DIR}"
    echo -e "${GREEN}Demo files cleaned up${NC}"
fi