# Migration Rollback & Recovery Documentation

**Generated:** 2025-09-16 22:56:00
**Project:** DiagnosticPro Schema Management
**Location:** `/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD/`
**Status:** Production-Ready Rollback System

## Overview

This directory contains foolproof rollback scripts for safely recovering from failed BigQuery migration operations. The system protects 4 critical data tables containing 13,463 total records across staging and production datasets.

## Critical Data Protection

### Protected Tables
| Table | Dataset | Records | Critical Level |
|-------|---------|---------|----------------|
| `dtc_codes_github` | repair_diagnostics | 1,000 | HIGH |
| `reddit_diagnostic_posts` | repair_diagnostics | 11,462 | CRITICAL |
| `youtube_repair_videos` | repair_diagnostics | 1,000 | HIGH |
| `equipment_registry` | diagnosticpro_prod | 1 | CORE |

**Total Data at Risk:** 13,463 records
**Recovery Window:** 24 hours (snapshot retention)

## File Structure

```
NMD/
├── rollback_snapshots.sql     # Create snapshots before migration
├── rollback_restore.sql       # Restore tables from snapshots
├── README_MIGRATION.md        # This documentation
└── merge_templates.sql        # Migration templates (existing)
```

## Migration Safety Protocol

### Phase 1: Pre-Migration Snapshots (MANDATORY)

**NEVER perform migrations without snapshots.** Create snapshots first:

```bash
# 1. Set environment variables
export PROJECT_ID="diagnostic-pro-start-up"
export PROD_DATASET="diagnosticpro_prod"
export STAGING_DATASET="repair_diagnostics"
export SNAPSHOT_SUFFIX="$(date +%Y%m%d_%H%M%S)"

# 2. Create snapshots (REQUIRED before any migration)
bq query --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="prod:STRING:${PROD_DATASET}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  --parameter="snapshot_suffix:STRING:${SNAPSHOT_SUFFIX}" \
  < rollback_snapshots.sql

# 3. Record snapshot suffix for rollback
echo "SNAPSHOT_SUFFIX=${SNAPSHOT_SUFFIX}" > .rollback_vars
echo "Created snapshots at: $(date)" >> .rollback_vars
```

**Verification:** Confirm all 7 snapshots were created:
```bash
# Check staging snapshots
bq ls repair_diagnostics | grep "snapshot_${SNAPSHOT_SUFFIX}"

# Check production snapshots
bq ls diagnosticpro_prod | grep "snapshot_${SNAPSHOT_SUFFIX}"
```

### Phase 2: DRY RUN Testing (RECOMMENDED)

Always test migration scripts with `--dry_run` first:

```bash
# Test migration queries without executing
bq query --dry_run --use_legacy_sql=false "$(cat merge_templates.sql)"

# Estimate query costs
bq query --dry_run --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="prod:STRING:${PROD_DATASET}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  "SELECT COUNT(*) FROM \`${PROJECT_ID}.${STAGING_DATASET}.reddit_diagnostic_posts\`"
```

### Phase 3: Migration Execution

Only proceed after snapshots are confirmed:

```bash
# Load rollback variables
source .rollback_vars

# Execute migration (example using existing templates)
bq query --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="prod:STRING:${PROD_DATASET}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  < merge_templates.sql
```

## Emergency Rollback Procedures

### When to Rollback

Trigger immediate rollback if:
- Migration fails with data corruption errors
- Row counts don't match expected values
- Data validation queries fail
- Schema constraints are violated
- Performance degrades significantly after migration

### Immediate Rollback Steps

```bash
# 1. Load snapshot variables from pre-migration
source .rollback_vars

# 2. Verify snapshot suffix exists
if [ -z "$SNAPSHOT_SUFFIX" ]; then
  echo "ERROR: SNAPSHOT_SUFFIX not found. Check .rollback_vars file"
  exit 1
fi

# 3. Execute immediate rollback
bq query --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="prod:STRING:${PROD_DATASET}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  --parameter="snapshot_suffix:STRING:${SNAPSHOT_SUFFIX}" \
  < rollback_restore.sql

# 4. Verify restoration
echo "Verifying data restoration..."
echo "Expected: dtc_codes_github = 1000 rows"
bq query --use_legacy_sql=false "SELECT COUNT(*) as actual_count FROM \`${PROJECT_ID}.${STAGING_DATASET}.dtc_codes_github\`"

echo "Expected: reddit_diagnostic_posts = 11462 rows"
bq query --use_legacy_sql=false "SELECT COUNT(*) as actual_count FROM \`${PROJECT_ID}.${STAGING_DATASET}.reddit_diagnostic_posts\`"

echo "Expected: youtube_repair_videos = 1000 rows"
bq query --use_legacy_sql=false "SELECT COUNT(*) as actual_count FROM \`${PROJECT_ID}.${STAGING_DATASET}.youtube_repair_videos\`"

echo "Expected: equipment_registry = 1 row"
bq query --use_legacy_sql=false "SELECT COUNT(*) as actual_count FROM \`${PROJECT_ID}.${PROD_DATASET}.equipment_registry\`"
```

### Rollback Verification Checklist

- [ ] All 4 tables restored successfully
- [ ] Row counts match expected values (1000, 11462, 1000, 1)
- [ ] Table schemas intact (partitioning, clustering preserved)
- [ ] No error messages in BigQuery console
- [ ] Data samples spot-checked for integrity
- [ ] Migration can be retried after fixing issues

## Advanced Recovery Scenarios

### Partial Migration Failure

If only some tables need rollback:

```bash
# Restore individual tables by modifying the restore script
# Example: Only restore reddit_diagnostic_posts

bq query --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  --parameter="snapshot_suffix:STRING:${SNAPSHOT_SUFFIX}" \
  "CREATE OR REPLACE TABLE \`${PROJECT_ID}.${STAGING_DATASET}.reddit_diagnostic_posts\`
   CLONE \`${PROJECT_ID}.${STAGING_DATASET}.reddit_diagnostic_posts_snapshot_${SNAPSHOT_SUFFIX}\`"
```

### Cross-Dataset Migration Issues

If data was migrated between datasets incorrectly:

```bash
# Restore staging data and clear production tables
source .rollback_vars

# 1. Restore staging tables from snapshots
bq query --use_legacy_sql=false \
  --parameter="snapshot_suffix:STRING:${SNAPSHOT_SUFFIX}" \
  "CREATE OR REPLACE TABLE \`${PROJECT_ID}.repair_diagnostics.dtc_codes_github\`
   CLONE \`${PROJECT_ID}.repair_diagnostics.dtc_codes_github_snapshot_${SNAPSHOT_SUFFIX}\`"

# 2. Clear production tables if needed
bq query --use_legacy_sql=false \
  "DELETE FROM \`${PROJECT_ID}.diagnosticpro_prod.dtc_codes_github\` WHERE TRUE"
```

### Snapshot Expiration Recovery

If snapshots expire (24 hours), use data pipeline imports:

```bash
# Check for recent data in pipeline
ls -la ../datapipeline_import/imported/ | head -10

# Look for backup data files
find ../ARCHIVE_* -name "*dtc_codes*" -o -name "*reddit*" -o -name "*youtube*"
```

## Environment Configuration

### Required Environment Variables

```bash
# Primary configuration
export PROJECT_ID="diagnostic-pro-start-up"          # GCP project
export PROD_DATASET="diagnosticpro_prod"             # Production dataset
export STAGING_DATASET="repair_diagnostics"         # Staging dataset

# Optional: Custom snapshot retention
export SNAPSHOT_HOURS="24"                           # Snapshot retention hours

# Optional: Backup file locations
export BACKUP_DIR="../datapipeline_import/imported"  # Local backup location
export ARCHIVE_DIR="../ARCHIVE_OLD_SYSTEM"          # Historical archives
```

### Required Permissions

BigQuery permissions needed:
- `bigquery.tables.create` (for snapshots)
- `bigquery.tables.delete` (for CREATE OR REPLACE)
- `bigquery.tables.get` (for reading table metadata)
- `bigquery.tables.getData` (for row count verification)
- `bigquery.datasets.get` (for dataset access)

Service account configuration:
```bash
# Verify permissions
gcloud auth application-default login
bq ls ${PROJECT_ID}:${PROD_DATASET}
bq ls ${PROJECT_ID}:${STAGING_DATASET}
```

## Cost Management

### Snapshot Storage Costs

- **Data Volume:** ~13,463 records ≈ 10-50 MB storage
- **Storage Cost:** ~$0.02-0.10 per month per snapshot
- **Total Cost:** <$1/month for 24-hour retention
- **Query Cost:** Snapshot creation ~$0.01-0.05 per execution

### Cost Optimization

```bash
# Monitor snapshot costs
bq show --format=prettyjson ${PROJECT_ID}:${STAGING_DATASET}.dtc_codes_github_snapshot_${SNAPSHOT_SUFFIX}

# Check storage usage
bq query --use_legacy_sql=false \
  "SELECT
     table_name,
     ROUND(size_bytes/1024/1024, 2) as size_mb,
     row_count
   FROM \`${PROJECT_ID}.${STAGING_DATASET}.INFORMATION_SCHEMA.TABLES\`
   WHERE table_name LIKE '%snapshot%'"
```

## Safety Notes & Warnings

### ⚠️ CRITICAL WARNINGS

1. **Snapshots expire in 24 hours** - Execute rollback within this window
2. **CREATE OR REPLACE destroys existing data** - Snapshots are your only safety net
3. **Always verify snapshot_suffix parameter** - Wrong suffix = wrong restore point
4. **Test rollback in staging first** - If you have multiple environments
5. **Keep .rollback_vars file safe** - Contains your recovery snapshot identifiers

### 🛡️ SAFETY BEST PRACTICES

1. **Always create snapshots before migration**
2. **Test with --dry_run first**
3. **Verify row counts before and after**
4. **Keep multiple snapshot generations during complex migrations**
5. **Document all migration steps with timestamps**
6. **Have a communication plan for emergency rollbacks**

### 🚨 EMERGENCY CONTACTS

**Data Loss Emergency Protocol:**
1. Stop all migration operations immediately
2. Run rollback_restore.sql with last known good snapshot
3. Verify data integrity with row count checks
4. Document incident with timestamps and error messages
5. Analyze root cause before retrying migration

## Example Complete Migration

### Full End-to-End Example

```bash
#!/bin/bash
# Complete migration with rollback protection

set -e  # Exit on any error

# 1. Configuration
export PROJECT_ID="diagnostic-pro-start-up"
export PROD_DATASET="diagnosticpro_prod"
export STAGING_DATASET="repair_diagnostics"
export SNAPSHOT_SUFFIX="$(date +%Y%m%d_%H%M%S)"

echo "Starting migration at: $(date)"
echo "Snapshot suffix: ${SNAPSHOT_SUFFIX}"

# 2. Create snapshots (MANDATORY)
echo "Creating snapshots..."
bq query --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="prod:STRING:${PROD_DATASET}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  --parameter="snapshot_suffix:STRING:${SNAPSHOT_SUFFIX}" \
  < rollback_snapshots.sql

# 3. Save rollback info
echo "SNAPSHOT_SUFFIX=${SNAPSHOT_SUFFIX}" > .rollback_vars
echo "MIGRATION_START=$(date)" >> .rollback_vars

# 4. DRY RUN test
echo "Testing migration with dry run..."
bq query --dry_run --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="prod:STRING:${PROD_DATASET}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  < merge_templates.sql

# 5. Execute migration
echo "Executing migration..."
bq query --use_legacy_sql=false \
  --parameter="project:STRING:${PROJECT_ID}" \
  --parameter="prod:STRING:${PROD_DATASET}" \
  --parameter="staging:STRING:${STAGING_DATASET}" \
  < merge_templates.sql

# 6. Verify success
echo "Verifying migration..."
REDDIT_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(*) FROM \`${PROJECT_ID}.${PROD_DATASET}.reddit_diagnostic_posts\`" | tail -1)

if [ "$REDDIT_COUNT" -gt 0 ]; then
  echo "✅ Migration successful! Reddit posts in production: ${REDDIT_COUNT}"
  echo "MIGRATION_SUCCESS=$(date)" >> .rollback_vars
else
  echo "❌ Migration failed! Executing rollback..."
  bq query --use_legacy_sql=false \
    --parameter="project:STRING:${PROJECT_ID}" \
    --parameter="prod:STRING:${PROD_DATASET}" \
    --parameter="staging:STRING:${STAGING_DATASET}" \
    --parameter="snapshot_suffix:STRING:${SNAPSHOT_SUFFIX}" \
    < rollback_restore.sql
  echo "ROLLBACK_EXECUTED=$(date)" >> .rollback_vars
  exit 1
fi

echo "Migration completed at: $(date)"
```

## Conclusion

This rollback system provides enterprise-grade data protection for BigQuery migrations. The combination of automated snapshots, parameterized scripts, and comprehensive documentation ensures that data recovery is fast, reliable, and foolproof.

**Remember:** The best rollback is the one you never have to use, but when you need it, these scripts will save your data and your sanity.

---

**Generated:** 2025-09-16 22:56:00
**Last Updated:** 2025-09-16 22:56:00
**Status:** ✅ Production Ready - Rollback System Deployed