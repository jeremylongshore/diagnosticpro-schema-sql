# Post-Migration Validation Scripts

**Created:** 2025-09-16
**Version:** 1.0.0
**Purpose:** Comprehensive validation of data integrity, quality, and freshness after BigQuery migration

## Overview

This validation suite provides comprehensive post-migration verification for the DiagnosticPro BigQuery platform. It validates data integrity, primary key uniqueness, freshness based on SLAs, and data quality assertions.

## Files

### 1. `validate_post_migration.sql`
- **Purpose:** Comprehensive SQL validation queries
- **Contains:**
  - Row count comparisons between staging and production
  - Primary key uniqueness checks
  - Data freshness validation based on SLA requirements
  - Data quality assertions (format validation, null checks)
  - Validation summary

### 2. `validate_post_migration.sh`
- **Purpose:** Bash execution script with parameter substitution
- **Features:**
  - Parameter substitution for project, datasets, timestamps
  - Comprehensive logging to `migration_logs/`
  - Error handling and dependency checking
  - Result analysis and reporting
  - Configurable via command line or environment variables

### 3. `test_validation_demo.sh`
- **Purpose:** Demo script showing validation functionality
- **Use:** Testing and demonstrating validation logic without BigQuery access

## Usage

### Basic Execution
```bash
# Run with default parameters
./validate_post_migration.sh

# Run with custom parameters
./validate_post_migration.sh \
  --project my-project \
  --staging my_staging \
  --prod my_prod
```

### Environment Variables
```bash
export PROJECT_ID="diagnostic-pro-start-up"
export STAGING_DATASET="diagnosticpro_staging"
export PROD_DATASET="diagnosticpro_prod"
export REPAIR_DATASET="repair_diagnostics"

./validate_post_migration.sh
```

### Command Line Options
```bash
./validate_post_migration.sh [OPTIONS]

OPTIONS:
    -p, --project PROJECT_ID        GCP project ID
    -s, --staging STAGING_DATASET   Staging dataset name
    -d, --prod PROD_DATASET         Production dataset name
    -r, --repair REPAIR_DATASET     Repair dataset name
    -l, --log-dir LOG_DIR           Log directory
    -h, --help                      Show help message
```

## Validation Types

### 1. Row Count Validation
- **Purpose:** Ensure no data loss during migration
- **Logic:** Staging count >= Production count
- **Failure:** `FAIL - DATA LOSS` if staging < production

### 2. Primary Key Uniqueness
- **Purpose:** Verify data integrity
- **Checks:** No duplicate primary keys in production tables
- **Tables:** All core tables (dtc_codes_github, reddit_diagnostic_posts, etc.)

### 3. Data Freshness (SLA-based)
- **dtc_codes_github:** Max staleness 48h (daily cadence)
- **reddit_diagnostic_posts:** Max staleness 6h (hourly cadence)
- **youtube_repair_videos:** Max staleness 24h (daily cadence)
- **equipment_registry:** Max staleness 7d (on_demand cadence)

### 4. Data Quality Assertions
- **Format Validation:**
  - DTC codes: `^[PBCU]\d{4}$`
  - YouTube video IDs: `^[a-zA-Z0-9_-]{11}$`
  - Reddit URLs: `^https?://(?:www\.)?reddit\.com/r/.+`
  - VIN numbers: `^[A-HJ-NPR-Z0-9]{17}$` (for vehicles)
- **Integrity Checks:**
  - No null primary keys
  - No future timestamps
  - Required field validation

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All validations passed |
| 1 | Validation failures detected |
| 2 | Script execution error |
| 3 | Missing dependencies |

## Output Files

### Log Files
- **Location:** `migration_logs/`
- **Format:** `validate_YYYYMMDD_HHMMSS.txt`
- **Contains:** Execution log with timestamps, errors, warnings

### Results Files
- **Location:** `migration_logs/`
- **Format:** `validation_results_YYYYMMDD_HHMMSS.csv`
- **Contains:** Detailed validation results in CSV format

### Error Files
- **Location:** `migration_logs/`
- **Format:** `validation_errors_YYYYMMDD_HHMMSS.txt`
- **Contains:** BigQuery execution errors (if any)

## Dependencies

### Required
- Google Cloud SDK (`gcloud`, `bq` commands)
- Authenticated GCP session
- Read access to BigQuery datasets
- Bash 4.0+

### Optional
- Write access to log directory (defaults to `../migration_logs/`)

## Example Output

### Successful Validation
```
2025-09-16 23:06:53 - INFO: === DiagnosticPro Post-Migration Validation Started ===
2025-09-16 23:06:53 - INFO: Project ID: diagnostic-pro-start-up
2025-09-16 23:06:53 - INFO: Validation Timestamp: 20250916_230653
2025-09-16 23:06:53 - INFO: Checking dependencies...
2025-09-16 23:06:53 - SUCCESS: All dependencies satisfied
2025-09-16 23:06:53 - SUCCESS: All validations passed!
2025-09-16 23:06:53 - SUCCESS: === Post-Migration Validation Completed Successfully ===
```

### Validation Failures
```
2025-09-16 23:06:53 - ERROR: === VALIDATION FAILURES ===
2025-09-16 23:06:53 - ERROR: FRESHNESS_VALIDATION,reddit_diagnostic_posts,FAIL - STALE DATA
2025-09-16 23:06:53 - ERROR: QUALITY_VALIDATION,reddit_diagnostic_posts,FAIL - INVALID REDDIT URL FORMAT
2025-09-16 23:06:53 - WARNING: WARNING: 1 data freshness SLA violations detected
```

## Integration with CI/CD

### GitLab CI
```yaml
validate_migration:
  stage: validate
  script:
    - ./NMD/validate_post_migration.sh
  artifacts:
    when: always
    paths:
      - migration_logs/
    expire_in: 30 days
  only:
    - migration-branches
```

### GitHub Actions
```yaml
- name: Validate Migration
  run: |
    cd NMD
    ./validate_post_migration.sh
  env:
    PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
    STAGING_DATASET: diagnosticpro_staging
    PROD_DATASET: diagnosticpro_prod
```

## Troubleshooting

### Common Issues

#### Authentication Errors
```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login
gcloud config set project diagnostic-pro-start-up
```

#### Missing Dependencies
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

#### Permission Errors
- Ensure BigQuery Data Viewer role for datasets
- Verify project access permissions
- Check dataset existence with `bq ls`

### Debug Mode
```bash
# Enable debug output
set -x
./validate_post_migration.sh
```

## Customization

### Adding New Validations
1. Add SQL validation logic to `validate_post_migration.sql`
2. Follow the existing pattern with CTEs and UNION ALL
3. Ensure proper parameter substitution placeholders
4. Test with demo script first

### Modifying SLA Requirements
1. Update freshness validation thresholds in SQL file
2. Modify comments to reflect new SLA requirements
3. Update this README with new requirements

## Support

For issues or questions:
1. Check the log files in `migration_logs/`
2. Review BigQuery permissions and dataset access
3. Verify parameter substitution in temporary SQL files
4. Run demo script to test validation logic

---

**Files created:**
- `/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD/validate_post_migration.sql`
- `/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD/validate_post_migration.sh`
- `/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD/test_validation_demo.sh`
- `/home/jeremy/projects/diagnostic-platform/diag-schema-sql/migration_logs/` (directory)

**Last Updated:** 2025-09-16