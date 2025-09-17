# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **BigQuery Schema Management** project for DiagnosticPro's repair platform data warehouse. It serves as the gateway for all data flowing into BigQuery, handling schema definitions, validation, and import pipelines for 266+ production tables.

**Critical:** This project is exclusively for BigQuery operations and data validation. It does NOT handle web scraping, data collection, or external API calls - that's handled by the separate scraper project.

## Key Commands

### BigQuery Operations
```bash
# List all BigQuery datasets
bq ls

# List tables in production dataset (266+ tables)
bq ls diagnosticpro_prod

# Query production data
bq query --use_legacy_sql=false "SELECT * FROM \`diagnostic-pro-start-up.diagnosticpro_prod.users\` LIMIT 10"

# Load data from NDJSON file
bq load --source_format=NEWLINE_DELIMITED_JSON \
  diagnosticpro_prod.table_name \
  path/to/data.ndjson \
  schema.json
```

### Data Import Pipeline
```bash
# Run the main import pipeline
./bigquery_import_pipeline.sh

# Import with schema validation
./bigquery_import_with_schemas.sh

# Deploy tables to BigQuery
./deploy_bigquery_tables.sh

# Check import errors
python3 bigquery_error_logger.py
```

### Pipeline Directory Management
```bash
# Check pipeline status
ls -la datapipeline_import/*/

# Move data to pending
cp data.ndjson datapipeline_import/pending/

# Check for failed imports
ls -la datapipeline_import/failed/
```

## High-Level Architecture

### BigQuery Datasets Structure
```
diagnostic-pro-start-up (GCP Project)
├── diagnosticpro_prod       # Main production dataset (266+ tables)
├── diagnosticpro_analytics  # Analytics and reporting
├── diagnosticpro_staging    # Staging environment
├── diagnosticpro_ml         # Machine learning features
├── diagnosticpro_archive    # Historical data archive
└── repair_diagnostics       # Specialized repair data
```

### Data Flow Architecture
```
External Data Sources
         ↓
Scraper Project (export_gateway)
         ↓
datapipeline_import/pending/     [This Project - Entry Point]
         ↓
    Validation Layer
    ↙          ↘
validated/    failed/
    ↓
BigQuery Upload
    ↓
imported/
```

### Core Table Systems

The 266+ production tables are organized into these systems:

1. **Authentication & Users** - User management, sessions, permissions
2. **Universal Equipment Registry** - Tracking all equipment types (vehicles, electronics, machinery)
3. **Diagnostic Protocols** - OBD-II, J1939, proprietary protocols
4. **Billing & Payments** - Subscriptions, invoices, transactions
5. **Communication** - Messages, notifications, support tickets
6. **ML Infrastructure** - Predictions, features, training data
7. **Multimedia Storage** - Images, videos, waveforms
8. **Operational Metrics** - Analytics, telemetry, performance

### Key Integration Points

- **Data Entry**: `datapipeline_import/pending/` - All data enters here
- **Validation**: Schema validation against BigQuery table definitions
- **BigQuery Project**: `diagnostic-pro-start-up`
- **Primary Dataset**: `diagnosticpro_prod`
- **Schema Files**: JSON schema definitions for each table type

### Directory Structure
```
schema/
├── datapipeline_import/        # Active data pipeline
│   ├── pending/               # Data awaiting validation
│   ├── validated/             # Passed validation
│   ├── failed/                # Failed validation with logs
│   └── imported/              # Successfully imported
├── *.sh                       # Import and deployment scripts
├── bigquery_error_logger.py   # Error tracking utility
├── *_schema.json              # Table schema definitions
└── ARCHIVE_*/                 # Historical reference (not active)
```

## Critical Rules

1. **Never add scraping or data collection code** - This project only receives and validates data
2. **All data enters through datapipeline_import/** - No direct BigQuery writes
3. **Validate before importing** - Never load unvalidated data
4. **Schema ownership** - This project owns all BigQuery schema definitions
5. **Use existing scripts** - Prefer shell scripts over creating new Python scripts

## Environment Setup

Copy `.env.template` to `.env` and configure if needed. The project primarily uses:
- Google Cloud SDK (`gcloud`, `bq` commands)
- Project ID: `diagnostic-pro-start-up`
- Default dataset: `diagnosticpro_prod`