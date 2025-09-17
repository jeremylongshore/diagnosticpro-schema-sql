# S4 Validation Runner - Comprehensive BigQuery Validation System

**Created:** 2025-09-16
**Version:** 1.0.0
**Author:** DiagnosticPro Data Engineering Team

## Overview

The S4 Validation Runner (`S4_runner.py`) is a production-ready, comprehensive validation system for BigQuery schemas and data quality. It integrates multiple validation types into a single CLI tool with robust error handling, progress tracking, and flexible output formats.

## Features

### 🔍 Multi-Layer Validation
- **Schema Compliance**: Validates table schemas against defined contracts
- **Data Constraints**: Enforces business rules and data quality standards
- **SLA Freshness**: Checks data recency against defined SLA requirements
- **SQL Constraint Checks**: Validates data integrity with actual SQL queries

### 🛠️ Production-Ready Features
- **CLI Interface**: Full argparse-based command line interface
- **Exit Codes**: Standardized exit codes for CI/CD integration
- **Progress Bars**: Visual progress tracking with tqdm
- **Multiple Output Formats**: Human-readable text and machine-parseable JSON
- **Error Handling**: Comprehensive exception handling and logging
- **Pattern Matching**: Flexible table selection with glob patterns

### 📊 Integration Points
- **Configuration Files**: Integrates with S2 YAML configuration files
- **BigQuery Client**: Native Google Cloud BigQuery integration
- **Logging**: Structured logging with configurable verbosity
- **CI/CD Ready**: Designed for continuous integration workflows

## Installation

### Prerequisites
```bash
# Install Python dependencies
pip install -r requirements.txt

# Ensure Google Cloud authentication
gcloud auth application-default login
```

### Dependencies
- **google-cloud-bigquery** (>=3.11.0): BigQuery client library
- **jsonschema** (>=4.19.0): JSON schema validation
- **PyYAML** (>=6.0): YAML configuration parsing
- **tqdm** (>=4.65.0): Progress bars and CLI enhancement

## Usage

### Basic Usage
```bash
# Validate all tables in default project/dataset
python S4_runner.py

# Validate specific tables
python S4_runner.py --tables "users,equipment_registry"

# Validate with pattern matching
python S4_runner.py --tables "user*"

# JSON output for CI/CD
python S4_runner.py --output json --tables "*"
```

### Advanced Usage
```bash
# Custom project and dataset
python S4_runner.py \
  --project my-project \
  --dataset my_dataset \
  --tables "*"

# Fail on warnings (strict mode)
python S4_runner.py \
  --fail-on warn \
  --tables "critical_*"

# Verbose logging for debugging
python S4_runner.py --verbose --tables "problematic_table"
```

## Command Line Interface

### Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--project` | `diagnostic-pro-start-up` | GCP project ID |
| `--dataset` | `diagnosticpro_prod` | BigQuery dataset name |
| `--tables` | `*` | Table pattern (glob) or comma-separated list |
| `--fail-on` | `error` | Failure threshold: `warn` or `error` |
| `--output` | `text` | Output format: `text` or `json` |
| `--verbose` | `false` | Enable verbose logging |

### Table Pattern Examples
```bash
# All tables
--tables "*"

# Specific tables
--tables "users,equipment_registry,dtc_codes_github"

# Pattern matching
--tables "user*"          # All tables starting with "user"
--tables "*_diagnostic"   # All tables ending with "_diagnostic"
--tables "reddit_*,youtube_*"  # Multiple patterns
```

## Exit Codes

The validation runner uses standardized exit codes for CI/CD integration:

- **0**: Success - All validations passed
- **1**: Hard Failure - Schema/constraint violations found
- **2**: Soft Failure - SLA/freshness issues found (only when `--fail-on warn`)

### CI/CD Integration Example
```bash
#!/bin/bash
# CI validation pipeline

# Run validation with strict failure mode
python S4_runner.py --fail-on warn --output json > validation_results.json

case $? in
  0)
    echo "✅ All validations passed"
    ;;
  1)
    echo "❌ Hard failures found - blocking deployment"
    exit 1
    ;;
  2)
    echo "⚠️ SLA warnings found - proceeding with caution"
    # Could send notifications here
    ;;
esac
```

## Validation Types

### 1. Schema Compliance Validation

Validates table schemas against contracts defined in `S2_table_contracts.yaml`:

```yaml
tables:
  users:
    schema:
      required_fields:
        - id
        - email
        - created_at
      fields:
        id:
          type: STRING
        email:
          type: STRING
```

**Checks:**
- Required fields presence
- Field type consistency
- Schema contract compliance

### 2. Data Constraints Validation

Enforces business rules from `S2_quality_rules.yaml`:

```yaml
global_rules:
  patterns:
    email_format: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    uuid_v4: '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$'
  timestamps:
    created_at:
      not_null: true
      not_future: true
```

**Checks:**
- Pattern validation (email, UUID, DTC codes)
- Timestamp constraints
- Null value validation
- Business rule enforcement

### 3. SLA Freshness Validation

Monitors data freshness against `S2_sla_retention.yaml`:

```yaml
freshness_slas:
  live_data_tables:
    reddit_diagnostic_posts:
      expected_cadence: "hourly"
      max_staleness: "6h"
      late_arrival_threshold: "3h"
```

**Checks:**
- Data staleness monitoring
- SLA compliance verification
- Late arrival detection
- Freshness trend analysis

## Output Formats

### Text Output (Default)
```
================================================================================
🔍 VALIDATION RESULTS - 2025-09-16T10:30:00.000000
================================================================================
📊 Project: diagnostic-pro-start-up
📦 Dataset: diagnosticpro_prod

📈 SUMMARY:
   Total Checks: 12
   ✅ Passed: 10
   ❌ Failed: 1
   ⚠️ Warnings: 3
   🚫 Errors: 1
   📊 Success Rate: 83.3%

📋 BY CATEGORY:
   ✅ Schema Compliance:
      Passed: 4, Failed: 0, Warnings: 0
   ❌ Data Constraints:
      Passed: 3, Failed: 1, Warnings: 1
   ✅ Freshness Sla:
      Passed: 3, Failed: 0, Warnings: 2

❌ FAILURES (1):
   🔴 users (data_constraints):
      • Found 5 rows with NULL created_at

⚠️ WARNINGS (3):
   🟡 reddit_diagnostic_posts (freshness_sla):
      • Data is stale: 8.2h > 6h threshold

⏱️ Total Validation Time: 12.45s
================================================================================
```

### JSON Output
```json
{
  "timestamp": "2025-09-16T10:30:00.000000",
  "project_id": "diagnostic-pro-start-up",
  "dataset_id": "diagnosticpro_prod",
  "summary": {
    "total_checks": 12,
    "passed_checks": 10,
    "failed_checks": 1,
    "total_warnings": 3,
    "total_errors": 1,
    "success_rate": "83.3%"
  },
  "by_category": {
    "schema_compliance": {
      "passed": 4,
      "failed": 0,
      "warnings": 0
    },
    "data_constraints": {
      "passed": 3,
      "failed": 1,
      "warnings": 1
    },
    "freshness_sla": {
      "passed": 3,
      "failed": 0,
      "warnings": 2
    }
  },
  "results": [
    {
      "name": "users",
      "category": "schema_compliance",
      "passed": true,
      "errors": [],
      "warnings": [],
      "details": {
        "table_schema": {
          "field_count": 15,
          "required_fields_checked": 5,
          "contract_fields_checked": 8
        }
      },
      "duration": 0.234
    }
  ]
}
```

## Configuration Files

The validation runner integrates with three key configuration files:

### S2_quality_rules.yaml
- Global and table-specific quality rules
- Pattern validation definitions
- Business rule specifications
- Data type constraints

### S2_table_contracts.yaml
- Table schema contracts
- Required field definitions
- Load and merge strategies
- Validation rule mappings

### S2_sla_retention.yaml
- Data freshness SLA definitions
- Retention policies
- Staleness thresholds
- Monitoring configurations

## Testing

### Run Tests
```bash
# Basic functionality tests
python test_S4_runner.py

# Include live BigQuery tests (requires authentication)
python test_S4_runner.py --live
```

### Test Categories
1. **Basic Functionality**: Help, argument parsing, basic execution
2. **JSON Output**: Valid JSON structure and required fields
3. **Pattern Matching**: Table selection and glob patterns
4. **Failure Thresholds**: Exit code behavior with different failure modes
5. **Live Validation**: Real BigQuery integration tests

## Performance Characteristics

### Scalability
- **Small datasets** (1-10 tables): < 30 seconds
- **Medium datasets** (10-50 tables): 1-5 minutes
- **Large datasets** (50+ tables): 5-15 minutes

### Resource Usage
- **Memory**: ~50MB base + ~10MB per table
- **Network**: Minimal (schema queries only)
- **CPU**: Low (mostly I/O bound)

## Error Handling

### Connection Errors
```python
# Graceful handling of BigQuery connectivity issues
try:
    self.client = bigquery.Client(project=project_id)
except Exception as e:
    logging.error(f"Failed to initialize BigQuery client: {e}")
    raise
```

### Validation Errors
```python
# Structured error reporting
result.add_error(f"Required field '{field_name}' missing from schema")
result.add_warning(f"Data is stale: {staleness_hours:.1f}h > {threshold}h")
```

### Exception Recovery
- Non-blocking table validation (one failure doesn't stop others)
- Graceful degradation when configuration files are missing
- Timeout handling for long-running queries
- Comprehensive logging for debugging

## Monitoring and Observability

### Logging Levels
- **INFO**: High-level progress and results
- **DEBUG**: Detailed execution information
- **ERROR**: Failures and exceptions
- **WARNING**: SLA violations and configuration issues

### Metrics Collection
```python
result.details['timestamp_validation'] = {
    'total_rows_checked': row.total_rows,
    'null_created_at': row.null_created_at,
    'future_created_at': row.future_created_at,
    'invalid_updated_at': row.invalid_updated_at
}
```

## Extension Points

### Custom Validation Rules
Add new validation types by extending the `ValidationRunner` class:

```python
def validate_custom_rule(self, table_name: str) -> ValidationResult:
    """Custom validation implementation"""
    result = ValidationResult(table_name, "custom_validation")
    # Implementation here
    return result
```

### Additional Output Formats
Extend the `print_results` method for new output formats:

```python
elif self.output_format == 'xml':
    print(self._generate_xml_output(summary))
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```bash
   gcloud auth application-default login
   gcloud config set project diagnostic-pro-start-up
   ```

2. **Missing Configuration Files**
   - Ensure S2_*.yaml files exist in the NMD directory
   - Check file permissions and YAML syntax

3. **Table Not Found Errors**
   - Verify dataset name and project ID
   - Check table name patterns and case sensitivity

4. **Timeout Issues**
   - Reduce table pattern scope
   - Check BigQuery quota limits
   - Verify network connectivity

### Debug Mode
```bash
python S4_runner.py --verbose --tables "problematic_table"
```

## Best Practices

### CI/CD Integration
1. Run validation on staging data before production
2. Use `--fail-on warn` for strict quality gates
3. Store JSON results as build artifacts
4. Set up notifications for SLA violations

### Performance Optimization
1. Use specific table patterns instead of "*" when possible
2. Run validation during off-peak hours for large datasets
3. Consider parallel execution for independent table validations
4. Cache configuration files to reduce I/O

### Configuration Management
1. Version control all YAML configuration files
2. Review and update SLA thresholds regularly
3. Document business rule changes in configuration
4. Test configuration changes in staging first

---

**Last Updated:** 2025-09-16
**Next Review:** 2025-12-16
**Status:** ✅ Production Ready