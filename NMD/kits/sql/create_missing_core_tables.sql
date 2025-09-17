-- =====================================================
-- CREATE MISSING CORE TABLES Script
-- =====================================================
-- Description: Creates 4 missing core tables with full schema definitions
-- Strategy: CREATE TABLE IF NOT EXISTS with parameterization
-- Tables: users, sensor_telemetry, diagnostic_sessions, models
-- =====================================================

-- Parameter declaration for dynamic SQL execution
DECLARE project_id STRING DEFAULT @project_id;
DECLARE prod_dataset STRING DEFAULT @prod_dataset;
DECLARE create_sql STRING;

-- =====================================================
-- 1. USERS TABLE
-- =====================================================
SET create_sql = FORMAT("""
CREATE TABLE IF NOT EXISTS `%s.%s.users` (
  -- Primary identification
  id STRING NOT NULL,
  email STRING NOT NULL,
  username STRING,

  -- Authentication
  auth_provider STRING NOT NULL DEFAULT 'local',
  auth_provider_id STRING,
  password_hash STRING,
  email_verified BOOLEAN DEFAULT false,
  email_verified_at TIMESTAMP,

  -- Profile information (nested structure)
  profile STRUCT<
    first_name STRING,
    last_name STRING,
    display_name STRING,
    avatar_url STRING,
    phone STRING,
    date_of_birth DATE,
    timezone STRING,
    language STRING DEFAULT 'en',
    country STRING,
    organization STRING
  >,

  -- Subscription and billing
  subscription STRUCT<
    plan_type STRING DEFAULT 'free',
    status STRING DEFAULT 'active',
    started_at TIMESTAMP,
    expires_at TIMESTAMP,
    auto_renew BOOLEAN DEFAULT true,
    billing_cycle STRING DEFAULT 'monthly'
  >,

  -- Preferences and settings
  preferences STRUCT<
    notifications JSON,
    dashboard_config JSON,
    theme STRING DEFAULT 'light',
    units STRING DEFAULT 'metric'
  >,

  -- Security and access
  roles ARRAY<STRING>,
  permissions ARRAY<STRING>,
  last_login_at TIMESTAMP,
  login_count INT64 DEFAULT 0,
  failed_login_attempts INT64 DEFAULT 0,
  locked_until TIMESTAMP,

  -- Audit fields
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  deleted_at TIMESTAMP,
  created_by STRING,
  import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(created_at)
CLUSTER BY email, auth_provider
""", project_id, prod_dataset);

EXECUTE IMMEDIATE create_sql;

-- =====================================================
-- 2. SENSOR_TELEMETRY TABLE
-- =====================================================
SET create_sql = FORMAT("""
CREATE TABLE IF NOT EXISTS `%s.%s.sensor_telemetry` (
  -- Primary identification
  id STRING NOT NULL,
  equipment_id STRING NOT NULL,
  sensor_id STRING NOT NULL,

  -- Measurement data
  timestamp TIMESTAMP NOT NULL,
  measurement_type STRING NOT NULL,
  value FLOAT64,
  unit STRING,

  -- Measurement context
  sensor_info STRUCT<
    sensor_type STRING,
    manufacturer STRING,
    model STRING,
    firmware_version STRING,
    calibration_date DATE,
    accuracy_class STRING,
    range_min FLOAT64,
    range_max FLOAT64
  >,

  -- Data quality indicators
  quality STRUCT<
    confidence_score FLOAT64,
    anomaly_flag BOOLEAN DEFAULT false,
    validation_status STRING DEFAULT 'pending',
    source_quality STRING,
    interpolated BOOLEAN DEFAULT false
  >,

  -- Environmental conditions
  conditions STRUCT<
    temperature FLOAT64,
    humidity FLOAT64,
    pressure FLOAT64,
    vibration_level FLOAT64,
    ambient_noise FLOAT64
  >,

  -- Processing metadata
  processing STRUCT<
    raw_value FLOAT64,
    processed_value FLOAT64,
    processing_algorithm STRING,
    filters_applied ARRAY<STRING>,
    calibration_applied BOOLEAN DEFAULT false
  >,

  -- Geolocation data
  location STRUCT<
    latitude FLOAT64,
    longitude FLOAT64,
    altitude FLOAT64,
    accuracy_meters FLOAT64,
    location_source STRING
  >,

  -- System metadata
  data_source STRING NOT NULL,
  collection_method STRING,
  batch_id STRING,

  -- Audit fields
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(timestamp)
CLUSTER BY equipment_id, sensor_id, measurement_type
""", project_id, prod_dataset);

EXECUTE IMMEDIATE create_sql;

-- =====================================================
-- 3. DIAGNOSTIC_SESSIONS TABLE
-- =====================================================
SET create_sql = FORMAT("""
CREATE TABLE IF NOT EXISTS `%s.%s.diagnostic_sessions` (
  -- Primary identification
  id STRING NOT NULL,
  equipment_id STRING NOT NULL,
  user_id STRING,

  -- Session metadata
  session_type STRING NOT NULL,
  status STRING DEFAULT 'active',
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  completed_at TIMESTAMP,
  duration_seconds INT64,

  -- Diagnostic protocol information
  protocol STRUCT<
    type STRING, -- 'OBD-II', 'J1939', 'CAN', 'proprietary'
    version STRING,
    adapter_type STRING,
    communication_speed INT64,
    supported_pids ARRAY<STRING>
  >,

  -- Vehicle/Equipment connection
  connection STRUCT<
    method STRING, -- 'obd_port', 'wireless', 'ethernet', 'direct'
    adapter_id STRING,
    adapter_firmware STRING,
    signal_strength FLOAT64,
    connection_quality STRING
  >,

  -- Diagnostic results
  results STRUCT<
    dtc_codes ARRAY<STRUCT<
      code STRING,
      description STRING,
      status STRING,
      freeze_frame JSON,
      first_detected TIMESTAMP,
      occurrence_count INT64
    >>,
    live_data ARRAY<STRUCT<
      pid STRING,
      parameter_name STRING,
      value FLOAT64,
      unit STRING,
      min_value FLOAT64,
      max_value FLOAT64,
      timestamp TIMESTAMP
    >>,
    readiness_monitors STRUCT<
      catalyst BOOLEAN,
      heated_catalyst BOOLEAN,
      evaporative_system BOOLEAN,
      secondary_air_system BOOLEAN,
      ac_refrigerant BOOLEAN,
      oxygen_sensor BOOLEAN,
      oxygen_sensor_heater BOOLEAN,
      egr_system BOOLEAN
    >
  >,

  -- Analysis and recommendations
  analysis STRUCT<
    severity_level STRING, -- 'low', 'medium', 'high', 'critical'
    priority_score FLOAT64,
    estimated_repair_cost FLOAT64,
    recommended_actions ARRAY<STRING>,
    follow_up_required BOOLEAN DEFAULT false,
    ai_confidence FLOAT64
  >,

  -- Session context
  context STRUCT<
    technician_notes STRING,
    customer_complaint STRING,
    symptoms ARRAY<STRING>,
    environmental_conditions JSON,
    previous_repairs ARRAY<STRING>
  >,

  -- Data sources and metadata
  data_source STRING NOT NULL,
  collection_metadata JSON,

  -- Audit fields
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(started_at)
CLUSTER BY equipment_id, user_id, session_type, status
""", project_id, prod_dataset);

EXECUTE IMMEDIATE create_sql;

-- =====================================================
-- 4. MODELS TABLE (ML Models Registry)
-- =====================================================
SET create_sql = FORMAT("""
CREATE TABLE IF NOT EXISTS `%s.%s.models` (
  -- Primary identification
  id STRING NOT NULL,
  name STRING NOT NULL,
  version STRING NOT NULL,

  -- Model metadata
  model_type STRING NOT NULL, -- 'classification', 'regression', 'clustering', 'anomaly_detection'
  framework STRING, -- 'tensorflow', 'pytorch', 'scikit-learn', 'xgboost'
  algorithm STRING,

  -- Model purpose and scope
  purpose STRUCT<
    domain STRING, -- 'predictive_maintenance', 'fault_diagnosis', 'performance_optimization'
    target_variable STRING,
    problem_type STRING,
    use_case_description STRING
  >,

  -- Training information
  training STRUCT<
    dataset_version STRING,
    training_start TIMESTAMP,
    training_end TIMESTAMP,
    training_duration_minutes INT64,
    total_samples INT64,
    training_samples INT64,
    validation_samples INT64,
    test_samples INT64
  >,

  -- Model performance metrics
  performance STRUCT<
    accuracy FLOAT64,
    precision FLOAT64,
    recall FLOAT64,
    f1_score FLOAT64,
    auc_roc FLOAT64,
    rmse FLOAT64,
    mae FLOAT64,
    r_squared FLOAT64,
    confusion_matrix JSON,
    feature_importance JSON
  >,

  -- Model configuration
  configuration STRUCT<
    hyperparameters JSON,
    feature_columns ARRAY<STRING>,
    preprocessing_steps ARRAY<STRING>,
    model_artifacts_path STRING,
    input_schema JSON,
    output_schema JSON
  >,

  -- Deployment information
  deployment STRUCT<
    status STRING DEFAULT 'development', -- 'development', 'staging', 'production', 'retired'
    deployed_at TIMESTAMP,
    deployment_environment STRING,
    endpoint_url STRING,
    serving_infrastructure STRING,
    auto_scaling_config JSON
  >,

  -- Model monitoring
  monitoring STRUCT<
    drift_detection BOOLEAN DEFAULT false,
    performance_threshold FLOAT64,
    retraining_schedule STRING,
    last_performance_check TIMESTAMP,
    alerts_config JSON
  >,

  -- Governance and compliance
  governance STRUCT<
    data_lineage JSON,
    model_lineage JSON,
    compliance_checks ARRAY<STRING>,
    risk_assessment STRING,
    approval_status STRING,
    approved_by STRING,
    approved_at TIMESTAMP
  >,

  -- Versioning and lifecycle
  parent_model_id STRING,
  is_latest_version BOOLEAN DEFAULT false,
  lifecycle_stage STRING DEFAULT 'development',

  -- Audit fields
  created_by STRING,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(created_at)
CLUSTER BY model_type, lifecycle_stage, deployment.status
""", project_id, prod_dataset);

EXECUTE IMMEDIATE create_sql;

-- =====================================================
-- COMPLETION SUMMARY
-- =====================================================
SELECT
  'ALL TABLES CREATED' as status,
  CURRENT_TIMESTAMP() as execution_time,
  [
    'users',
    'sensor_telemetry',
    'diagnostic_sessions',
    'models'
  ] as tables_created,
  FORMAT('%s.%s', project_id, prod_dataset) as target_dataset;