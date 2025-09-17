#!/usr/bin/env bash
set -euo pipefail

# NMD Layout Enforcement - Fail CI if unknown files exist
# whitelist pattern for allowed files and directories
ALLOW_RE='^(README\.md|LICENSE|SECURITY\.md|\.gitignore|\.github(/.*)?|NMD(/(core|kits|specs|reports|archive|tools)(/.*)?)?|\.pre-commit-config\.yaml)$'

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