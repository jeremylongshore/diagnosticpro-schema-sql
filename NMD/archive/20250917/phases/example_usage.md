# S4 Validation Runner - Usage Examples

**Created:** 2025-09-16
**Status:** Production Ready Examples

## Quick Start Examples

### 1. Basic Validation
```bash
# Validate all tables with default settings
python S4_runner.py

# Validate specific tables
python S4_runner.py --tables "users,equipment_registry"

# Get help
python S4_runner.py --help
```

### 2. Pattern Matching
```bash
# All tables starting with "user"
python S4_runner.py --tables "user*"

# All tables ending with "_diagnostic"
python S4_runner.py --tables "*_diagnostic"

# Multiple patterns
python S4_runner.py --tables "reddit_*,youtube_*,github_*"
```

### 3. Output Formats
```bash
# Human-readable text output (default)
python S4_runner.py --tables "users"

# JSON output for CI/CD
python S4_runner.py --tables "users" --output json

# JSON with all tables
python S4_runner.py --output json > validation_report.json
```

### 4. Failure Thresholds
```bash
# Fail only on hard errors (default)
python S4_runner.py --fail-on error --tables "users"

# Fail on warnings too (strict mode)
python S4_runner.py --fail-on warn --tables "critical_*"
```

### 5. Different Projects/Datasets
```bash
# Custom project and dataset
python S4_runner.py \
  --project my-project \
  --dataset my_dataset \
  --tables "*"

# Staging environment validation
python S4_runner.py \
  --project diagnostic-pro-start-up \
  --dataset repair_diagnostics \
  --tables "*"
```

## CI/CD Pipeline Examples

### GitHub Actions
```yaml
name: Data Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install -r NMD/requirements.txt

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Run validation
        run: |
          cd NMD
          python S4_runner.py \
            --project diagnostic-pro-start-up \
            --dataset diagnosticpro_prod \
            --tables "*" \
            --fail-on warn \
            --output json > validation_results.json

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: validation-results
          path: NMD/validation_results.json
```

### GitLab CI
```yaml
validate_data:
  stage: test
  image: python:3.12
  before_script:
    - pip install -r NMD/requirements.txt
    - echo $GCP_SERVICE_ACCOUNT_KEY | base64 -d > gcp-key.json
    - export GOOGLE_APPLICATION_CREDENTIALS=gcp-key.json
  script:
    - cd NMD
    - python S4_runner.py --output json --fail-on warn
  artifacts:
    reports:
      junit: NMD/validation_results.json
    expire_in: 30 days
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any

    stages {
        stage('Validate Data') {
            steps {
                script {
                    sh '''
                        cd NMD
                        pip install -r requirements.txt
                        python S4_runner.py --output json --fail-on error > validation_results.json
                    '''

                    def exitCode = sh(
                        script: 'cd NMD && python S4_runner.py --fail-on warn',
                        returnStatus: true
                    )

                    if (exitCode == 1) {
                        error("Hard validation failures found")
                    } else if (exitCode == 2) {
                        unstable("SLA warnings found")
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'NMD/validation_results.json'
                }
            }
        }
    }
}
```

## Monitoring and Alerting Examples

### Slack Notifications
```bash
#!/bin/bash
# slack_validation.sh

# Run validation and capture results
python S4_runner.py --output json > validation_results.json
EXIT_CODE=$?

# Parse results
TOTAL_CHECKS=$(jq '.summary.total_checks' validation_results.json)
FAILED_CHECKS=$(jq '.summary.failed_checks' validation_results.json)
WARNINGS=$(jq '.summary.total_warnings' validation_results.json)

# Send Slack notification based on results
case $EXIT_CODE in
  0)
    MESSAGE="✅ Data validation passed! $TOTAL_CHECKS checks completed successfully."
    ;;
  1)
    MESSAGE="❌ Data validation failed! $FAILED_CHECKS failures found in $TOTAL_CHECKS checks."
    ;;
  2)
    MESSAGE="⚠️ Data validation warnings! $WARNINGS warnings found in $TOTAL_CHECKS checks."
    ;;
esac

curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"$MESSAGE\"}" \
  $SLACK_WEBHOOK_URL
```

### Datadog Metrics
```bash
#!/bin/bash
# datadog_validation.sh

# Run validation
python S4_runner.py --output json > validation_results.json

# Extract metrics
TOTAL_CHECKS=$(jq '.summary.total_checks' validation_results.json)
FAILED_CHECKS=$(jq '.summary.failed_checks' validation_results.json)
SUCCESS_RATE=$(jq -r '.summary.success_rate' validation_results.json | sed 's/%//')

# Send to Datadog
curl -X POST "https://api.datadoghq.com/api/v1/series" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: $DD_API_KEY" \
-d '{
  "series": [
    {
      "metric": "bigquery.validation.total_checks",
      "points": [['$(date +%s)', '$TOTAL_CHECKS']],
      "tags": ["environment:prod", "dataset:diagnosticpro_prod"]
    },
    {
      "metric": "bigquery.validation.failed_checks",
      "points": [['$(date +%s)', '$FAILED_CHECKS']],
      "tags": ["environment:prod", "dataset:diagnosticpro_prod"]
    },
    {
      "metric": "bigquery.validation.success_rate",
      "points": [['$(date +%s)', '$SUCCESS_RATE']],
      "tags": ["environment:prod", "dataset:diagnosticpro_prod"]
    }
  ]
}'
```

## Advanced Usage Patterns

### Staged Validation
```bash
#!/bin/bash
# staged_validation.sh

echo "🔍 Stage 1: Critical tables validation"
python S4_runner.py \
  --tables "users,equipment_registry,diagnostic_sessions" \
  --fail-on warn \
  --output json > critical_validation.json

if [ $? -ne 0 ]; then
  echo "❌ Critical validation failed - stopping"
  exit 1
fi

echo "🔍 Stage 2: Data tables validation"
python S4_runner.py \
  --tables "reddit_*,youtube_*,github_*" \
  --fail-on error \
  --output json > data_validation.json

echo "🔍 Stage 3: All remaining tables"
python S4_runner.py \
  --tables "*" \
  --fail-on error \
  --output json > full_validation.json

echo "✅ All validation stages completed"
```

### Parallel Validation
```bash
#!/bin/bash
# parallel_validation.sh

# Run validations in parallel for different table groups
python S4_runner.py --tables "user*" --output json > user_validation.json &
python S4_runner.py --tables "reddit_*" --output json > reddit_validation.json &
python S4_runner.py --tables "youtube_*" --output json > youtube_validation.json &
python S4_runner.py --tables "github_*" --output json > github_validation.json &

# Wait for all to complete
wait

echo "All parallel validations completed"

# Combine results
jq -s '.[0].results + .[1].results + .[2].results + .[3].results' \
  user_validation.json reddit_validation.json youtube_validation.json github_validation.json \
  > combined_validation.json
```

### Scheduled Validation
```bash
#!/bin/bash
# scheduled_validation.sh

# Add to crontab:
# 0 */6 * * * /path/to/scheduled_validation.sh

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="/var/log/bigquery_validation"
mkdir -p $LOG_DIR

echo "🕐 Starting scheduled validation at $(date)"

# Run validation with timestamp
python S4_runner.py \
  --output json \
  --fail-on warn > $LOG_DIR/validation_${TIMESTAMP}.json

EXIT_CODE=$?

# Log results
echo "Validation completed with exit code: $EXIT_CODE" >> $LOG_DIR/validation.log

# Cleanup old logs (keep last 30 days)
find $LOG_DIR -name "validation_*.json" -mtime +30 -delete

# Send alerts if needed
if [ $EXIT_CODE -ne 0 ]; then
  echo "Validation issues detected - sending alert"
  # Add alerting logic here
fi
```

## Testing Examples

### Unit Testing
```bash
# Run basic functionality tests
python test_S4_runner.py

# Run with live BigQuery data
python test_S4_runner.py --live

# Test specific functionality
python -c "
from test_S4_runner import test_json_output
test_json_output()
"
```

### Integration Testing
```bash
#!/bin/bash
# integration_test.sh

echo "🧪 Running integration tests"

# Test 1: Basic validation
echo "Test 1: Basic validation"
python S4_runner.py --tables "users" --output json > test1.json
[ $? -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED"

# Test 2: Pattern matching
echo "Test 2: Pattern matching"
python S4_runner.py --tables "*_diagnostic" --output json > test2.json
[ $? -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED"

# Test 3: Failure thresholds
echo "Test 3: Failure thresholds"
python S4_runner.py --tables "users" --fail-on warn > test3.txt 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 2 ]; then
  echo "✅ PASSED"
else
  echo "❌ FAILED"
fi

echo "Integration tests completed"
```

## Performance Optimization Examples

### Large Dataset Validation
```bash
#!/bin/bash
# optimize_large_dataset.sh

# For datasets with 100+ tables, use batched approach
BATCH_SIZE=10

# Get all tables
python S4_runner.py --tables "*" --output json 2>/dev/null | \
  jq -r '.results[].name' > all_tables.txt

# Process in batches
split -l $BATCH_SIZE all_tables.txt batch_

for batch_file in batch_*; do
  TABLES=$(tr '\n' ',' < $batch_file | sed 's/,$//')
  echo "Processing batch: $batch_file"

  python S4_runner.py \
    --tables "$TABLES" \
    --output json > "validation_${batch_file}.json"
done

# Combine results
jq -s 'reduce .[] as $item ({}; . * $item)' validation_batch_*.json > final_validation.json

# Cleanup
rm batch_* validation_batch_*.json all_tables.txt
```

### Resource Monitoring
```bash
#!/bin/bash
# monitor_validation.sh

# Monitor resource usage during validation
echo "Starting resource monitoring..."

# Start monitoring in background
(while true; do
  echo "$(date): CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}'), Memory=$(free -h | awk 'NR==2{print $3}')"
  sleep 5
done) > resource_usage.log &
MONITOR_PID=$!

# Run validation
echo "Running validation..."
time python S4_runner.py --output json > validation_results.json

# Stop monitoring
kill $MONITOR_PID

echo "Validation completed. Check resource_usage.log for performance metrics."
```

---

**Last Updated:** 2025-09-16
**Next Review:** 2025-12-16