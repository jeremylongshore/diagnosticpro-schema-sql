# NMD Layout

**DiagnosticPro Schema Repository Organization**

## Directory Structure

| Directory | Contents | Purpose |
|-----------|----------|---------|
| **core/** | Current contracts and SLAs | Living table contracts, coverage metrics, retention policies |
| **specs/** | Lineage, export, change policy | Data flow specifications and change management |
| **kits/** | Validation + migration tools | SQL validators, migration scripts, rollback procedures |
| **reports/** | Current status | Latest high-level status reports only |
| **archive/** | Phased artifacts and logs by date | Historical deliverables organized by YYYYMMDD |
| **tools/** | Layout checks and cleaners | CI enforcement scripts and cleanup utilities |

## Quick Navigation

### 🔧 Development Operations
- **Validate data**: `kits/S4_runner.py`
- **Run migration**: `kits/migrate_staging_to_prod.sh`
- **Check layout**: `tools/check_layout.sh`
- **Clean directories**: `tools/clean_empty_dirs.sh`

### 📋 Current Contracts
- **Master contracts**: `core/S2b_table_contracts_full.yaml`
- **SLA policies**: `core/S2_sla_retention.yaml`
- **Coverage status**: `core/S2b_coverage.csv`
- **Gap analysis**: `core/S2b_gaps.md`

### 📊 Specifications
- **Data lineage**: `specs/S3_lineage.md`
- **Export formats**: `specs/S3_export_spec.md`
- **Change policy**: `specs/S3_change_policy.md`

### 🗃️ Historical Archive
- **Phase reports**: `archive/YYYYMMDD/phases/`
- **Detailed reports**: `archive/YYYYMMDD/reports/`
- **Schema catalogs**: `archive/YYYYMMDD/catalog/`
- **Sample data**: `archive/YYYYMMDD/samples/`
- **Migration logs**: `archive/YYYYMMDD/logs/`

## Usage

### For Schema Developers
```bash
# Check current table contracts
cat core/S2b_table_contracts_full.yaml

# Run data validation
python kits/S4_runner.py --project diagnostic-pro-start-up --dataset diagnosticpro_prod --tables "*"

# Execute migration
bash kits/migrate_staging_to_prod.sh
```

### For CI/CD Integration
```bash
# Layout compliance check (runs in CI)
bash tools/check_layout.sh

# Clean empty directories
bash tools/clean_empty_dirs.sh
```

### For Historical Research
```bash
# Find old phase reports
ls archive/*/phases/

# Review migration logs
ls archive/*/logs/
```

## Compliance

This repository enforces strict layout compliance:
- ✅ All files must be in designated directories
- ✅ No secrets or large files permitted
- ✅ Layout check runs in CI/CD pipeline
- ✅ Pre-commit hooks prevent violations

See `ORG_SOP.md` for detailed organization procedures.