#!/usr/bin/env bash
set -euo pipefail

# Clean empty directories in NMD (except NMD itself)
echo "🧹 Cleaning empty directories in NMD..."

# Find and remove empty directories, but not NMD itself
find NMD -type d -empty -not -path "NMD" -delete 2>/dev/null || true

echo "✅ Empty directories cleaned"