# Publish Checklist

## Pre-flight Checks
- [ ] All phase reports exist (S0-S6)
- [ ] No temp files (*.bak, *~, .DS_Store)
- [ ] No __pycache__ directories
- [ ] README.md in root
- [ ] LICENSE file present
- [ ] .gitignore configured

## Data Validation
- [ ] Run S4_runner.py locally
- [ ] Execute S4_checks.sql
- [ ] Verify row counts match S1_row_counts_LIVE.csv
- [ ] Test migration script in DRY_RUN mode

## Documentation
- [ ] SUMMARY.md links all reports
- [ ] S5_diff_template.md reviewed
- [ ] Migration README complete
- [ ] All YAML files valid

## Security
- [ ] No credentials in code
- [ ] No PII in samples
- [ ] PROJECT_ID parameterized
- [ ] Service account not committed

## BigQuery Access
- [ ] Note: 'bq' CLI required but not included
- [ ] Document gcloud SDK requirement
- [ ] List required permissions
- [ ] Test with minimal IAM role

## Final Steps
- [ ] Tag release v1.0.0
- [ ] Create GitHub release
- [ ] Add collaborator access
- [ ] Enable Issues/Discussions