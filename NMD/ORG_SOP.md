# NMD Organization SOP

**Standard Operating Procedures for DiagnosticPro Schema Repository Organization**

## Directory Purpose

| Directory | Purpose | What Goes Here |
|-----------|---------|----------------|
| `core/` | Living contracts and SLAs | Current table contracts, coverage data, SLA definitions |
| `specs/` | Data flow specifications | Lineage, export specifications, change policies |
| `kits/` | Validation and migration tools | SQL validators, migration scripts, rollback tools |
| `reports/` | Current status only | Latest high-level status reports (not archives) |
| `archive/` | Historical artifacts by date | Phased deliverables, old reports, samples, logs |
| `tools/` | Layout checks and cleaners | CI enforcement scripts, cleanup utilities |

## File Placement Rules

### ✅ Core Files (core/)
- **ONLY** put living, actively-used contracts here
- `S2b_table_contracts_full.yaml` - Master table contracts
- `S2_sla_retention.yaml` - SLA and retention policies
- `S2b_coverage.csv` - Current coverage metrics
- `S2b_gaps.md` - Current coverage gaps

### ✅ Specs Files (specs/)
- **ONLY** specifications that define data flow
- `S3_lineage.md` - Data lineage documentation
- `S3_export_spec.md` - Export format specifications
- `S3_change_policy.md` - Change management policies

### ✅ Kits Files (kits/)
- **ONLY** operational tools and scripts
- `S4_checks.sql` - SQL validation queries
- `S4_runner.py` - Validation runner script
- `migrate_staging_to_prod.sh` - Migration orchestration
- `validate_post_migration.sh` - Post-migration validation
- `sql/` - SQL merge templates and queries
- `rollback_*.sql` - Rollback procedures
- `prep_release.sh` - Release preparation

### ✅ Reports Files (reports/)
- **ONLY** current high-level status reports
- Latest overall status summary
- Current phase completion status
- **NOT** detailed phase reports (those go to archive/)

### ✅ Archive Files (archive/YYYYMMDD/)
- **Everything else** organized by date
- `phases/` - Individual phase deliverables
- `reports/` - Historical detailed reports
- `catalog/` - Schema discovery artifacts
- `samples/` - Golden sample data
- `logs/` - Migration and validation logs

### ✅ Tools Files (tools/)
- **ONLY** layout enforcement and cleanup scripts
- `check_layout.sh` - CI layout validation
- `clean_empty_dirs.sh` - Empty directory cleanup

## Prohibited Content

### ❌ Never Commit
- Data dumps or large datasets
- API keys, credentials, or secrets
- Personal information or PII
- Temporary files (*.tmp, *.bak, *~)
- Cache directories (__pycache__, .DS_Store)
- Empty directories

### ❌ Wrong Locations
- Phase reports in core/ (goes to archive/)
- Old contracts in kits/ (goes to archive/)
- Data samples in specs/ (goes to archive/)
- Tools in core/ (goes to tools/)

## Maintenance Procedures

### Daily Operations
```bash
# Clean empty directories
bash NMD/tools/clean_empty_dirs.sh

# Check layout compliance
bash NMD/tools/check_layout.sh
```

### Adding New Files
1. **Determine purpose** - Is it core, spec, kit, report, or archive?
2. **Check if current** - Only latest/living files go in core/specs/kits/reports
3. **Place correctly** - Use appropriate directory based on purpose
4. **Run layout check** - Ensure compliance before commit

### Archiving Old Files
```bash
# Create new archive directory
TODAY="$(date -u +%Y%m%d)"
mkdir -p "NMD/archive/${TODAY}/"{phases,reports,catalog,samples,logs}

# Move old files by category
mv old_phase_files NMD/archive/${TODAY}/phases/
mv old_reports NMD/archive/${TODAY}/reports/
# etc.
```

## CI/CD Integration

### Pre-commit Hook
- Layout validation runs automatically
- Large file detection (5MB limit)
- YAML syntax validation
- Trailing whitespace cleanup

### CI Pipeline Check
```yaml
- name: Enforce NMD layout
  run: bash NMD/tools/check_layout.sh
```

## Emergency Procedures

### Layout Violation Recovery
1. **Identify violations**: Run `bash NMD/tools/check_layout.sh`
2. **Move misplaced files**: Use appropriate archive or proper directory
3. **Clean artifacts**: Run `bash NMD/tools/clean_empty_dirs.sh`
4. **Verify compliance**: Re-run layout check

### Accidental Secret Commit
1. **Stop immediately** - Do not push to remote
2. **Remove secret** - Edit or remove file
3. **Rewrite history** - Use `git reset` or `git rebase`
4. **Force push** - Only if already pushed (dangerous)
5. **Rotate credentials** - Change any exposed secrets

## Compliance Verification

The repository layout is considered compliant when:
- ✅ `bash NMD/tools/check_layout.sh` passes
- ✅ No empty directories exist
- ✅ All files are in appropriate directories
- ✅ No secrets or large files are committed
- ✅ Pre-commit hooks are configured and passing

**Violation Policy**: Any file not matching the allowed pattern will cause CI failure and must be moved to the appropriate location before merge.