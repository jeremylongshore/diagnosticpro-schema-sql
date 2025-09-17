# S4 CI/CD Integration Guide

**Created:** 2025-09-16
**Purpose:** Documentation for running S4 validation locally and in CI/CD pipelines

## Overview

This guide covers how to set up and run S4 data quality validation both locally and in continuous integration environments. The S4 validation framework provides comprehensive BigQuery schema validation, constraint checking, and data freshness monitoring.

## Local Development Setup

### Prerequisites

1. **Python Environment**
   ```bash
   python3 --version  # Requires Python 3.11+
   pip install --upgrade pip
   ```

2. **Google Cloud SDK**
   ```bash
   # Install gcloud CLI
   curl https://sdk.cloud.google.com | bash
   gcloud auth login
   gcloud config set project diagnostic-pro-start-up
   ```

3. **BigQuery Access**
   ```bash
   # Test BigQuery connectivity
   bq ls
   bq ls diagnosticpro_prod
   ```

### Installation

1. **Clone and Navigate**
   ```bash
   cd /home/jeremy/projects/diagnostic-platform/diag-schema-sql
   ```

2. **Install Dependencies**
   ```bash
   # From requirements file
   pip install -r NMD/requirements.txt

   # Or install core dependencies manually
   pip install google-cloud-bigquery>=3.11.0 \
               jsonschema>=4.19.0 \
               PyYAML>=6.0 \
               tqdm>=4.65.0
   ```

3. **Verify Installation**
   ```bash
   cd NMD
   python3 S4_runner.py --help
   ./setup_validation_environment.sh
   ```

### Local Validation Commands

#### Quick Development Validation
```bash
cd NMD

# Fast schema validation for development
python3 S4_runner.py \
  --mode schema \
  --validation-level quick \
  --verbose

# Quick constraint check
python3 S4_runner.py \
  --mode constraints \
  --validation-level quick \
  --verbose
```

#### Standard Validation
```bash
# JSON Schema validation
python3 S4_runner.py \
  --mode schema \
  --project-id diagnostic-pro-start-up \
  --dataset diagnosticpro_prod \
  --validation-level standard \
  --verbose

# SQL constraint validation
python3 S4_runner.py \
  --mode constraints \
  --project-id diagnostic-pro-start-up \
  --dataset diagnosticpro_prod \
  --validation-level standard \
  --verbose

# Data freshness validation (allows soft failures)
python3 S4_runner.py \
  --mode freshness \
  --project-id diagnostic-pro-start-up \
  --dataset diagnosticpro_prod \
  --validation-level standard \
  --allow-soft-failures \
  --verbose
```

#### Comprehensive Validation
```bash
# Full validation suite
python3 S4_runner.py \
  --mode all \
  --project-id diagnostic-pro-start-up \
  --dataset diagnosticpro_prod \
  --validation-level comprehensive \
  --verbose

# Generate HTML report
python3 S4_runner.py \
  --mode summary \
  --project-id diagnostic-pro-start-up \
  --dataset diagnosticpro_prod \
  --output-format html \
  --verbose
```

## CI/CD Pipeline Configuration

### GitHub Actions Configuration

The project includes a complete GitHub Actions workflow at `.github/workflows/data-quality.yml`.

#### Manual Triggers
```bash
# Via GitHub UI or CLI
gh workflow run data-quality.yml \
  -f target_dataset=diagnosticpro_prod \
  -f validation_level=standard \
  -f fail_on_warnings=false
```

#### Pull Request Validation
Automatically triggers on PRs affecting:
- `NMD/**` files
- Schema files (`*.json`, `*.yaml`)
- BigQuery scripts (`bigquery_**`)

#### Secrets Configuration

Set these secrets in your GitHub repository:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `GCP_PROJECT` | Google Cloud Project ID | Optional (defaults to diagnostic-pro-start-up) |
| `GCP_SA_KEY` | Service Account JSON key (base64 encoded) | Required for production |

**Creating Service Account Key:**
```bash
# Create service account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account"

# Grant BigQuery permissions
gcloud projects add-iam-policy-binding diagnostic-pro-start-up \
  --member="serviceAccount:github-actions-sa@diagnostic-pro-start-up.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"

gcloud projects add-iam-policy-binding diagnostic-pro-start-up \
  --member="serviceAccount:github-actions-sa@diagnostic-pro-start-up.iam.gserviceaccount.com" \
  --role="roles/bigquery.metadataViewer"

# Create and download key
gcloud iam service-accounts keys create github-sa-key.json \
  --iam-account=github-actions-sa@diagnostic-pro-start-up.iam.gserviceaccount.com

# Base64 encode for GitHub secret
base64 -w 0 github-sa-key.json
```

### GitLab CI Configuration

```yaml
# .gitlab-ci.yml
stages:
  - validate

variables:
  PROJECT_ID: "diagnostic-pro-start-up"
  DATASET: "diagnosticpro_prod"

data-quality-validation:
  stage: validate
  image: python:3.11
  before_script:
    - pip install -r NMD/requirements.txt
    - echo $GCP_SA_KEY | base64 -d > /tmp/gcp-key.json
    - export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-key.json
  script:
    - cd NMD
    - python3 S4_runner.py --mode schema --project-id $PROJECT_ID --dataset $DATASET --verbose
    - python3 S4_runner.py --mode constraints --project-id $PROJECT_ID --dataset $DATASET --verbose
  artifacts:
    reports:
      junit: NMD/validation_report.xml
    paths:
      - NMD/validation_*.json
      - NMD/validation_*.html
    expire_in: 1 week
  only:
    - merge_requests
    - main
```

### Jenkins Pipeline Configuration

```groovy
pipeline {
    agent any

    environment {
        PROJECT_ID = 'diagnostic-pro-start-up'
        DATASET = 'diagnosticpro_prod'
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key')
    }

    stages {
        stage('Setup') {
            steps {
                sh 'pip install -r NMD/requirements.txt'
            }
        }

        stage('Schema Validation') {
            steps {
                dir('NMD') {
                    sh '''
                    python3 S4_runner.py \
                        --mode schema \
                        --project-id $PROJECT_ID \
                        --dataset $DATASET \
                        --output-format github \
                        --verbose
                    '''
                }
            }
        }

        stage('Constraint Validation') {
            steps {
                dir('NMD') {
                    sh '''
                    python3 S4_runner.py \
                        --mode constraints \
                        --project-id $PROJECT_ID \
                        --dataset $DATASET \
                        --output-format github \
                        --verbose
                    '''
                }
            }
        }

        stage('Generate Report') {
            steps {
                dir('NMD') {
                    sh '''
                    python3 S4_runner.py \
                        --mode summary \
                        --project-id $PROJECT_ID \
                        --dataset $DATASET \
                        --output-format html
                    '''
                }
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'NMD',
                    reportFiles: 'validation_report.html',
                    reportName: 'Data Quality Report'
                ])
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'NMD/validation_*.json,NMD/validation_*.html', allowEmptyArchive: true
        }
    }
}
```

## Exit Code Documentation

The S4 validation runner uses standardized exit codes for CI/CD integration:

| Exit Code | Meaning | Action |
|-----------|---------|---------|
| `0` | ✅ Success | All validations passed |
| `1` | ❌ Hard Failure | Schema/constraint violations - **FAIL BUILD** |
| `2` | ⚠️ Soft Failure | Freshness/SLA violations - **WARN BUT CONTINUE** |

### Handling Exit Codes in CI

#### Fail on Hard Failures Only
```bash
# In CI script
cd NMD
python3 S4_runner.py --mode constraints --verbose
exit_code=$?

if [ $exit_code -eq 1 ]; then
    echo "❌ Critical validation failures detected"
    exit 1
elif [ $exit_code -eq 2 ]; then
    echo "⚠️ Soft failures detected, continuing..."
    exit 0
else
    echo "✅ Validation passed"
    exit 0
fi
```

#### Fail on Any Failure
```bash
# Strict mode - fail on any issue
cd NMD
python3 S4_runner.py --mode all --verbose --strict
```

## BigQuery Permissions Required

### Minimum Required Roles

For the service account used in CI:

1. **BigQuery Data Viewer** (`roles/bigquery.dataViewer`)
   - Read table data for validation
   - Required for constraint checking

2. **BigQuery Metadata Viewer** (`roles/bigquery.metadataViewer`)
   - Read table schemas and metadata
   - Required for schema validation

3. **BigQuery Job User** (`roles/bigquery.jobUser`)
   - Execute BigQuery jobs
   - Required for running validation queries

### Custom Role (Recommended)

```yaml
# custom-validation-role.yaml
title: "BigQuery Validation Role"
description: "Minimum permissions for data quality validation"
stage: "GA"
includedPermissions:
  - bigquery.datasets.get
  - bigquery.tables.get
  - bigquery.tables.getData
  - bigquery.tables.list
  - bigquery.jobs.create
  - bigquery.jobs.get
  - bigquery.jobs.list
```

```bash
# Create custom role
gcloud iam roles create bigqueryValidationRole \
  --project=diagnostic-pro-start-up \
  --file=custom-validation-role.yaml

# Assign to service account
gcloud projects add-iam-policy-binding diagnostic-pro-start-up \
  --member="serviceAccount:github-actions-sa@diagnostic-pro-start-up.iam.gserviceaccount.com" \
  --role="projects/diagnostic-pro-start-up/roles/bigqueryValidationRole"
```

## Validation Levels

### Quick (`validation-level: quick`)
- Fast execution (< 2 minutes)
- Core schema validation only
- Subset of tables (high-priority)
- Ideal for development and pre-commit hooks

### Standard (`validation-level: standard`)
- Moderate execution (5-10 minutes)
- Schema + basic constraints
- Most production tables
- Default for CI/CD pipelines

### Comprehensive (`validation-level: comprehensive`)
- Full execution (15-30 minutes)
- All validations + freshness checks
- All tables and advanced rules
- Release validation and scheduled runs

## Troubleshooting

### Common Issues

#### 1. Authentication Errors
```bash
# Check credentials
gcloud auth list
gcloud config get-value project

# Test BigQuery access
bq ls diagnosticpro_prod
```

#### 2. Missing Dependencies
```bash
# Reinstall dependencies
pip install --force-reinstall -r NMD/requirements.txt

# Check specific imports
python3 -c "import google.cloud.bigquery; print('✅ BigQuery OK')"
python3 -c "import jsonschema; print('✅ JSONSchema OK')"
```

#### 3. Permission Denied
```bash
# Check service account permissions
gcloud projects get-iam-policy diagnostic-pro-start-up \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:github-actions-sa@diagnostic-pro-start-up.iam.gserviceaccount.com"
```

#### 4. Timeout Issues
```bash
# Use quick validation for large datasets
python3 S4_runner.py --mode schema --validation-level quick --timeout 300
```

### Debug Mode

Enable detailed logging:

```bash
# Maximum verbosity
python3 S4_runner.py \
  --mode schema \
  --verbose \
  --debug \
  --log-level DEBUG \
  --output-format console
```

## Performance Optimization

### For Large Datasets

1. **Use Sampling**
   ```bash
   python3 S4_runner.py --mode constraints --sample-size 10000
   ```

2. **Parallel Execution**
   ```bash
   python3 S4_runner.py --mode all --parallel-jobs 4
   ```

3. **Cache Results**
   ```bash
   python3 S4_runner.py --mode schema --cache-results --cache-ttl 3600
   ```

## Monitoring and Alerting

### Integration with Monitoring Systems

#### Datadog
```bash
# Send metrics to Datadog
python3 S4_runner.py \
  --mode all \
  --metrics-backend datadog \
  --datadog-api-key $DD_API_KEY
```

#### Prometheus
```bash
# Export Prometheus metrics
python3 S4_runner.py \
  --mode all \
  --metrics-backend prometheus \
  --prometheus-pushgateway http://prometheus:9091
```

### Slack Notifications

```bash
# Send results to Slack
python3 S4_runner.py \
  --mode all \
  --slack-webhook $SLACK_WEBHOOK_URL \
  --notify-on-failure
```

---

**Last Updated:** 2025-09-16
**Version:** 1.0.0
**Dependencies:** S4_runner.py, Google Cloud SDK, Python 3.11+