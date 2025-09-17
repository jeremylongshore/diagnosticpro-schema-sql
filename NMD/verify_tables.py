import csv
import json
import re

# Read the full table list
with open('/home/jeremy/projects/diagnostic-platform/diag-schema-sql/diagnosticpro_prod_all_tables.txt', 'r') as f:
    all_tables = [line.strip() for line in f if line.strip()]

# Read the row counts file
row_counts = {}
with open('/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD/S1_row_counts_LIVE.csv', 'r') as f:
    csv_reader = csv.DictReader(f)
    for row in csv_reader:
        row_counts[row['table_name']] = row['row_count']

# Define categories and helpers
def categorize_table(table_name):
    auth_tables = ['users', 'roles', 'permissions', 'user_roles', 'user_permissions', 'login_attempts', 'auth_audit_log']
    audit_tables = ['audit_log', 'audit_events', 'security_logs', 'user_activity_log']
    reference_tables = [
        'countries', 'states', 'cities', 'vehicle_makes', 'vehicle_models',
        'vehicle_model_years', 'equipment_registry', 'parts_catalog'
    ]
    transaction_tables = [
        'appointments', 'diagnostic_sessions', 'work_orders', 'invoices',
        'payments', 'diagnostic_reports', 'fleet_maintenance'
    ]

    if table_name in auth_tables:
        return 'auth'
    elif table_name in audit_tables:
        return 'audit'
    elif table_name in reference_tables:
        return 'reference'
    elif table_name in transaction_tables:
        return 'transaction'
    else:
        return 'utility'

def suggest_primary_key(table_name):
    # Common patterns for primary keys
    pk_patterns = {
        r'_id$': 'id',
        r'^(id|uuid|guid)_': 'id',
        r'_code$': 'code',
        r'_key$': 'key'
    }

    for pattern, pk_type in pk_patterns.items():
        if re.search(pattern, table_name):
            return f"{table_name}_{pk_type}"

    # Generic fallbacks
    return f"{table_name}_id"

def determine_partition_strategy(table_name):
    time_based_tables = [
        'audit_log', 'diagnostic_sessions', 'user_activity_log',
        'appointments', 'payments', 'work_orders'
    ]

    if table_name in time_based_tables:
        return {
            'has_partition': 'proposed',
            'partition_column': 'created_at',
            'partition_type': 'TIMESTAMP'
        }

    return {
        'has_partition': 'N',
        'partition_column': '',
        'partition_type': ''
    }

def determine_sla_category(table_name):
    real_time_tables = [
        'diagnostic_sessions', 'user_activity_log',
        'appointments', 'work_orders', 'live_data_streams'
    ]
    hourly_tables = [
        'sensor_telemetry', 'vehicle_service_history',
        'performance_logs', 'error_logs'
    ]
    daily_tables = [
        'audit_log', 'billing_cycles', 'invoices',
        'payments', 'fleet_maintenance'
    ]

    if table_name in real_time_tables:
        return 'real-time'
    elif table_name in hourly_tables:
        return 'hourly'
    elif table_name in daily_tables:
        return 'daily'
    else:
        return 'weekly'

# Prepare output CSV
output_rows = []
for table_name in all_tables:
    # Determine row count
    row_count = row_counts.get(table_name, 'unknown')

    # Categorize table
    table_category = categorize_table(table_name)

    # Suggest PK
    pk_suggestion = suggest_primary_key(table_name)

    # Determine partition strategy
    partition_details = determine_partition_strategy(table_name)

    # Determine SLA category
    sla_category = determine_sla_category(table_name)

    output_rows.append({
        'table_name': table_name,
        'has_pk': 'proposed',
        'pk_column(s)': pk_suggestion,
        'has_partition': partition_details['has_partition'],
        'partition_column': partition_details['partition_column'],
        'partition_type': partition_details['partition_type'],
        'has_clustering': 'proposed',
        'cluster_columns': f"{pk_suggestion}, created_at",
        'sla_category': sla_category,
        'row_count': row_count,
        'table_exists_in_prod': 'Y',  # Assuming all exist based on the full tables list
        'table_category': table_category
    })

# Write to CSV
output_file = '/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD/S2b_coverage.csv'
with open(output_file, 'w', newline='') as f:
    fieldnames = [
        'table_name', 'has_pk', 'pk_column(s)',
        'has_partition', 'partition_column', 'partition_type',
        'has_clustering', 'cluster_columns',
        'sla_category', 'row_count',
        'table_exists_in_prod', 'table_category'
    ]
    writer = csv.DictWriter(f, fieldnames=fieldnames)

    writer.writeheader()
    for row in output_rows:
        writer.writerow(row)

# Create summary
summary = {
    'total_tables': len(output_rows),
    'tables_with_row_count': sum(1 for row in output_rows if row['row_count'] != 'unknown'),
    'table_categories': {},
    'sla_categories': {}
}

for row in output_rows:
    # Count table categories
    category = row['table_category']
    summary['table_categories'][category] = summary['table_categories'].get(category, 0) + 1

    # Count SLA categories
    sla = row['sla_category']
    summary['sla_categories'][sla] = summary['sla_categories'].get(sla, 0) + 1

# Write summary to a text file
with open('/home/jeremy/projects/diagnostic-platform/diag-schema-sql/NMD/S2b_coverage_summary.txt', 'w') as f:
    f.write("BigQuery Table Coverage Analysis Summary\n")
    f.write("=======================================\n\n")
    f.write(f"Total Tables Analyzed: {summary['total_tables']}\n")
    f.write(f"Tables with Verified Row Counts: {summary['tables_with_row_count']}\n\n")

    f.write("Table Categories:\n")
    for category, count in summary['table_categories'].items():
        f.write(f"- {category.capitalize()}: {count}\n")

    f.write("\nSLA Categories:\n")
    for category, count in summary['sla_categories'].items():
        f.write(f"- {category.capitalize()}: {count}\n")

print("Analysis complete. Check S2b_coverage.csv and S2b_coverage_summary.txt")