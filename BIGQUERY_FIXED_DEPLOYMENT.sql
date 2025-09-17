-- =====================================================
-- DIAGNOSTICPRO BIGQUERY SCHEMA - PRODUCTION READY (FIXED)
-- Version: 1.0 (Fixed for BigQuery deployment)
-- Date: 2025-08-31
-- Description: Complete BigQuery-optimized schema migration with syntax fixes
-- =====================================================

-- =====================================================
-- DATASET ORGANIZATION
-- Note: Datasets already created via BigQuery console/API
-- Removing CREATE SCHEMA statements as datasets exist
-- =====================================================

-- =====================================================
-- CORE FOUNDATION TABLES
-- =====================================================

-- Users table with nested authentication data
CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.users` (
  id STRING NOT NULL OPTIONS(description="Generated UUID"),
  email STRING NOT NULL,
  email_verified BOOL,
  email_verified_at TIMESTAMP,
  password_hash STRING NOT NULL,
  user_type STRING NOT NULL,
  
  -- Nested profile data
  profile STRUCT<
    first_name STRING,
    last_name STRING,
    phone STRING,
    avatar_url STRING,
    timezone STRING,
    language STRING,
    country STRING
  >,
  
  -- Nested authentication data
  auth STRUCT<
    mfa_enabled BOOL,
    mfa_secret STRING,
    mfa_backup_codes ARRAY<STRING>,
    failed_login_attempts INT64,
    locked_until TIMESTAMP,
    password_reset_token STRING,
    password_reset_expires TIMESTAMP
  >,
  
  -- Metadata as nested structure
  metadata STRUCT<
    source STRING,
    referral_code STRING,
    utm_campaign STRING,
    utm_source STRING,
    utm_medium STRING,
    custom_fields JSON
  >,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  last_login_at TIMESTAMP,
  is_active BOOL,
  deleted_at TIMESTAMP
)
PARTITION BY DATE(created_at)
CLUSTER BY user_type, email
OPTIONS(
  description="Core user authentication and profile data",
  partition_expiration_days=NULL,
  require_partition_filter=false
);

-- =====================================================
-- UNIVERSAL EQUIPMENT REGISTRY (OPTIMIZED)
-- =====================================================

CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.equipment_registry` (
  -- Primary identification
  id STRING NOT NULL OPTIONS(description="Generated UUID"),
  identification_primary_type STRING NOT NULL,
  identification_primary STRING NOT NULL,
  
  -- Secondary identifiers as nested array
  secondary_identifiers ARRAY<STRUCT<
    id_type STRING,
    id_value STRING,
    issuing_authority STRING,
    issue_date DATE,
    expiry_date DATE
  >>,
  
  -- Equipment details
  equipment_category STRING NOT NULL,
  
  equipment_details STRUCT<
    subcategory STRING,
    manufacturer STRING,
    brand STRING,
    model STRING,
    model_variant STRING,
    model_year INT64,
    manufacture_date DATE,
    purchase_date DATE,
    warranty_expiration DATE,
    end_of_life_date DATE
  >,
  
  -- Physical characteristics as nested structure
  physical STRUCT<
    size_classification STRING,
    weight_lbs NUMERIC,
    dimensions_inches STRUCT<
      length NUMERIC,
      width NUMERIC,
      height NUMERIC
    >,
    color STRING,
    material STRING
  >,
  
  -- Value and economics
  economics STRUCT<
    original_msrp NUMERIC,
    current_value NUMERIC,
    currency_code STRING,
    insurance_value NUMERIC,
    replacement_cost NUMERIC,
    depreciation_rate NUMERIC
  >,
  
  -- Power and energy
  power STRUCT<
    source STRING,
    voltage_primary INT64,
    amperage_max NUMERIC,
    wattage_max NUMERIC,
    battery_type STRING,
    fuel_type STRING,
    fuel_capacity_gallons NUMERIC
  >,
  
  -- Usage environment
  usage STRUCT<
    environment STRING,
    duty_cycle STRING,
    expected_lifespan_years NUMERIC,
    operating_hours NUMERIC,
    total_miles NUMERIC,
    total_cycles INT64
  >,
  
  -- Ownership
  ownership STRUCT<
    owner_type STRING,
    owner_id STRING,
    operator_id STRING,
    location_type STRING,
    location_country STRING,
    location_state STRING,
    location_city STRING,
    gps_coordinates GEOGRAPHY
  >,
  
  -- Connectivity
  connectivity ARRAY<STRING>,
  smart_features ARRAY<STRING>,
  iot_enabled BOOL,
  
  -- Compliance and certifications
  compliance STRUCT<
    regulatory ARRAY<STRING>,
    safety_certifications ARRAY<STRING>,
    recall_status BOOL,
    recall_details ARRAY<STRUCT<
      recall_id STRING,
      description STRING,
      remedy STRING,
      date_issued DATE
    >>
  >,
  
  -- Custom fields and metadata
  custom_fields JSON,
  tags ARRAY<STRING>,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  deleted_at TIMESTAMP
)
PARTITION BY DATE(created_at)
CLUSTER BY equipment_category, identification_primary_type
OPTIONS(
  description="Universal equipment registry supporting all equipment types",
  partition_expiration_days=NULL,
  require_partition_filter=false
);

-- =====================================================
-- SENSOR TELEMETRY (TIME-SERIES OPTIMIZED)
-- =====================================================

CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.sensor_telemetry` (
  -- Partition key must be first for optimal performance
  reading_date DATE NOT NULL,
  
  -- Core identifiers
  equipment_id STRING NOT NULL,
  sensor_id STRING NOT NULL,
  
  -- Reading data
  reading_timestamp TIMESTAMP NOT NULL,
  reading_value NUMERIC NOT NULL,
  reading_unit STRING,
  
  -- Sensor metadata
  sensor_type STRING,
  
  -- Quality and validation
  quality STRUCT<
    confidence_score NUMERIC,
    is_validated BOOL,
    is_anomaly BOOL,
    anomaly_score NUMERIC,
    error_code STRING
  >,
  
  -- Context
  context STRUCT<
    location GEOGRAPHY,
    weather_condition STRING,
    operating_mode STRING,
    operator_id STRING
  >,
  
  -- Processing metadata
  ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  processing_timestamp TIMESTAMP,
  batch_id STRING
)
PARTITION BY reading_date
CLUSTER BY equipment_id, sensor_type, reading_timestamp
OPTIONS(
  description="High-volume sensor telemetry data",
  partition_expiration_days=730,  -- 2 years retention
  require_partition_filter=true   -- Force partition filter for cost control
);

-- =====================================================
-- ML MODELS AND PREDICTIONS
-- =====================================================

CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.models` (
  model_id STRING NOT NULL OPTIONS(description="Generated UUID"),
  model_name STRING NOT NULL,
  model_type STRING,
  
  -- Version control
  version_info STRUCT<
    version_number STRING,
    git_commit_hash STRING,
    created_by STRING,
    created_at TIMESTAMP,
    is_production BOOL,
    is_champion BOOL
  >,
  
  -- Model details
  algorithm STRING,
  framework STRING,
  
  -- Hyperparameters as JSON for flexibility
  hyperparameters JSON,
  
  -- Feature configuration
  features STRUCT<
    input_features ARRAY<STRING>,
    target_variable STRING,
    feature_importance JSON,
    preprocessing_steps JSON
  >,
  
  -- Performance metrics
  metrics STRUCT<
    training_metrics JSON,
    validation_metrics JSON,
    test_metrics JSON,
    production_metrics JSON
  >,
  
  -- Training information
  training STRUCT<
    dataset_id STRING,
    training_start TIMESTAMP,
    training_end TIMESTAMP,
    training_duration_seconds INT64,
    training_rows INT64,
    compute_resources JSON
  >,
  
  -- Deployment
  deployment STRUCT<
    deployed_at TIMESTAMP,
    endpoint_url STRING,
    serving_framework STRING,
    auto_scaling_enabled BOOL,
    max_instances INT64,
    min_instances INT64
  >,
  
  -- Model artifacts
  artifacts STRUCT<
    model_path STRING,
    preprocessor_path STRING,
    metadata_path STRING,
    artifact_size_mb NUMERIC
  >,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(created_at)
CLUSTER BY model_type, model_name
OPTIONS(
  description="ML model registry and metadata",
  partition_expiration_days=NULL
);

-- =====================================================
-- FEATURE STORE (ML OPTIMIZED)
-- =====================================================

CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.feature_store` (
  feature_date DATE NOT NULL,
  entity_id STRING NOT NULL,
  entity_type STRING NOT NULL,
  
  -- Feature vectors as arrays for efficient storage
  numeric_features ARRAY<NUMERIC>,
  categorical_features ARRAY<STRING>,
  
  -- Feature metadata
  feature_set_name STRING NOT NULL,
  feature_set_version STRING NOT NULL,
  
  -- Feature values as nested structure
  features STRUCT<
    equipment_age_days INT64,
    total_operating_hours NUMERIC,
    avg_daily_usage_hours NUMERIC,
    failure_count_30d INT64,
    failure_count_90d INT64,
    maintenance_score NUMERIC,
    environmental_risk_score NUMERIC,
    usage_intensity_score NUMERIC
  >,
  
  -- Embeddings for similarity search
  embedding_vector ARRAY<FLOAT64>,
  
  -- Quality metrics
  data_quality STRUCT<
    completeness_score NUMERIC,
    freshness_hours INT64,
    anomaly_flags ARRAY<STRING>
  >,
  
  computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY feature_date
CLUSTER BY entity_type, entity_id
OPTIONS(
  description="ML feature store for model training and inference",
  partition_expiration_days=90
);

-- =====================================================
-- DIAGNOSTIC SESSIONS (OPTIMIZED)
-- =====================================================

CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.diagnostic_sessions` (
  session_id STRING NOT NULL OPTIONS(description="Generated UUID"),
  session_date DATE NOT NULL,
  
  -- Equipment and user
  equipment_id STRING NOT NULL,
  technician_id STRING,
  customer_id STRING,
  shop_id STRING,
  
  -- Session details
  session_type STRING,
  
  -- Symptoms and complaints as array
  symptoms ARRAY<STRUCT<
    symptom_type STRING,
    description STRING,
    severity STRING,
    frequency STRING,
    conditions STRING
  >>,
  
  -- Diagnostic codes found
  diagnostic_codes ARRAY<STRUCT<
    code STRING,
    code_type STRING,
    description STRING,
    freeze_frame_data JSON
  >>,
  
  -- Tests performed
  tests_performed ARRAY<STRUCT<
    test_name STRING,
    test_type STRING,
    result STRING,
    values JSON,
    passed BOOL
  >>,
  
  -- Findings and recommendations
  findings STRUCT<
    root_cause STRING,
    affected_systems ARRAY<STRING>,
    severity_level STRING,
    immediate_action_required BOOL
  >,
  
  recommendations ARRAY<STRUCT<
    action STRING,
    priority STRING,
    estimated_cost NUMERIC,
    estimated_hours NUMERIC,
    parts_required ARRAY<STRING>
  >>,
  
  -- Resolution
  resolution STRUCT<
    actions_taken ARRAY<STRING>,
    parts_replaced ARRAY<STRUCT<
      part_number STRING,
      part_name STRING,
      quantity INT64,
      cost NUMERIC
    >>,
    labor_hours NUMERIC,
    total_cost NUMERIC,
    warranty_covered BOOL,
    customer_satisfied BOOL
  >,
  
  -- Media attachments
  media ARRAY<STRUCT<
    media_type STRING,
    media_url STRING,
    thumbnail_url STRING,
    caption STRING
  >>,
  
  -- Timestamps
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  completed_at TIMESTAMP,
  duration_minutes INT64
)
PARTITION BY session_date
CLUSTER BY equipment_id, session_type
OPTIONS(
  description="Diagnostic session records with findings and resolutions",
  partition_expiration_days=2555  -- 7 years for compliance
);

-- =====================================================
-- PARTS INVENTORY (SUPPLY CHAIN OPTIMIZED)
-- =====================================================

CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.parts_inventory` (
  part_id STRING NOT NULL OPTIONS(description="Generated UUID"),
  part_number STRING NOT NULL,
  
  -- Part identification
  part_info STRUCT<
    manufacturer STRING,
    brand STRING,
    description STRING,
    category STRING,
    subcategory STRING,
    oem_numbers ARRAY<STRING>,
    superseded_by STRING
  >,
  
  -- Availability by location
  availability ARRAY<STRUCT<
    location_id STRING,
    location_type STRING,
    quantity_on_hand INT64,
    quantity_available INT64,
    quantity_reserved INT64,
    reorder_point INT64,
    reorder_quantity INT64,
    lead_time_days INT64
  >>,
  
  -- Suppliers
  suppliers ARRAY<STRUCT<
    supplier_id STRING,
    supplier_name STRING,
    supplier_part_number STRING,
    cost NUMERIC,
    currency STRING,
    moq INT64,
    lead_time_days INT64,
    last_order_date DATE,
    quality_score NUMERIC
  >>,
  
  -- Compatibility
  compatible_equipment ARRAY<STRING>,
  compatible_models ARRAY<STRUCT<
    make STRING,
    model STRING,
    years ARRAY<INT64>
  >>,
  
  -- Pricing
  pricing STRUCT<
    list_price NUMERIC,
    dealer_cost NUMERIC,
    core_charge NUMERIC,
    environmental_fee NUMERIC,
    currency STRING
  >,
  
  -- Specifications
  specifications STRUCT<
    weight_lbs NUMERIC,
    dimensions_inches STRUCT<
      length NUMERIC,
      width NUMERIC,
      height NUMERIC
    >,
    material STRING,
    color STRING,
    warranty_months INT64
  >,
  
  -- Performance metrics
  metrics STRUCT<
    demand_forecast_30d INT64,
    demand_forecast_90d INT64,
    turnover_rate NUMERIC,
    stockout_risk_score NUMERIC,
    obsolescence_risk_score NUMERIC
  >,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY part_number
OPTIONS(
  description="Parts inventory and supply chain management"
);

-- =====================================================
-- PREDICTIVE MAINTENANCE SCHEDULES
-- =====================================================

CREATE OR REPLACE TABLE `diagnostic-pro-start-up.repair_diagnostics.maintenance_predictions` (
  prediction_id STRING NOT NULL OPTIONS(description="Generated UUID"),
  prediction_date DATE NOT NULL,
  
  equipment_id STRING NOT NULL,
  
  -- Predictions array for multiple components
  predictions ARRAY<STRUCT<
    component_type STRING,
    failure_mode STRING,
    probability NUMERIC,
    confidence_interval STRUCT<
      lower NUMERIC,
      upper NUMERIC
    >,
    predicted_failure_date DATE,
    days_until_failure INT64,
    risk_level STRING,
    model_id STRING,
    model_version STRING
  >>,
  
  -- Recommended actions
  maintenance_actions ARRAY<STRUCT<
    action_type STRING,
    component STRING,
    priority STRING,
    recommended_date DATE,
    estimated_cost NUMERIC,
    estimated_downtime_hours NUMERIC,
    parts_needed ARRAY<STRING>,
    preventable_failure_cost NUMERIC,
    roi_ratio NUMERIC
  >>,
  
  -- Risk assessment
  risk_assessment STRUCT<
    overall_risk_score NUMERIC,
    safety_risk BOOL,
    operational_risk_level STRING,
    financial_impact NUMERIC,
    downtime_impact_hours NUMERIC
  >,
  
  -- Model metadata
  model_metadata STRUCT<
    ensemble_models ARRAY<STRING>,
    feature_importance JSON,
    explanation JSON
  >,
  
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY prediction_date
CLUSTER BY equipment_id
OPTIONS(
  description="Predictive maintenance recommendations and scheduling",
  partition_expiration_days=365
);

-- =====================================================
-- MATERIALIZED VIEWS FOR ANALYTICS
-- =====================================================

-- Daily diagnostic metrics
CREATE MATERIALIZED VIEW `diagnostic-pro-start-up.repair_diagnostics.daily_diagnostic_metrics`
PARTITION BY metric_date
CLUSTER BY equipment_category
AS
SELECT
  DATE(started_at) as metric_date,
  e.equipment_details.manufacturer,
  e.equipment_category,
  COUNT(DISTINCT ds.session_id) as total_sessions,
  COUNT(DISTINCT ds.equipment_id) as unique_equipment,
  COUNT(DISTINCT ds.technician_id) as active_technicians,
  AVG(ds.resolution.total_cost) as avg_repair_cost,
  AVG(ds.duration_minutes) as avg_duration_minutes,
  SUM(ds.resolution.total_cost) as total_revenue,
  COUNTIF(ds.resolution.warranty_covered) as warranty_repairs,
  AVG(CAST(ds.resolution.customer_satisfied AS NUMERIC)) as satisfaction_rate
FROM `diagnostic-pro-start-up.repair_diagnostics.diagnostic_sessions` ds
JOIN `diagnostic-pro-start-up.repair_diagnostics.equipment_registry` e
  ON ds.equipment_id = e.id
WHERE ds.session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY 1, 2, 3;

-- =====================================================
-- USER DEFINED FUNCTIONS (UDFs)
-- =====================================================

-- Calculate equipment age in days
CREATE OR REPLACE FUNCTION `diagnostic-pro-start-up.repair_diagnostics.calculate_equipment_age`(
  manufacture_date DATE,
  purchase_date DATE
)
RETURNS INT64
AS (
  DATE_DIFF(CURRENT_DATE(), COALESCE(manufacture_date, purchase_date), DAY)
);

-- Parse VIN to extract manufacturer
CREATE OR REPLACE FUNCTION `diagnostic-pro-start-up.repair_diagnostics.parse_vin_manufacturer`(vin STRING)
RETURNS STRING
LANGUAGE js AS r"""
  if (!vin || vin.length < 3) return null;
  const wmi = vin.substring(0, 3).toUpperCase();
  const manufacturers = {
    '1F1': 'Ford', '1F2': 'Ford', '1F3': 'Ford', '1F4': 'Ford', '1F5': 'Ford',
    '1G1': 'Chevrolet', '1G2': 'Pontiac', '1G3': 'Oldsmobile', '1G4': 'Buick',
    '1G6': 'Cadillac', '1GM': 'Pontiac', '1GC': 'Chevrolet Truck',
    '2F1': 'Ford Canada', '2G1': 'Chevrolet Canada',
    '3F1': 'Ford Mexico', '3G1': 'Chevrolet Mexico',
    'WBA': 'BMW', 'WBS': 'BMW', 'WBX': 'BMW',
    'WDB': 'Mercedes-Benz', 'WDD': 'Mercedes-Benz',
    'WAU': 'Audi', 'WVW': 'Volkswagen',
    'JHM': 'Honda', 'JT1': 'Toyota', 'JT2': 'Toyota'
  };
  return manufacturers[wmi] || 'Unknown';
""";

-- Calculate failure probability
CREATE OR REPLACE FUNCTION `diagnostic-pro-start-up.repair_diagnostics.calculate_failure_probability`(
  operating_hours NUMERIC,
  age_days INT64,
  failure_history_count INT64
)
RETURNS NUMERIC
AS (
  LEAST(1.0, 
    (CAST(operating_hours AS NUMERIC) / 10000 * 0.3) +
    (CAST(age_days AS NUMERIC) / 3650 * 0.3) +
    (CAST(failure_history_count AS NUMERIC) / 10 * 0.4)
  )
);

-- =====================================================
-- MONITORING AND OPTIMIZATION
-- =====================================================

-- Query to monitor table sizes and costs (Fixed size_bytes reference)
CREATE OR REPLACE VIEW `diagnostic-pro-start-up.repair_diagnostics.table_metrics` AS
SELECT
  table_schema as dataset,
  table_name,
  row_count,
  ROUND(total_logical_bytes / POW(10, 9), 2) as size_gb,
  ROUND(total_logical_bytes / POW(10, 9) * 5.00, 2) as monthly_storage_cost_usd,
  type,
  creation_time,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), creation_time, DAY) as age_days
FROM `diagnostic-pro-start-up.repair_diagnostics.INFORMATION_SCHEMA.TABLE_STORAGE`
WHERE table_schema = 'repair_diagnostics'
ORDER BY total_logical_bytes DESC;

-- =====================================================
-- DOCUMENTATION AND COMPLIANCE
-- =====================================================

/*
BIGQUERY DEPLOYMENT FIXES APPLIED:

1. REMOVED CREATE SCHEMA statements - BigQuery uses datasets, not schemas
   - Datasets are created via BigQuery console/API before running this script
   - All table references updated to use existing dataset: diagnostic-pro-start-up:repair_diagnostics

2. FIXED CHECK constraints - BigQuery doesn't support CHECK constraints
   - Removed all CHECK constraint syntax
   - Constraints can be enforced in application logic or data validation pipelines

3. FIXED size_bytes reference in monitoring view
   - Changed from size_bytes to total_logical_bytes (correct BigQuery column name)
   - Updated INFORMATION_SCHEMA reference to use correct dataset

4. PRESERVED all table structures
   - No tables, columns, or data types removed
   - All nested STRUCT and ARRAY structures maintained
   - All partitioning and clustering configurations preserved

5. FIXED materialized view aggregation
   - Added explicit CAST for BOOL to NUMERIC in satisfaction_rate calculation
   - BigQuery requires explicit casting for AVG() on BOOL columns

6. MAINTAINED BigQuery optimizations
   - Partitioning on date columns for cost efficiency
   - Clustering for query performance
   - Nested structures for JSON-like flexibility
   - UDFs for custom business logic

DEPLOYMENT INSTRUCTIONS:
1. Ensure dataset 'diagnostic-pro-start-up:repair_diagnostics' exists
2. Run this SQL file in BigQuery console or via bq command-line tool
3. Verify all tables and views are created successfully
4. Test sample queries to validate functionality

COST OPTIMIZATION FEATURES PRESERVED:
- Partition expiration for automatic data lifecycle management
- Required partition filters to prevent expensive full table scans
- Clustered tables for improved query performance
- Materialized views for expensive aggregation queries

ERROR FIXES SUMMARY:
- CREATE SCHEMA → Removed (use existing datasets)
- CHECK constraints → Removed (not supported in BigQuery)  
- size_bytes → total_logical_bytes (correct column name)
- BOOL aggregation → Added explicit CAST to NUMERIC
- Dataset references → Updated to use diagnostic-pro-start-up:repair_diagnostics
*/