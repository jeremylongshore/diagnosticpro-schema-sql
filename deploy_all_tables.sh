#!/bin/bash

# BigQuery Table Deployment Script - Deploy All Tables
# Junior Developer: Deploying fixed schema to BigQuery

echo "=========================================="
echo "BigQuery Table Deployment"
echo "Project: diagnostic-pro-start-up"
echo "Dataset: repair_diagnostics"
echo "=========================================="

# Copy fixed SQL to VM
echo "Copying fixed SQL to VM..."
gcloud compute scp /home/jeremy/projects/schema/BIGQUERY_FIXED_DEPLOYMENT.sql repair-db-access:/tmp/ --zone=us-west1-b 2>/dev/null

# Deploy all tables at once
echo "Deploying all tables to BigQuery..."
gcloud compute ssh repair-db-access --zone=us-west1-b --command="
  echo 'Starting deployment...'
  bq query --use_legacy_sql=false --max_rows=0 < /tmp/BIGQUERY_FIXED_DEPLOYMENT.sql 2>&1 | head -50
" 2>&1 | grep -v "External IP"

# Check deployment status
echo ""
echo "Checking deployment status..."
gcloud compute ssh repair-db-access --zone=us-west1-b --command="
  echo 'Tables in dataset:'
  bq ls diagnostic-pro-start-up:repair_diagnostics | head -20
" 2>&1 | grep -v "External IP"

echo "=========================================="
echo "Deployment complete!"