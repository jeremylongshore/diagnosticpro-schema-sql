# Diag Schema SQL
Production data contracts, lineage, validators, and migration kit for DiagnosticPro.

## Datasets
- **Staging:** `repair_diagnostics`
- **Production:** `diagnosticpro_prod`
- **Downstream:** `diagnosticpro_analytics`, `diagnosticpro_ml`, `diagnosticpro_archive`

## What's here
- **Contracts:** `NMD/S2_table_contracts.yaml`, `NMD/S2b_table_contracts_full.yaml`
- **SLAs & Retention:** `NMD/S2_sla_retention.yaml`
- **Catalog:** `NMD/S1_*`
- **Lineage & Export:** `NMD/S3_lineage.md`, `NMD/S3_export_spec.md`, `NMD/S3_change_policy.md`
- **Validators:** `NMD/S4_jsonschema/`, `NMD/S4_pydantic/`, `NMD/S4_checks.sql`, `NMD/S4_runner.py`
- **Migration Kit:** `NMD/migrate_staging_to_prod.sh`, `NMD/sql/*.sql`, `NMD/validate_post_migration.*`, rollback scripts
- **Scraper Contracts:** `NMD/S5_event_contracts.yaml`, `NMD/S5_input_examples/`, `NMD/S5_diff_template.md`

## Validate data (local)
```bash
python NMD/S4_runner.py --project <GCP_PROJECT> --dataset diagnosticpro_prod --tables "*" --fail-on error
bq query --use_legacy_sql=false --project_id=<GCP_PROJECT> < NMD/S4_checks.sql
```