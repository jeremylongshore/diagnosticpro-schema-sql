#!/bin/bash

# S5 Cleanup Script - Remove temporary files and Python caches
# Generated: 2025-09-17
# Purpose: Clean up stray temporary files from Phase S4 and S5

set -e

echo "🧹 Phase S5 Cleanup Script"
echo "========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📂 Working directory: $SCRIPT_DIR"
echo ""

# Counter for removed items
REMOVED_COUNT=0

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    local description="$2"

    if [ -e "$path" ]; then
        echo -e "${YELLOW}Removing:${NC} $description"
        rm -rf "$path"
        ((REMOVED_COUNT++))
    fi
}

# 1. Remove Python cache directories
echo "🐍 Cleaning Python caches..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
find . -type f -name "*.pyd" -delete 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true

# 2. Remove stray test files
echo ""
echo "🧪 Removing stray test files..."
safe_remove "fix_test_script.py" "Stray test script from S4"
safe_remove "test_*.py" "Test files (if not in proper test directory)"
safe_remove "*_test.py" "Test files (alternative naming)"

# 3. Remove temporary files
echo ""
echo "📝 Removing temporary files..."
safe_remove "*.tmp" "Temporary files"
safe_remove "*.temp" "Temp files"
safe_remove "*.bak" "Backup files"
safe_remove "*~" "Editor backup files"
safe_remove ".*.swp" "Vim swap files"
safe_remove ".*.swo" "Vim swap overflow files"

# 4. Remove .DS_Store files (macOS)
echo ""
echo "🍎 Removing OS-specific files..."
find . -type f -name ".DS_Store" -delete 2>/dev/null || true
find . -type f -name "Thumbs.db" -delete 2>/dev/null || true
find . -type f -name "desktop.ini" -delete 2>/dev/null || true

# 5. Clean up any sed/awk temporary files
echo ""
echo "🔧 Removing sed/awk temporary files..."
safe_remove "sed*" "sed temporary files (if any)"
safe_remove "awk*" "awk temporary files (if any)"

# 6. Clean up log files from previous runs (optional)
echo ""
echo "📊 Checking for old log files..."
# Keep recent logs, remove those older than 7 days
find . -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true

# 7. Remove empty directories
echo ""
echo "📁 Removing empty directories..."
find . -type d -empty -delete 2>/dev/null || true

# 8. Special Phase S4 cleanup
echo ""
echo "🔍 Phase S4 specific cleanup..."
safe_remove "S4_pydantic/__pycache__" "S4 Pydantic cache"
safe_remove "S4_json_schemas/__pycache__" "S4 JSON schema cache"
safe_remove "S4_validation.db" "Temporary validation database (if exists)"
safe_remove "*.validation.tmp" "Validation temporary files"

# 9. Report findings
echo ""
echo "========================================="
if [ $REMOVED_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ Cleanup complete!${NC}"
    echo "Removed $REMOVED_COUNT item(s)"
else
    echo -e "${GREEN}✅ Already clean!${NC}"
    echo "No temporary files found to remove"
fi

# 10. Show current directory structure (first 2 levels only)
echo ""
echo "📊 Current NMD directory structure:"
echo "-----------------------------------"
tree -L 2 -I '__pycache__|*.pyc' 2>/dev/null || ls -la

# 11. Disk space saved
echo ""
echo "💾 Disk usage after cleanup:"
du -sh . 2>/dev/null || echo "Unable to calculate disk usage"

echo ""
echo "🎯 Cleanup complete! Ready for Phase S6."
echo ""

# Exit successfully
exit 0