#!/bin/bash

# prep_release.sh - Dry-run release gate checker
# Generated: 2025-09-17
# Purpose: Verify repository is ready for publication (DRY RUN ONLY)

set -e

echo "🔍 DiagnosticPro Schema Release Prep (DRY RUN)"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# Check function
check() {
    local name="$1"
    local cmd="$2"
    local required="${3:-true}"

    echo -n "Checking $name... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        PASS=$((PASS + 1))
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC}"
            FAIL=$((FAIL + 1))
        else
            echo -e "${YELLOW}⚠${NC}"
            WARN=$((WARN + 1))
        fi
    fi
}

echo "📁 Repository Structure"
echo "-----------------------"
check "Root README.md" "[ -f ../README.md ]"
check "Root LICENSE" "[ -f ../LICENSE ]"
check "Root .gitignore" "[ -f ../.gitignore ]"
check "NMD directory" "[ -d . ]"

echo ""
echo "📊 Phase Reports"
echo "----------------"
for phase in S0 S1 S1_UPDATED S2 S2b S3 S3_migration_kit S4 S5 S6; do
    check "report_${phase}.md" "[ -f report_${phase}.md ]"
done

echo ""
echo "📦 Core Deliverables"
echo "--------------------"
check "SUMMARY.md" "[ -f SUMMARY.md ]"
check "S2_table_contracts.yaml" "[ -f S2_table_contracts.yaml ]"
check "S2b_table_contracts_full.yaml" "[ -f S2b_table_contracts_full.yaml ]"
check "S4_runner.py" "[ -f S4_runner.py ]"
check "migrate_staging_to_prod.sh" "[ -f migrate_staging_to_prod.sh ]"

echo ""
echo "🧹 Cleanliness"
echo "--------------"
check "No *.bak files" "! ls *.bak 2>/dev/null | grep -q ."
check "No *~ files" "! ls *~ 2>/dev/null | grep -q ."
check "No .DS_Store" "! find . -name '.DS_Store' | grep -q ."
check "No __pycache__" "! find . -name '__pycache__' -type d | grep -q ."
check "No fix_test_script.py" "! [ -f fix_test_script.py ]"

echo ""
echo "🔧 Dependencies"
echo "---------------"
check "bq CLI available" "command -v bq" false
check "gcloud CLI available" "command -v gcloud" false
check "python3 available" "command -v python3"
check "jq available" "command -v jq" false

echo ""
echo "📝 Documentation"
echo "----------------"
check "Validator README" "[ -f S4_VALIDATION_RUNNER_README.md ]"
check "Migration README" "[ -f README_MIGRATION.md ]"
check "JSON schemas" "[ -d S4_jsonschema ]"
check "Pydantic models" "[ -d S4_pydantic ]"
check "SQL templates" "[ -d sql ]"

echo ""
echo "🎯 Data Samples"
echo "---------------"
check "S5 input examples" "[ -d S5_input_examples ]"
check "Golden samples" "ls S5_input_examples/*.ndjson 2>/dev/null | grep -q ."

echo ""
echo "=============================================="
echo "📊 Release Readiness Report"
echo "=============================================="
echo -e "Passed: ${GREEN}${PASS}${NC}"
echo -e "Failed: ${RED}${FAIL}${NC}"
echo -e "Warnings: ${YELLOW}${WARN}${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ READY FOR RELEASE${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review publish_checklist.md"
    echo "2. Commit all changes"
    echo "3. Tag release: git tag v1.0.0"
    echo "4. Push to GitHub: git push origin main --tags"
else
    echo -e "${RED}❌ NOT READY${NC}"
    echo ""
    echo "Fix the failed checks above before release."
fi

if [ $WARN -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Warnings:${NC}"
    echo "- 'bq' CLI not found (users need Google Cloud SDK)"
    echo "- 'gcloud' CLI not found (required for BigQuery access)"
    echo "- Document these requirements in README"
fi

echo ""
echo "📝 Note: This is a DRY RUN - no changes were made"
echo ""

exit 0