# S3 - Export Specifications for DiagnosticPro BigQuery Platform
**Generated:** 2025-09-16
**Project:** diagnostic-pro-start-up
**Version:** 1.0.0
**Status:** Production Ready

## 1. Export Destinations

### 1.1 Primary: Google Cloud Storage (GCS)
```
gs://diagnosticpro-exports/
├── prod/                          # Production exports
│   ├── diagnosticpro_prod/       # Main dataset
│   │   ├── continuous/           # Real-time/streaming exports
│   │   ├── scheduled/            # Batch exports
│   │   └── on-demand/           # Manual exports
│   ├── diagnosticpro_analytics/  # Analytics dataset
│   ├── diagnosticpro_ml/        # ML features & predictions
│   └── diagnosticpro_archive/   # Long-term archives
├── staging/                       # Staging exports
└── dev/                          # Development exports
```

### 1.2 Secondary: AWS S3
```
s3://diagnosticpro-cross-cloud/
├── disaster-recovery/            # DR copies of critical data
├── partner-exchange/             # Data sharing with partners
└── compliance-archives/          # Regulatory compliance copies
```

### 1.3 Tertiary: Azure Blob Storage
```
https://diagnosticpro.blob.core.windows.net/
├── backup/                       # Additional backup layer
├── ml-training/                  # ML training datasets
└── edge-compute/                # Edge computing datasets
```

### 1.4 Archive Locations
```
gs://diagnosticpro-cold-storage/
├── financial-records/            # 7-year retention
├── compliance-data/              # 10-year retention
├── historical-telemetry/         # Compressed sensor data
└── deprecated-tables/            # Sunset table archives
```

## 2. Format Specifications

### 2.1 Parquet (Preferred)
**Use Cases:** Analytics, ML training, long-term storage
```yaml
format_config:
  version: "2.6"
  compression: "SNAPPY"  # Default
  encoding: "PLAIN_DICTIONARY"
  row_group_size: 128MB
  page_size: 1MB
  schema_evolution:
    enabled: true
    backward_compatible: true
    version_column: "_schema_version"
```

**Example: Sensor Telemetry Export**
```bash
bq extract \
  --destination_format=PARQUET \
  --compression=SNAPPY \
  diagnosticpro_prod.sensor_telemetry \
  gs://diagnosticpro-exports/prod/diagnosticpro_prod/scheduled/sensor_telemetry/2025/09/16/*.parquet
```

### 2.2 JSONL (Streaming/Real-time)
**Use Cases:** Event streams, API consumption, message queues
```yaml
format_config:
  newline_delimited: true
  encoding: "UTF-8"
  schema_included: false
  timestamp_format: "RFC3339"
  null_representation: "null"
```

**Example: Diagnostic Sessions Stream**
```bash
bq extract \
  --destination_format=NEWLINE_DELIMITED_JSON \
  --compression=GZIP \
  diagnosticpro_prod.diagnostic_sessions \
  gs://diagnosticpro-exports/prod/diagnosticpro_prod/continuous/diagnostic_sessions_*.jsonl.gz
```

### 2.3 CSV (Legacy Consumers)
**Use Cases:** Excel imports, legacy systems, simple reporting
```yaml
format_config:
  delimiter: ","
  header: true
  quote_character: '"'
  escape_character: "\\"
  null_marker: ""
  encoding: "UTF-8"
```

**Example: Parts Inventory Report**
```bash
bq extract \
  --destination_format=CSV \
  --field_delimiter=',' \
  --print_header=true \
  diagnosticpro_prod.parts_inventory \
  gs://diagnosticpro-exports/prod/diagnosticpro_prod/on-demand/parts_inventory.csv.gz
```

### 2.4 Compression Standards
```yaml
compression_matrix:
  GZIP:
    compatibility: "universal"
    compression_ratio: "60-70%"
    use_for: ["CSV", "JSONL", "legacy systems"]

  ZSTD:
    compatibility: "modern systems"
    compression_ratio: "70-80%"
    speed: "3x faster than GZIP"
    use_for: ["Parquet", "high-volume data"]

  SNAPPY:
    compatibility: "BigQuery native"
    compression_ratio: "40-50%"
    speed: "fastest"
    use_for: ["real-time", "low-latency"]

  BROTLI:
    compatibility: "web delivery"
    compression_ratio: "80-85%"
    use_for: ["API responses", "CDN distribution"]
```

## 3. Partitioning Strategy

### 3.1 Standard Date-Based Partitioning
```
{bucket}/{env}/{dataset}/{entity}/{yyyy}/{MM}/{dd}/
```

**Example: Reddit Diagnostic Posts**
```
gs://diagnosticpro-exports/prod/diagnosticpro_prod/reddit_diagnostic_posts/2025/09/16/
├── reddit_diagnostic_posts_20250916_000000_a1b2c3d4.parquet.snappy
├── reddit_diagnostic_posts_20250916_060000_e5f6g7h8.parquet.snappy
├── reddit_diagnostic_posts_20250916_120000_i9j0k1l2.parquet.snappy
└── reddit_diagnostic_posts_20250916_180000_m3n4o5p6.parquet.snappy
```

### 3.2 High-Volume Table Partitioning
```yaml
sensor_telemetry:
  primary_partition: "date(created_at)"
  secondary_partition: "equipment_id % 100"  # 100 shards
  tertiary_partition: "sensor_type"
  path_pattern: "{entity}/{yyyy}/{MM}/{dd}/{HH}/{shard_id}/{sensor_type}/"

diagnostic_sessions:
  primary_partition: "date(session_start)"
  secondary_partition: "user_region"
  path_pattern: "{entity}/{yyyy}/{MM}/{dd}/{region}/"

feature_store:
  primary_partition: "feature_timestamp"
  secondary_partition: "feature_category"
  path_pattern: "{entity}/{yyyy}/{MM}/{dd}/{category}/"
```

### 3.3 Filename Patterns
```yaml
pattern: "{entity}_{yyyymmdd}_{HHMMSS}_{uuid}.{format}.{compression}"

examples:
  - "users_20250916_143022_7f3b4e5a.parquet.snappy"
  - "sensor_telemetry_20250916_143022_8a6c9d2b.jsonl.gz"
  - "parts_inventory_20250916_143022_9e7f1c3d.csv.gz"

metadata_sidecar: "{filename}.metadata.json"
```

## 4. Append vs Overwrite Rules

### 4.1 Append-Only Tables
**Never overwrite, always add new records**
```yaml
append_only:
  audit_logs:
    reason: "Immutable audit trail"
    export_mode: "APPEND"
    deduplication: "by event_id on consumer side"

  sensor_telemetry:
    reason: "Time-series data stream"
    export_mode: "APPEND"
    partition_by: "hourly"

  api_access_log:
    reason: "Security audit trail"
    export_mode: "APPEND"
    retention: "2190 days"

  diagnostic_sessions:
    reason: "Historical diagnostic records"
    export_mode: "APPEND"
    archive_after: "90 days"

  reddit_diagnostic_posts:
    reason: "Scraped content accumulation"
    export_mode: "APPEND"
    deduplication: "by post_id"
```

### 4.2 Full Refresh Tables
**Complete replacement on each export**
```yaml
full_refresh:
  equipment_manufacturers:
    reason: "Reference data"
    export_mode: "OVERWRITE"
    frequency: "weekly"

  dtc_code_definitions:
    reason: "Master lookup table"
    export_mode: "OVERWRITE"
    frequency: "monthly"

  configuration_settings:
    reason: "System configuration"
    export_mode: "OVERWRITE"
    frequency: "on_change"

  parts_catalog:
    reason: "Product catalog"
    export_mode: "OVERWRITE"
    frequency: "daily"
```

### 4.3 Incremental Tables
**Export only changed/new records**
```yaml
incremental:
  users:
    export_mode: "INCREMENTAL"
    change_column: "updated_at"
    lookback_window: "24 hours"
    merge_key: "user_id"

  equipment_registry:
    export_mode: "INCREMENTAL"
    change_column: "last_modified"
    lookback_window: "7 days"
    merge_key: "identification_number"

  parts_inventory:
    export_mode: "INCREMENTAL"
    change_column: "inventory_updated_at"
    lookback_window: "4 hours"
    merge_key: ["part_id", "location_id"]

  billing_transactions:
    export_mode: "INCREMENTAL"
    change_column: "transaction_timestamp"
    lookback_window: "48 hours"
    merge_key: "transaction_id"
```

## 5. Manifest and Validation

### 5.1 Manifest Structure
```json
{
  "export_id": "exp_20250916_143022_7f3b4e5a",
  "export_timestamp": "2025-09-16T14:30:22Z",
  "source": {
    "project": "diagnostic-pro-start-up",
    "dataset": "diagnosticpro_prod",
    "table": "sensor_telemetry",
    "partition": "2025-09-16"
  },
  "destination": {
    "uri": "gs://diagnosticpro-exports/prod/diagnosticpro_prod/sensor_telemetry/2025/09/16/",
    "format": "PARQUET",
    "compression": "SNAPPY"
  },
  "statistics": {
    "row_count": 1548293,
    "byte_size": 245678912,
    "compressed_size": 98271564,
    "schema_version": "2025.09.01.00",
    "column_count": 47
  },
  "files": [
    {
      "name": "sensor_telemetry_20250916_143022_7f3b4e5a_001.parquet.snappy",
      "rows": 500000,
      "bytes": 82189123,
      "checksum": "sha256:a3b4c5d6e7f8..."
    }
  ],
  "validation": {
    "schema_hash": "sha256:9f8e7d6c5b4a...",
    "row_count_verified": true,
    "checksum_verified": true,
    "duplicate_check": "passed",
    "null_check": "passed"
  },
  "metadata": {
    "export_type": "scheduled",
    "export_trigger": "cron",
    "export_duration_ms": 45678,
    "bigquery_job_id": "job_abc123xyz",
    "operator": "airflow-export-dag"
  }
}
```

### 5.2 Validation Rules
```yaml
validation_checks:
  pre_export:
    - verify_source_table_exists
    - check_partition_freshness
    - estimate_export_size
    - verify_destination_permissions

  during_export:
    - monitor_job_progress
    - track_bytes_transferred
    - validate_schema_consistency

  post_export:
    - verify_row_counts
    - calculate_checksums
    - validate_file_formats
    - check_compression_ratios
    - create_success_marker

  failure_handling:
    - create_failure_marker
    - log_error_details
    - trigger_alert
    - initiate_retry
```

### 5.3 Success/Failure Markers
```bash
# Success marker
gs://diagnosticpro-exports/.../SUCCESS
{
  "status": "SUCCESS",
  "timestamp": "2025-09-16T14:35:22Z",
  "manifest": "manifest_20250916_143022.json",
  "row_count": 1548293
}

# Failure marker
gs://diagnosticpro-exports/.../FAILURE
{
  "status": "FAILURE",
  "timestamp": "2025-09-16T14:35:22Z",
  "error": "Export job failed: Quota exceeded",
  "retry_count": 2,
  "next_retry": "2025-09-16T14:45:22Z"
}
```

## 6. Access Controls

### 6.1 IAM Roles for Exporters
```yaml
service_accounts:
  bigquery-exporter@diagnostic-pro-start-up.iam.gserviceaccount.com:
    roles:
      - roles/bigquery.dataViewer      # Read BigQuery tables
      - roles/bigquery.jobUser         # Run export jobs
      - roles/storage.objectCreator    # Write to GCS
      - roles/storage.legacyBucketWriter

  cross-cloud-exporter@diagnostic-pro-start-up.iam.gserviceaccount.com:
    roles:
      - roles/storage.objectViewer     # Read from GCS
      - custom/aws-s3-writer           # Write to S3
      - custom/azure-blob-writer       # Write to Azure

  compliance-exporter@diagnostic-pro-start-up.iam.gserviceaccount.com:
    roles:
      - roles/bigquery.dataViewer
      - roles/storage.objectCreator
      - roles/cloudkms.cryptoKeyEncrypter  # Encrypt exports
```

### 6.2 Bucket-Level Permissions
```yaml
bucket_policies:
  diagnosticpro-exports:
    uniform_access: true
    versioning: enabled
    lifecycle_rules:
      - age: 30
        action: "SetStorageClass:NEARLINE"
      - age: 90
        action: "SetStorageClass:COLDLINE"
      - age: 365
        action: "SetStorageClass:ARCHIVE"

    iam_bindings:
      - role: "roles/storage.objectViewer"
        members:
          - "group:data-analysts@diagnosticpro.com"
          - "serviceAccount:analytics-reader@..."

      - role: "roles/storage.objectCreator"
        members:
          - "serviceAccount:bigquery-exporter@..."
          - "serviceAccount:airflow-operator@..."
```

### 6.3 Encryption Configuration
```yaml
encryption:
  at_rest:
    method: "Google-managed keys (GMEK)"
    algorithm: "AES-256"
    key_rotation: "90 days"

    sensitive_data:
      method: "Customer-managed keys (CMEK)"
      kms_key: "projects/diagnostic-pro-start-up/locations/us-central1/keyRings/exports/cryptoKeys/sensitive-data"
      algorithm: "AES-256-GCM"

  in_transit:
    protocol: "TLS 1.3"
    cipher_suites:
      - "TLS_AES_256_GCM_SHA384"
      - "TLS_CHACHA20_POLY1305_SHA256"
    certificate: "*.diagnosticpro.com"

  cross_cloud:
    aws_s3:
      sse: "AES256"
      kms_master_key: "arn:aws:kms:us-east-1:..."

    azure_blob:
      encryption_scope: "diagnosticpro-exports"
      key_vault: "diagnosticpro-keys"
```

## 7. Error Handling

### 7.1 Retry Logic
```yaml
retry_configuration:
  max_attempts: 5
  backoff_strategy: "exponential"
  initial_delay_seconds: 30
  max_delay_seconds: 3600
  multiplier: 2

  retry_conditions:
    - "RATE_LIMIT_EXCEEDED"
    - "QUOTA_EXCEEDED"
    - "TIMEOUT"
    - "INTERNAL_ERROR"
    - "SERVICE_UNAVAILABLE"

  non_retryable:
    - "PERMISSION_DENIED"
    - "INVALID_ARGUMENT"
    - "NOT_FOUND"
    - "ALREADY_EXISTS"
```

**Implementation Example:**
```python
import time
from google.cloud import bigquery
from google.api_core import retry

@retry.Retry(
    predicate=retry.if_transient_error,
    initial=30.0,
    maximum=3600.0,
    multiplier=2.0,
    deadline=7200.0
)
def export_with_retry(client, table_ref, destination_uri, job_config):
    """Export BigQuery table with exponential backoff retry."""
    job = client.extract_table(
        table_ref,
        destination_uri,
        job_config=job_config
    )
    return job.result()  # Wait for job completion
```

### 7.2 Dead Letter Queue
```yaml
dlq_configuration:
  storage_location: "gs://diagnosticpro-exports/dead-letter-queue/"

  structure:
    failed_exports/:
      - export_request.json    # Original export request
      - error_details.json     # Error information
      - retry_history.json     # Retry attempts

    poison_messages/:         # Permanently failed
      - message_id.json
      - failure_reason.txt

  retention: "90 days"

  processing:
    manual_review_sla: "24 hours"
    auto_retry_after: "6 hours"
    escalation_after: "48 hours"
```

### 7.3 Idempotency Tokens
```yaml
idempotency_design:
  token_format: "{table}_{partition}_{timestamp}_{hash}"

  example: "sensor_telemetry_20250916_1694876422_a3b4c5d6"

  storage:
    location: "gs://diagnosticpro-exports/idempotency-tokens/"
    retention: "7 days"

  usage:
    - Prevent duplicate exports
    - Track export status
    - Enable safe retries
    - Audit trail
```

**Implementation Example:**
```python
import hashlib
from datetime import datetime

def generate_idempotency_token(table_name, partition, export_config):
    """Generate unique token for export operation."""
    components = [
        table_name,
        partition,
        str(int(datetime.utcnow().timestamp())),
        hashlib.md5(str(export_config).encode()).hexdigest()[:8]
    ]
    return "_".join(components)

def check_idempotency(token, storage_client):
    """Check if export already completed."""
    bucket = storage_client.bucket("diagnosticpro-exports")
    blob = bucket.blob(f"idempotency-tokens/{token}")
    return blob.exists()
```

## 8. Table Category Examples

### 8.1 Scraped Data Tables
**Reddit Diagnostic Posts**
```yaml
export_config:
  source: "diagnosticpro_prod.reddit_diagnostic_posts"
  destination: "gs://diagnosticpro-exports/prod/diagnosticpro_prod/reddit_diagnostic_posts/"
  format: "PARQUET"
  compression: "SNAPPY"
  partitioning:
    field: "created_date"
    granularity: "daily"
  schedule: "0 */6 * * *"  # Every 6 hours
  mode: "APPEND"
  validation:
    - unique_post_ids
    - subreddit_verification
    - content_length_check
```

**YouTube Repair Videos**
```yaml
export_config:
  source: "diagnosticpro_prod.youtube_repair_videos"
  destination: "gs://diagnosticpro-exports/prod/diagnosticpro_prod/youtube_videos/"
  format: "JSONL"
  compression: "GZIP"
  partitioning:
    field: "upload_date"
    granularity: "daily"
  schedule: "0 2 * * *"  # Daily at 2 AM
  mode: "APPEND"
  validation:
    - video_id_format
    - transcript_availability
    - metadata_completeness
```

### 8.2 Sensor Telemetry (High-Volume)
```yaml
export_config:
  source: "diagnosticpro_prod.sensor_telemetry"
  destination: "gs://diagnosticpro-exports/prod/diagnosticpro_prod/sensor_telemetry/"
  format: "PARQUET"
  compression: "ZSTD"
  partitioning:
    primary: "timestamp_hour"
    secondary: "equipment_id_shard"
  schedule: "continuous"  # Streaming export
  mode: "APPEND"
  optimization:
    row_group_size: "256MB"
    column_encoding: "DELTA_BINARY_PACKED"
  validation:
    - timestamp_ordering
    - sensor_value_ranges
    - equipment_id_validation
```

### 8.3 Financial Tables
```yaml
export_config:
  source: "diagnosticpro_prod.billing_transactions"
  destination: "gs://diagnosticpro-exports/prod/diagnosticpro_prod/financial/"
  format: "PARQUET"
  compression: "GZIP"
  encryption: "CMEK"  # Customer-managed encryption
  partitioning:
    field: "transaction_date"
    granularity: "monthly"
  schedule: "0 0 * * *"  # Daily at midnight
  mode: "INCREMENTAL"
  validation:
    - transaction_balance_check
    - currency_validation
    - audit_trail_completeness
  compliance:
    - PCI_DSS_compliant
    - SOX_compliant
```

### 8.4 ML Feature Store
```yaml
export_config:
  source: "diagnosticpro_prod.feature_store"
  destination: "gs://diagnosticpro-exports/prod/diagnosticpro_ml/features/"
  format: "PARQUET"
  compression: "SNAPPY"
  partitioning:
    field: "feature_timestamp"
    granularity: "hourly"
  schedule: "0 * * * *"  # Hourly
  mode: "INCREMENTAL"
  schema_evolution:
    enabled: true
    compatibility: "backward"
  validation:
    - feature_value_distributions
    - null_percentage_threshold
    - feature_version_tracking
```

### 8.5 User Data (GDPR Compliant)
```yaml
export_config:
  source: "diagnosticpro_prod.users"
  destination: "gs://diagnosticpro-exports/prod/diagnosticpro_prod/users/"
  format: "JSONL"
  compression: "GZIP"
  encryption: "CMEK"
  schedule: "0 3 * * *"  # Daily at 3 AM
  mode: "FULL_REFRESH"
  gdpr_compliance:
    anonymization:
      - email: "hash_sha256"
      - phone: "mask_except_last_4"
      - ip_address: "truncate_last_octet"
    excluded_fields:
      - "password_hash"
      - "security_questions"
  validation:
    - email_format_check
    - data_minimization_verify
    - consent_flag_check
```

## 9. Monitoring and Alerting

### 9.1 Export Metrics
```yaml
metrics:
  export_duration:
    threshold: "30 minutes"
    alert: "PagerDuty"

  export_size:
    threshold: "10GB per table"
    alert: "Email"

  failure_rate:
    threshold: "5% over 1 hour"
    alert: "Slack + PagerDuty"

  cost_per_export:
    threshold: "$10"
    alert: "Email to finance"
```

### 9.2 Dashboard Queries
```sql
-- Export success rate
SELECT
  DATE(export_timestamp) as export_date,
  table_name,
  COUNT(*) as total_exports,
  SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as successful,
  ROUND(100.0 * SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM export_logs
WHERE export_timestamp >= CURRENT_DATE - 7
GROUP BY 1, 2
ORDER BY 1 DESC, 2;

-- Data freshness monitoring
SELECT
  table_name,
  MAX(export_timestamp) as last_export,
  DATETIME_DIFF(CURRENT_DATETIME(), MAX(export_timestamp), HOUR) as hours_since_export,
  CASE
    WHEN DATETIME_DIFF(CURRENT_DATETIME(), MAX(export_timestamp), HOUR) > 24 THEN 'STALE'
    ELSE 'FRESH'
  END as freshness_status
FROM export_logs
WHERE status = 'SUCCESS'
GROUP BY table_name
HAVING freshness_status = 'STALE';
```

## 10. Cost Optimization

### 10.1 Export Cost Management
```yaml
optimization_strategies:
  compression:
    high_volume_tables: "ZSTD"  # Better compression
    low_latency_tables: "SNAPPY"  # Faster processing

  scheduling:
    off_peak_exports: "2 AM - 6 AM PST"
    cost_savings: "30% lower egress charges"

  incremental_exports:
    reduces_volume: "90% for user tables"
    reduces_cost: "85% for transaction tables"

  regional_optimization:
    same_region_transfer: "Free"
    multi_region_strategy: "Replicate only critical"
```

### 10.2 Storage Tiering
```yaml
lifecycle_policies:
  30_days:
    action: "Transition to NEARLINE"
    cost_reduction: "50%"

  90_days:
    action: "Transition to COLDLINE"
    cost_reduction: "75%"

  365_days:
    action: "Transition to ARCHIVE"
    cost_reduction: "90%"

  auto_delete:
    temp_exports: "7 days"
    failed_exports: "30 days"
    test_exports: "1 day"
```

---

**Document Metadata**
- **Last Updated:** 2025-09-16
- **Next Review:** 2025-12-16
- **Owner:** Data Engineering Team
- **Approval Status:** Production Ready

**Related Documents:**
- S1_master_schema.yaml - Master schema definitions
- S2_sla_retention.yaml - SLA and retention policies
- S4_pipeline_spec.md - Pipeline specifications (next document)

---
**Generated:** 2025-09-16