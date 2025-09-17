# S4 Validation Makefile Snippets

**Created:** 2025-09-16
**Purpose:** Make targets for local data quality validation

## Overview

These Makefile snippets provide standardized targets for running data quality validation locally using the S4 validation framework.

## Make Targets

Add these targets to your project's `Makefile`:

```makefile
# =============================================================================
# Data Quality Validation Targets
# =============================================================================

# Configuration variables
PROJECT_ID ?= diagnostic-pro-start-up
DATASET ?= diagnosticpro_prod
VALIDATION_LEVEL ?= standard
NMD_DIR := NMD
S4_RUNNER := $(NMD_DIR)/S4_runner.py

# Environment check
.PHONY: check-env
check-env:
	@echo "🔍 Checking validation environment..."
	@command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found"; exit 1; }
	@python3 -c "import google.cloud.bigquery" 2>/dev/null || { echo "❌ google-cloud-bigquery not installed"; exit 1; }
	@python3 -c "import jsonschema" 2>/dev/null || { echo "❌ jsonschema not installed"; exit 1; }
	@test -f "$(S4_RUNNER)" || { echo "❌ S4_runner.py not found at $(S4_RUNNER)"; exit 1; }
	@echo "✅ Environment check passed"

# Install validation dependencies
.PHONY: install-validation-deps
install-validation-deps:
	@echo "📦 Installing validation dependencies..."
	@if [ -f "$(NMD_DIR)/requirements.txt" ]; then \
		pip install -r $(NMD_DIR)/requirements.txt; \
	else \
		pip install google-cloud-bigquery>=3.11.0 jsonschema>=4.19.0 PyYAML>=6.0 tqdm>=4.65.0; \
	fi
	@echo "✅ Dependencies installed"

# =============================================================================
# Core Validation Targets
# =============================================================================

# JSON Schema validation
.PHONY: validate-json
validate-json: check-env
	@echo "🔍 Running JSON Schema validation..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode schema \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--validation-level $(VALIDATION_LEVEL) \
		--verbose

# SQL constraint validation
.PHONY: validate-sql
validate-sql: check-env
	@echo "🔍 Running SQL constraint validation..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode constraints \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--validation-level $(VALIDATION_LEVEL) \
		--verbose

# Data freshness validation
.PHONY: validate-freshness
validate-freshness: check-env
	@echo "🔍 Running data freshness validation..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode freshness \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--validation-level $(VALIDATION_LEVEL) \
		--allow-soft-failures \
		--verbose

# Combined validation (all checks)
.PHONY: validate-all
validate-all: check-env validate-json validate-sql validate-freshness
	@echo "📊 Generating combined validation summary..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode summary \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--output-format console
	@echo "✅ All validations completed"

# =============================================================================
# Quick Validation Targets
# =============================================================================

# Quick validation (reduced scope for development)
.PHONY: validate-quick
validate-quick: check-env
	@echo "⚡ Running quick validation..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode schema \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--validation-level quick \
		--verbose

# Pre-commit validation hook
.PHONY: validate-pre-commit
validate-pre-commit: validate-quick
	@echo "✅ Pre-commit validation passed"

# =============================================================================
# CI/CD Integration Targets
# =============================================================================

# CI validation (GitHub Actions compatible)
.PHONY: validate-ci
validate-ci: check-env
	@echo "🤖 Running CI validation..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode schema \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--validation-level $(VALIDATION_LEVEL) \
		--output-format github \
		--verbose
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode constraints \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--validation-level $(VALIDATION_LEVEL) \
		--output-format github \
		--verbose

# =============================================================================
# Advanced Validation Targets
# =============================================================================

# Comprehensive validation (all checks, full scope)
.PHONY: validate-comprehensive
validate-comprehensive: check-env
	@echo "🔍 Running comprehensive validation..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode all \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--validation-level comprehensive \
		--verbose

# Validation with custom configuration
.PHONY: validate-custom
validate-custom: check-env
	@test -n "$(CONFIG)" || { echo "❌ CONFIG variable required"; exit 1; }
	@echo "🔧 Running validation with custom config: $(CONFIG)"
	cd $(NMD_DIR) && python3 S4_runner.py \
		--config $(CONFIG) \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--verbose

# =============================================================================
# Validation Reporting Targets
# =============================================================================

# Generate validation report
.PHONY: validate-report
validate-report: check-env
	@echo "📊 Generating validation report..."
	cd $(NMD_DIR) && python3 S4_runner.py \
		--mode summary \
		--project-id $(PROJECT_ID) \
		--dataset $(DATASET) \
		--output-format html \
		--verbose
	@echo "📄 Report generated: $(NMD_DIR)/validation_report.html"

# Clean validation artifacts
.PHONY: clean-validation
clean-validation:
	@echo "🧹 Cleaning validation artifacts..."
	@rm -f $(NMD_DIR)/validation_*.json
	@rm -f $(NMD_DIR)/validation_*.html
	@rm -f $(NMD_DIR)/*_report_*.md
	@rm -rf $(NMD_DIR)/__pycache__
	@echo "✅ Validation artifacts cleaned"

# =============================================================================
# Help Target
# =============================================================================

.PHONY: validate-help
validate-help:
	@echo "📚 Available validation targets:"
	@echo ""
	@echo "Core Validation:"
	@echo "  validate-json        - JSON Schema validation"
	@echo "  validate-sql         - SQL constraint validation"
	@echo "  validate-freshness   - Data freshness validation"
	@echo "  validate-all         - All validations"
	@echo ""
	@echo "Quick Validation:"
	@echo "  validate-quick       - Quick development validation"
	@echo "  validate-pre-commit  - Pre-commit hook validation"
	@echo ""
	@echo "CI/CD Integration:"
	@echo "  validate-ci          - CI-friendly validation"
	@echo ""
	@echo "Advanced:"
	@echo "  validate-comprehensive - Full comprehensive validation"
	@echo "  validate-custom      - Custom config validation (requires CONFIG=...)"
	@echo ""
	@echo "Reporting:"
	@echo "  validate-report      - Generate HTML validation report"
	@echo ""
	@echo "Utilities:"
	@echo "  check-env           - Check validation environment"
	@echo "  install-validation-deps - Install required dependencies"
	@echo "  clean-validation    - Clean validation artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  PROJECT_ID=$(PROJECT_ID)"
	@echo "  DATASET=$(DATASET)"
	@echo "  VALIDATION_LEVEL=$(VALIDATION_LEVEL)"
```

## Usage Examples

```bash
# Basic validation
make validate-all

# Quick development check
make validate-quick

# Specific dataset validation
make validate-json DATASET=diagnosticpro_staging

# Custom project validation
make validate-sql PROJECT_ID=my-project DATASET=my_dataset

# Comprehensive validation with report
make validate-comprehensive
make validate-report

# CI/CD pipeline validation
make validate-ci VALIDATION_LEVEL=standard

# Clean up after validation
make clean-validation
```

## Environment Variables

The Makefile supports these environment variables:

- `PROJECT_ID`: Google Cloud project ID (default: `diagnostic-pro-start-up`)
- `DATASET`: BigQuery dataset name (default: `diagnosticpro_prod`)
- `VALIDATION_LEVEL`: Validation scope (`quick`, `standard`, `comprehensive`)
- `CONFIG`: Path to custom validation configuration file

## Exit Codes

The validation targets follow standard exit codes:

- `0`: Success - All validations passed
- `1`: Hard failure - Schema or constraint violations
- `2`: Soft failure - Freshness or SLA violations (warnings)

## Integration with CI/CD

These targets are designed to integrate seamlessly with:

- **GitHub Actions**: Use `validate-ci` target
- **GitLab CI**: Use `validate-all` or `validate-ci`
- **Jenkins**: Use `validate-comprehensive` for release validation
- **Pre-commit hooks**: Use `validate-pre-commit`

---

**Last Updated:** 2025-09-16
**Dependencies:** S4_runner.py, BigQuery access, Python 3.11+