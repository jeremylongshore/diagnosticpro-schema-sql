#!/bin/bash
# Setup script for S4 Validation Runner environment
# Created: 2025-09-16

set -e

echo "🔧 Setting up S4 Validation Runner Environment"
echo "=============================================="

# Check Python version
echo "📋 Checking Python version..."
python3 --version

# Check if we're in the right directory
if [[ ! -f "S4_runner.py" ]]; then
    echo "❌ S4_runner.py not found. Please run this script from the NMD directory."
    exit 1
fi

echo "✅ S4_runner.py found"

# Check if configuration files exist
echo "📋 Checking configuration files..."
config_files=("S2_quality_rules.yaml" "S2_table_contracts.yaml" "S2_sla_retention.yaml")
for file in "${config_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file found"
    else
        echo "⚠️ $file not found (will use empty config)"
    fi
done

# Check if requirements.txt exists
if [[ -f "requirements.txt" ]]; then
    echo "✅ requirements.txt found"
else
    echo "❌ requirements.txt not found"
    exit 1
fi

# Show installation instructions
echo ""
echo "🚀 Next Steps:"
echo "=============="
echo "1. Install dependencies:"
echo "   pip install -r requirements.txt"
echo ""
echo "2. Setup Google Cloud authentication:"
echo "   gcloud auth application-default login"
echo "   gcloud config set project diagnostic-pro-start-up"
echo ""
echo "3. Test the validation runner:"
echo "   python S4_runner.py --help"
echo ""
echo "4. Run basic tests:"
echo "   python test_S4_runner.py"
echo ""
echo "5. Run live validation (requires BigQuery access):"
echo "   python S4_runner.py --tables \"users\" --output json"
echo ""

# Check file permissions
echo "📋 Checking file permissions..."
if [[ -x "S4_runner.py" ]]; then
    echo "✅ S4_runner.py is executable"
else
    echo "🔧 Making S4_runner.py executable..."
    chmod +x S4_runner.py
fi

if [[ -x "test_S4_runner.py" ]]; then
    echo "✅ test_S4_runner.py is executable"
else
    echo "🔧 Making test_S4_runner.py executable..."
    chmod +x test_S4_runner.py
fi

# Validate Python syntax
echo "📋 Validating Python syntax..."
if python3 -m py_compile S4_runner.py; then
    echo "✅ S4_runner.py syntax is valid"
else
    echo "❌ S4_runner.py has syntax errors"
    exit 1
fi

if python3 -m py_compile test_S4_runner.py; then
    echo "✅ test_S4_runner.py syntax is valid"
else
    echo "❌ test_S4_runner.py has syntax errors"
    exit 1
fi

echo ""
echo "🎉 Environment setup complete!"
echo "   You can now install dependencies and run the validation runner."