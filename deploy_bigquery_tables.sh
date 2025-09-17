#!/bin/bash

# BigQuery Table Deployment Script
# Deploys tables one by one with error handling

PROJECT="diagnostic-pro-start-up"
DATASET="repair_diagnostics"
SQL_FILE="/home/jeremy/projects/schema/BIGQUERY_FIXED_DEPLOYMENT.sql"

echo "Starting BigQuery table deployment..."
echo "Dataset: $PROJECT:$DATASET"
echo "================================"

# Extract and deploy each CREATE TABLE statement
awk '/^CREATE OR REPLACE TABLE/{flag=1} flag{print} /;\s*$/{if(flag) exit}' "$SQL_FILE" | while IFS= read -r line; do
    if [[ $line == "CREATE OR REPLACE TABLE"* ]]; then
        # Extract table name
        TABLE_NAME=$(echo "$line" | grep -oP '`[^`]+\.([^`]+)`' | sed 's/.*\.//' | sed 's/`//g')
        echo "Deploying table: $TABLE_NAME"
        
        # Create temp file with single table
        TEMP_FILE="/tmp/${TABLE_NAME}.sql"
        
        # Extract full CREATE statement for this table
        awk "/CREATE OR REPLACE TABLE.*$TABLE_NAME/,/^OPTIONS\([^)]*\);$|^;$/" "$SQL_FILE" > "$TEMP_FILE"
        
        # Deploy via VM
        gcloud compute scp "$TEMP_FILE" repair-db-access:/tmp/ --zone=us-west1-b 2>/dev/null
        
        # Execute the CREATE statement
        gcloud compute ssh repair-db-access --zone=us-west1-b --command="bq query --use_legacy_sql=false --format=none < /tmp/${TABLE_NAME}.sql" 2>&1 | grep -E "ERROR|error|successfully" || echo "Table $TABLE_NAME created"
        
        sleep 1
    fi
done

echo "================================"
echo "Deployment complete. Checking tables..."

# List all tables in dataset
gcloud compute ssh repair-db-access --zone=us-west1-b --command="bq ls --format=json $PROJECT:$DATASET | python3 -c \"import sys, json; tables = json.load(sys.stdin); print(f'Total tables created: {len(tables)}'); [print(f\"  - {t['tableReference']['tableId']}\") for t in tables[:10]]\"" 2>&1 | grep -v "External IP"

echo "================================"
echo "Deployment finished!"