# BigQuery Migration Script Documentation

**File:** `migrate_staging_to_prod.sh`
**Created:** 2025-09-16
**Purpose:** Safely migrate data from staging (repair_diagnostics) to production (diagnosticpro_prod) dataset

## Overview

This script provides a comprehensive, production-ready solution for migrating BigQuery data with built-in safety measures, rollback capabilities, and detailed logging.

## Features

### 🛡️ Safety First
- **Default DRY_RUN=1** - Safe mode by default, requires explicit opt-in for execution
- **Rollback snapshots** - Automatic pre-migration snapshots for easy rollback
- **Comprehensive validation** - Authentication, dataset existence, and data integrity checks
- **Error handling** - Fails fast with clear error messages and logging

### 📊 Data Management
- **4 Missing Core Tables** - Creates sensor_telemetry, models, feature_store, maintenance_predictions if missing
- **4 Data Migration Tables** - MERGE operations for dtc_codes_github, reddit_diagnostic_posts, youtube_repair_videos, equipment_registry
- **Intelligent MERGE** - Uses appropriate unique keys for each table to prevent duplicates
- **Soft delete handling** - Respects deleted_at fields and excludes soft-deleted records

### 📝 Comprehensive Logging
- **Detailed logs** - All operations logged with timestamps and levels
- **Row count tracking** - Pre/post migration counts for all tables
- **Rollback scripts** - Auto-generated SQL for easy restoration
- **Migration history** - Persistent logs in `migration_logs/` directory

## Usage

### 1. Dry Run (Recommended First)
```bash
# Test migration without making changes
./migrate_staging_to_prod.sh
```

### 2. Execute Migration
```bash
# Run actual migration
DRY_RUN=0 ./migrate_staging_to_prod.sh
```

### 3. Custom Configuration
```bash
# Use different project/datasets
PROJECT=my-project STAGING_DS=my_staging PROD_DS=my_prod DRY_RUN=0 ./migrate_staging_to_prod.sh
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT` | `diagnostic-pro-start-up` | GCP project ID |
| `STAGING_DS` | `repair_diagnostics` | Source dataset name |
| `PROD_DS` | `diagnosticpro_prod` | Target dataset name |
| `DRY_RUN` | `1` | Safe mode (1=dry run, 0=execute) |

## Prerequisites

### Required Tools
- Google Cloud SDK (`gcloud`, `bq` commands)
- Authenticated BigQuery access (`gcloud auth login`)
- Bash 4.0+ with modern shell features

### Required Permissions
- BigQuery Data Editor on both datasets
- BigQuery Job User for running queries
- BigQuery Table Admin for creating tables

### Dataset Requirements
- Staging dataset (`repair_diagnostics`) must exist with source data
- Production dataset (`diagnosticpro_prod`) must exist
- Tables must follow expected schema structure

## Migration Process

### Phase 1: Validation
1. ✅ Check BigQuery CLI availability and authentication
2. ✅ Verify staging and production datasets exist
3. ✅ Log pre-migration row counts

### Phase 2: Safety Measures
1. 🔄 Create rollback snapshots of existing production tables
2. 📝 Generate rollback SQL script for easy restoration

### Phase 3: Core Tables
1. 🔧 Create missing core tables if they don't exist:
   - `sensor_telemetry` (IoT sensor data, partitioned by reading_date)
   - `models` (ML model registry)
   - `feature_store` (ML features, partitioned by feature_date)
   - `maintenance_predictions` (Predictive maintenance, partitioned by prediction_date)

### Phase 4: Data Migration
1. 🔄 **dtc_codes_github**: MERGE by dtc_code + source
2. 🔄 **reddit_diagnostic_posts**: MERGE by url (11,462 records expected)
3. 🔄 **youtube_repair_videos**: MERGE by video_id (1,000 records expected)
4. 🔄 **equipment_registry**: MERGE by identification_primary (1 record expected)

### Phase 5: Validation
1. ✅ Check for duplicate keys in migrated tables
2. ✅ Validate data integrity and constraints
3. 📊 Log post-migration row counts

## File Structure

```
NMD/
├── migrate_staging_to_prod.sh     # Main migration script
├── migration_logs/                # Generated logs and artifacts
│   ├── migration_YYYYMMDD_HHMMSS.log       # Detailed execution log
│   ├── rollback_YYYYMMDD_HHMMSS.sql        # Auto-generated rollback script
│   ├── row_counts_pre_YYYYMMDD_HHMMSS.csv  # Pre-migration counts
│   ├── row_counts_post_YYYYMMDD_HHMMSS.csv # Post-migration counts
│   └── merge_*.sql                         # Individual MERGE SQL files
└── MIGRATION_README.md            # This documentation
```

## Expected Data Volumes

Based on current staging data:

| Table | Staging Count | Migration Strategy |
|-------|---------------|-------------------|
| dtc_codes_github | 1,000 | MERGE by dtc_code + source |
| reddit_diagnostic_posts | 11,462 | MERGE by url |
| youtube_repair_videos | 1,000 | MERGE by video_id |
| equipment_registry | 1 | MERGE by identification_primary |

**Total Records:** ~13,463

## Rollback Procedure

If migration fails or produces unexpected results:

1. **Automatic Rollback Script:**
   ```bash
   # Find the rollback file
   ls -la migration_logs/rollback_*.sql

   # Execute rollback (replace TIMESTAMP with actual timestamp)
   bq query --use_legacy_sql=false < migration_logs/rollback_YYYYMMDD_HHMMSS.sql
   ```

2. **Manual Rollback:**
   ```bash
   # List available snapshots
   bq ls diagnosticpro_prod | grep premigration

   # Restore specific table (example)
   bq cp diagnosticpro_prod.dtc_codes_github_premigration_TIMESTAMP diagnosticpro_prod.dtc_codes_github
   ```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```bash
   gcloud auth login
   gcloud config set project diagnostic-pro-start-up
   ```

2. **Dataset Not Found**
   ```bash
   # List available datasets
   bq ls

   # Create missing dataset if needed
   bq mk --dataset diagnostic-pro-start-up:repair_diagnostics
   ```

3. **Permission Denied**
   ```bash
   # Check current permissions
   gcloud projects get-iam-policy diagnostic-pro-start-up

   # Required roles: BigQuery Data Editor, BigQuery Job User
   ```

4. **Table Schema Mismatch**
   - Check that staging tables match expected schema
   - Review merge_templates.sql for expected field names
   - Update MERGE SQL if schema has changed

### Debug Mode

For detailed debugging, check the log files:

```bash
# View latest migration log
tail -f migration_logs/migration_*.log

# Check for specific errors
grep ERROR migration_logs/migration_*.log

# Review generated SQL
cat migration_logs/merge_*.sql
```

## Best Practices

### 1. Always Test First
```bash
# Run dry run first
./migrate_staging_to_prod.sh

# Review planned actions in logs
cat migration_logs/migration_*.log
```

### 2. Monitor Resource Usage
```bash
# Check BigQuery job status
bq ls -j

# Monitor slot usage during large migrations
# (Use BigQuery Console for real-time monitoring)
```

### 3. Schedule During Low Traffic
- Run migrations during maintenance windows
- Consider time zones for global user base
- Monitor production systems during migration

### 4. Backup Verification
```bash
# Verify snapshots were created
bq ls diagnosticpro_prod | grep premigration

# Test rollback script syntax (don't execute)
bq query --dry_run --use_legacy_sql=false < migration_logs/rollback_*.sql
```

## Security Considerations

- Script logs contain no sensitive data (no credentials, PII, or secrets)
- Uses authenticated BigQuery CLI (inherits user permissions)
- Rollback scripts stored locally - secure appropriately
- All operations logged for audit trail

## Performance Optimization

The script includes several optimizations:

1. **Table Clustering** - Uses appropriate clustering keys for each table
2. **Partitioning** - Time-based partitioning for time-series data
3. **Deduplication** - ARRAY_AGG with LIMIT to handle duplicates efficiently
4. **Batch Operations** - Single MERGE per table rather than row-by-row
5. **Validation** - Targeted validation queries to minimize resource usage

## Support

For issues or questions:

1. Check this documentation
2. Review log files in `migration_logs/`
3. Examine generated SQL for specific errors
4. Verify BigQuery permissions and dataset access
5. Test with smaller datasets if issues persist

---

**Last Updated:** 2025-09-16
**Script Version:** 1.0
**Compatibility:** BigQuery Standard SQL, Bash 4.0+