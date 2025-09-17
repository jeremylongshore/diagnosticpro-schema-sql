#!/usr/bin/env bash
set -euo pipefail

# NMD Layout Enforcement - Fail CI if unknown files exist
# whitelist pattern for allowed files and directories
ALLOW_RE='^(README\.md|LICENSE|SECURITY\.md|\.gitignore|\.github(/.*)?|\.claude(/.*)?|\.env\.template|BIGQUERY.*\.(sql|md)|CLAUDE\.md|NMD\.md|NMD/(core|kits|specs|reports|archive|tools)(/.*)?|NMD/(ORG_SOP|README)\.md|\.pre-commit-config\.yaml|bigquery.*\.(yaml|py|sh|md|txt)|database.*\.csv|deploy.*\.(sh|txt)|diagnosticpro.*\.txt|docs(/.*)?|.*codes.*\.json|.*tables.*\.txt|.*migration.*\.(md|txt)|.*import.*\.(sh|md)|sandbox.*\.sh|.*schema.*\.json)$'

violations=0

# Check if we're in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "ERROR: Not in a git repository"
    exit 1
fi

echo "🔍 Checking NMD layout compliance..."
echo "Allowed pattern: $ALLOW_RE"
echo ""

# Check all tracked files
while IFS= read -r -d '' file; do
    if [[ ! "$file" =~ $ALLOW_RE ]]; then
        echo "[VIOLATION] $file"
        violations=1
    fi
done < <(git ls-files -z)

if [ $violations -eq 1 ]; then
    echo ""
    echo "❌ Layout violations found!"
    echo "Files must be in: core/ | kits/ | specs/ | reports/ | archive/ | tools/"
    echo "Or be: README.md | LICENSE | SECURITY.md | .gitignore | .github/ | .pre-commit-config.yaml"
    exit 1
else
    echo "✅ All files comply with NMD layout"
    exit 0
fi