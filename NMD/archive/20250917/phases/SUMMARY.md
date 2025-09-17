# NMD Schema Audit Summary

## Phase Reports
- [S0 - Setup](report_S0.md)
- [S1 - Catalog](report_S1_UPDATED.md)
- [S2 - Contracts](report_S2.md)
- [S2b - Full Coverage](report_S2b.md)
- [S3 - Lineage](report_S3.md)
- [S3.1 - Migration Kit](report_S3_migration_kit.md)
- [S4 - Validators](report_S4.md)
- [S5 - Scraper Contracts](report_S5.md)
- [S6 - Consolidation](report_S6.md)

## Key Artifacts

### Contracts & SLAs
- [Table Contracts (Core)](S2_table_contracts.yaml)
- [Table Contracts (Full)](S2b_table_contracts_full.yaml)
- [SLA & Retention](S2_sla_retention.yaml)
- [Quality Rules](S2_quality_rules.yaml)

### Catalog & Schema
- [Full Catalog](S1_catalog.md)
- [Columns CSV](S1_columns.csv)
- [Keys & Constraints](S1_keys.yaml)
- [Row Counts (Live)](S1_row_counts_LIVE.csv)

### Migration Kit
- [Migration Script](migrate_staging_to_prod.sh)
- [SQL Templates](sql/)
- [Validation](validate_post_migration.sh)
- [Rollback](rollback_restore.sql)

### Validators
- [JSON Schemas](S4_jsonschema/)
- [Pydantic Models](S4_pydantic/)
- [SQL Checks](S4_checks.sql)
- [Runner Script](S4_runner.py)

### Scraper Integration
- [Event Contracts](S5_event_contracts.yaml)
- [Golden Samples](S5_input_examples/)
- [Compliance Checklist](S5_diff_template.md)

## Quick Stats
- **Tables:** 266 in production
- **Records:** 13,463 migrated
- **Contracts:** 264 tables covered
- **Validators:** 100% coverage for core tables
- **Scrapers:** 4 entities integrated