#!/usr/bin/env python3
"""
BigQuery Error Logger - Retrieve and analyze BigQuery upload errors
"""

import subprocess
import json
from datetime import datetime, timedelta
import sys

class BigQueryErrorLogger:
    def __init__(self, project_id="diagnostic-pro-start-up"):
        self.project_id = project_id
        self.errors = []
        
    def fetch_recent_errors(self, hours_back=24):
        """Fetch BigQuery errors from the last N hours"""
        print(f"Fetching BigQuery errors from the last {hours_back} hours...")
        
        # Calculate timestamp
        time_filter = (datetime.utcnow() - timedelta(hours=hours_back)).isoformat() + "Z"
        
        # Build the logging query
        query = f"""
            resource.type="bigquery_resource" 
            AND severity>=ERROR 
            AND timestamp>="{time_filter}"
        """
        
        try:
            # Execute gcloud logging read
            result = subprocess.run(
                ["gcloud", "logging", "read", query, "--limit=100", "--format=json"],
                capture_output=True,
                text=True,
                check=True
            )
            
            logs = json.loads(result.stdout)
            
            # Parse errors
            for log in logs:
                error_info = self.parse_error(log)
                if error_info:
                    self.errors.append(error_info)
                    
            return self.errors
            
        except subprocess.CalledProcessError as e:
            print(f"Error fetching logs: {e}")
            return []
    
    def parse_error(self, log_entry):
        """Parse a single log entry for error information"""
        error_info = {
            'timestamp': log_entry.get('timestamp', 'N/A'),
            'severity': log_entry.get('severity', 'N/A'),
            'resource': log_entry.get('resource', {}).get('labels', {}),
        }
        
        # Extract error message
        if 'protoPayload' in log_entry:
            proto = log_entry['protoPayload']
            error_info['method'] = proto.get('methodName', 'N/A')
            error_info['resource_name'] = proto.get('resourceName', 'N/A')
            
            if 'status' in proto and 'message' in proto['status']:
                error_info['error_message'] = proto['status']['message']
                
            # Extract SQL statement if available
            if 'metadata' in proto and 'jobChange' in proto['metadata']:
                job = proto['metadata']['jobChange'].get('job', {})
                if 'jobConfig' in job and 'queryConfig' in job['jobConfig']:
                    error_info['query'] = job['jobConfig']['queryConfig'].get('query', 'N/A')
                    
        elif 'textPayload' in log_entry:
            error_info['error_message'] = log_entry['textPayload']
            
        return error_info if 'error_message' in error_info else None
    
    def analyze_errors(self):
        """Analyze and categorize errors"""
        if not self.errors:
            print("No errors found.")
            return
            
        print(f"\nFound {len(self.errors)} errors\n")
        print("=" * 80)
        
        # Group errors by type
        error_types = {}
        for error in self.errors:
            msg = error.get('error_message', 'Unknown')
            
            # Categorize error
            if 'Syntax error' in msg:
                category = 'SQL Syntax Error'
            elif 'Access Denied' in msg:
                category = 'Permission Error'
            elif 'Unrecognized name' in msg:
                category = 'Invalid Column/Table Name'
            elif 'already exists' in msg:
                category = 'Duplicate Resource'
            else:
                category = 'Other'
                
            if category not in error_types:
                error_types[category] = []
            error_types[category].append(error)
        
        # Print categorized errors
        for category, errors in error_types.items():
            print(f"\n{category} ({len(errors)} occurrences):")
            print("-" * 40)
            
            # Show first 3 examples
            for error in errors[:3]:
                print(f"Time: {error['timestamp']}")
                print(f"Error: {error['error_message']}")
                if 'query' in error and error['query'] != 'N/A':
                    print(f"Query: {error['query'][:200]}...")
                print()
    
    def export_errors(self, filename="bigquery_errors.json"):
        """Export errors to JSON file"""
        with open(filename, 'w') as f:
            json.dump(self.errors, f, indent=2)
        print(f"Errors exported to {filename}")

def main():
    # Initialize logger
    logger = BigQueryErrorLogger()
    
    # Fetch recent errors
    errors = logger.fetch_recent_errors(hours_back=24)
    
    # Analyze errors
    logger.analyze_errors()
    
    # Export to file
    if errors:
        logger.export_errors()
        
    # Check for specific table errors
    print("\n" + "=" * 80)
    print("CHECKING FOR TABLE CREATION ERRORS:")
    print("=" * 80)
    
    # List tables that might have failed
    failed_tables = [
        'shop_operating_hours', 'shop_locations', 'location_distances',
        'exchange_rates', 'payment_processors', 'subscription_plans',
        'audit_log', 'user_activity_log', 'data_subjects'
    ]
    
    for table in failed_tables:
        table_errors = [e for e in errors if table in str(e.get('error_message', ''))]
        if table_errors:
            print(f"\n{table}: {len(table_errors)} errors")
            print(f"  Latest: {table_errors[0].get('error_message', 'N/A')}")

if __name__ == "__main__":
    main()