"""
S4 Pydantic Models Package
Comprehensive Pydantic v2 models for DiagnosticPro platform data validation.

This package provides enterprise-grade data validation models with:
- Comprehensive field validation using regex patterns
- Business rule enforcement through custom validators
- Nested data structures with proper validation
- Type safety and serialization support
- Performance optimized for high-throughput operations

Generated from:
- S2b_table_contracts_full.yaml
- S2_quality_rules.yaml

Models included:
- Equipment Registry: Universal equipment tracking
- Users: Authentication and profile management
- Diagnostic Sessions: Session tracking and business rules
- Sensor Telemetry: IoT sensor data with time-series validation
- Parts Inventory: Inventory management with business rules
- Maintenance Predictions: Predictive maintenance with risk assessment
- DTC Codes GitHub: Diagnostic trouble codes from GitHub
- Reddit Diagnostic Posts: Reddit posts with diagnostic information
- YouTube Repair Videos: YouTube video content validation
- Models: ML model registry and metadata
- Feature Store: ML feature storage and versioning
"""

from .equipment_registry_model import (
    EquipmentRegistry,
    EquipmentRegistryCreate,
    EquipmentRegistryUpdate,
    EquipmentRegistryResponse,
    EquipmentRegistrySummary,
    Specifications,
    Location,
    EquipmentCategory,
    VehicleType,
    IdentificationType,
)

from .users_model import (
    Users,
    UsersCreate,
    UsersUpdate,
    UsersResponse,
    UsersPasswordChange,
    UsersLogin,
    UsersLoginResponse,
    Profile,
    AuthSecurity,
    Preferences,
    UserType,
)

from .diagnostic_sessions_model import (
    DiagnosticSessions,
    DiagnosticSessionsCreate,
    DiagnosticSessionsUpdate,
    DiagnosticSessionsResponse,
    DiagnosticSessionsSummary,
    DiagnosticCode,
    Resolution,
    SessionMetrics,
    SessionType,
    SessionStatus,
    PriorityLevel,
)

# Note: sensor_telemetry_model needs to be recreated
# from .sensor_telemetry_model import (
#     SensorTelemetry,
#     SensorTelemetryCreate,
#     SensorTelemetryBatch,
#     SensorTelemetryAggregated,
#     SensorTelemetryResponse,
#     SensorTelemetrySummary,
#     QualityMetrics,
#     SensorMetadata,
#     ReadingContext,
#     ReadingQuality,
#     SensorType,
#     UnitOfMeasurement,
# )

from .parts_inventory_model import (
    PartsInventory,
    PartsInventoryCreate,
    PartsInventoryUpdate,
    PartsInventoryResponse,
    PartsInventorySummary,
    PartsInventorySearch,
    PricingInfo,
    SpecificationsInfo,
    CompatibilityInfo,
    InventoryInfo,
    SupplierInfo,
    AvailabilityStatus,
    PartCategory,
    PartCondition,
    UnitOfMeasure,
)

from .maintenance_predictions_model import (
    MaintenancePredictions,
    MaintenancePredictionsCreate,
    MaintenancePredictionsUpdate,
    MaintenancePredictionsResponse,
    MaintenancePredictionsSummary,
    MaintenancePredictionsAcknowledge,
    RiskAssessment,
    PredictionModel,
    MaintenanceRecommendation,
    RiskLevel,
    PredictionType,
    MaintenanceAction,
    PredictionStatus,
)

# from .dtc_codes_github_model import (
#     DTCCodesGithub,
#     DTCCodesGithubCreate,
#     DTCCodesGithubUpdate,
#     DTCCodesGithubResponse,
#     DTCCodesGithubBatch,
#     DTCCodesGithubSummary,
#     DTCCodesGithubSearch,
#     SourceInfo,
#     ExtractionMetadata,
#     ValidationInfo,
#     DTCCategory,
#     SourceType,
#     QualityScore,
# )

from .reddit_diagnostic_posts_model import (
    RedditDiagnosticPosts,
    RedditDiagnosticPostsCreate,
    RedditDiagnosticPostsUpdate,
    RedditDiagnosticPostsResponse,
    RedditDiagnosticPostsSummary,
    RedditDiagnosticPostsSearch,
    EquipmentInfo,
    RepairInfo,
    PostMetrics,
    ExtractionInfo,
    PostStatus,
    Sentiment,
    SolutionStatus,
)

# from .youtube_repair_videos_model import (
#     YouTubeRepairVideos,
#     YouTubeRepairVideosCreate,
#     YouTubeRepairVideosUpdate,
#     YouTubeRepairVideosResponse,
#     YouTubeRepairVideosSummary,
#     YouTubeRepairVideosBatch,
#     YouTubeRepairVideosSearch,
#     ChannelInfo,
#     VideoMetrics,
#     TechnicalInfo,
#     ContentAnalysis,
#     VideoCategory,
#     QualityRating,
#     Language,
#     VideoStatus,
# )

from .models_model import (
    Models,
    ModelsCreate,
    ModelsUpdate,
    ModelsResponse,
    ModelsSummary,
    ModelsSearch,
    ModelsPromote,
    VersionInfo,
    TrainingInfo,
    PerformanceMetrics,
    DeploymentInfo,
    AlgorithmType,
    Framework,
    ModelType,
    ModelStatus,
    MetricType,
)

from .feature_store_model import (
    FeatureStore,
    FeatureStoreCreate,
    FeatureStoreUpdate,
    FeatureStoreResponse,
    FeatureStoreBatch,
    FeatureStoreSummary,
    FeatureStoreSearch,
    FeatureSetMetadata,
    DataQuality,
    FeatureMetadata,
    StatisticalProfile,
    EntityType,
    FeatureDataType,
    AggregationMethod,
    FeatureStatus,
)

# Version information
__version__ = "2.0.0"
__generated_from__ = [
    "S2b_table_contracts_full.yaml",
    "S2_quality_rules.yaml"
]
__generation_date__ = "2025-09-16"

# All model classes for easy importing
__all__ = [
    # Equipment Registry
    "EquipmentRegistry",
    "EquipmentRegistryCreate",
    "EquipmentRegistryUpdate",
    "EquipmentRegistryResponse",
    "EquipmentDetails",
    "PhysicalSpecs",
    "Economics",
    "PowerSpecs",
    "Ownership",
    "EquipmentCategory",
    "IdentificationType",

    # Users
    "Users",
    "UsersCreate",
    "UsersUpdate",
    "UsersResponse",
    "UsersPasswordChange",
    "UsersLogin",
    "UsersLoginResponse",
    "Profile",
    "AuthSecurity",
    "Preferences",
    "UserType",

    # Diagnostic Sessions
    "DiagnosticSessions",
    "DiagnosticSessionsCreate",
    "DiagnosticSessionsUpdate",
    "DiagnosticSessionsResponse",
    "DiagnosticSessionsSummary",
    "DiagnosticCode",
    "Resolution",
    "SessionMetrics",
    "SessionType",
    "SessionStatus",
    "PriorityLevel",

    # Sensor Telemetry
    "SensorTelemetry",
    "SensorTelemetryCreate",
    "SensorTelemetryBatch",
    "SensorTelemetryAggregated",
    "SensorTelemetryResponse",
    "SensorTelemetrySummary",
    "QualityMetrics",
    "SensorMetadata",
    "ReadingContext",
    "ReadingQuality",
    "SensorType",
    "UnitOfMeasurement",

    # Parts Inventory
    "PartsInventory",
    "PartsInventoryCreate",
    "PartsInventoryUpdate",
    "PartsInventoryResponse",
    "PartsInventorySummary",
    "PartsInventorySearch",
    "PricingInfo",
    "SpecificationsInfo",
    "CompatibilityInfo",
    "InventoryInfo",
    "SupplierInfo",
    "AvailabilityStatus",
    "PartCategory",
    "PartCondition",
    "UnitOfMeasure",

    # Maintenance Predictions
    "MaintenancePredictions",
    "MaintenancePredictionsCreate",
    "MaintenancePredictionsUpdate",
    "MaintenancePredictionsResponse",
    "MaintenancePredictionsSummary",
    "MaintenancePredictionsAcknowledge",
    "RiskAssessment",
    "PredictionModel",
    "MaintenanceRecommendation",
    "RiskLevel",
    "PredictionType",
    "MaintenanceAction",
    "PredictionStatus",

    # DTC Codes GitHub
    "DTCCodesGithub",
    "DTCCodesGithubCreate",
    "DTCCodesGithubUpdate",
    "DTCCodesGithubResponse",
    "DTCCodesGithubBatch",
    "DTCCodesGithubSummary",
    "DTCCodesGithubSearch",
    "SourceInfo",
    "ExtractionMetadata",
    "ValidationInfo",
    "DTCCategory",
    "SourceType",
    "QualityScore",

    # Reddit Diagnostic Posts
    "RedditDiagnosticPosts",
    "RedditDiagnosticPostsCreate",
    "RedditDiagnosticPostsUpdate",
    "RedditDiagnosticPostsResponse",
    "RedditDiagnosticPostsSummary",
    "RedditDiagnosticPostsSearch",
    "EquipmentInfo",
    "RepairInfo",
    "PostMetrics",
    "ExtractionInfo",
    "PostStatus",
    "Sentiment",
    "SolutionStatus",

    # YouTube Repair Videos
    "YouTubeRepairVideos",
    "YouTubeRepairVideosCreate",
    "YouTubeRepairVideosUpdate",
    "YouTubeRepairVideosResponse",
    "YouTubeRepairVideosSummary",
    "YouTubeRepairVideosBatch",
    "YouTubeRepairVideosSearch",
    "ChannelInfo",
    "VideoMetrics",
    "TechnicalInfo",
    "ContentAnalysis",
    "VideoCategory",
    "QualityRating",
    "Language",
    "VideoStatus",

    # Models
    "Models",
    "ModelsCreate",
    "ModelsUpdate",
    "ModelsResponse",
    "ModelsSummary",
    "ModelsSearch",
    "ModelsPromote",
    "VersionInfo",
    "TrainingInfo",
    "PerformanceMetrics",
    "DeploymentInfo",
    "AlgorithmType",
    "Framework",
    "ModelType",
    "ModelStatus",
    "MetricType",

    # Feature Store
    "FeatureStore",
    "FeatureStoreCreate",
    "FeatureStoreUpdate",
    "FeatureStoreResponse",
    "FeatureStoreBatch",
    "FeatureStoreSummary",
    "FeatureStoreSearch",
    "FeatureSetMetadata",
    "DataQuality",
    "FeatureMetadata",
    "StatisticalProfile",
    "EntityType",
    "FeatureDataType",
    "AggregationMethod",
    "FeatureStatus",
]

# Model registry for dynamic access
MODEL_REGISTRY = {
    # Core models
    "equipment_registry": EquipmentRegistry,
    "users": Users,
    "diagnostic_sessions": DiagnosticSessions,
    # # "sensor_telemetry": SensorTelemetry,  # Missing file
    "parts_inventory": PartsInventory,
    "maintenance_predictions": MaintenancePredictions,

    # Data models
    # # "dtc_codes_github": DTCCodesGithub,  # Missing file
    "reddit_diagnostic_posts": RedditDiagnosticPosts,
    # # "youtube_repair_videos": YouTubeRepairVideos,  # Missing file

    # ML models
    "models": Models,
    "feature_store": FeatureStore,
}

# Create models for API operations
CREATE_MODELS = {
    "equipment_registry": EquipmentRegistryCreate,
    "users": UsersCreate,
    "diagnostic_sessions": DiagnosticSessionsCreate,
    # # "sensor_telemetry": SensorTelemetryCreate,  # Missing file
    "parts_inventory": PartsInventoryCreate,
    "maintenance_predictions": MaintenancePredictionsCreate,
    # # "dtc_codes_github": DTCCodesGithubCreate,  # Missing file
    "reddit_diagnostic_posts": RedditDiagnosticPostsCreate,
    # # "youtube_repair_videos": YouTubeRepairVideosCreate,  # Missing file
    "models": ModelsCreate,
    "feature_store": FeatureStoreCreate,
}

# Update models for API operations
UPDATE_MODELS = {
    "equipment_registry": EquipmentRegistryUpdate,
    "users": UsersUpdate,
    "diagnostic_sessions": DiagnosticSessionsUpdate,
    # "sensor_telemetry": None,  # Immutable time-series data
    "parts_inventory": PartsInventoryUpdate,
    "maintenance_predictions": MaintenancePredictionsUpdate,
    # "dtc_codes_github": DTCCodesGithubUpdate,
    "reddit_diagnostic_posts": RedditDiagnosticPostsUpdate,
    # "youtube_repair_videos": YouTubeRepairVideosUpdate,
    "models": ModelsUpdate,
    "feature_store": FeatureStoreUpdate,
}

# Response models for API operations
RESPONSE_MODELS = {
    "equipment_registry": EquipmentRegistryResponse,
    "users": UsersResponse,
    "diagnostic_sessions": DiagnosticSessionsResponse,
    # "sensor_telemetry": SensorTelemetryResponse,
    "parts_inventory": PartsInventoryResponse,
    "maintenance_predictions": MaintenancePredictionsResponse,
    # "dtc_codes_github": DTCCodesGithubResponse,
    "reddit_diagnostic_posts": RedditDiagnosticPostsResponse,
    # "youtube_repair_videos": YouTubeRepairVideosResponse,
    "models": ModelsResponse,
    "feature_store": FeatureStoreResponse,
}

# Summary models for dashboards and reporting
SUMMARY_MODELS = {
    "diagnostic_sessions": DiagnosticSessionsSummary,
    # "sensor_telemetry": SensorTelemetrySummary,
    "parts_inventory": PartsInventorySummary,
    "maintenance_predictions": MaintenancePredictionsSummary,
    # "dtc_codes_github": DTCCodesGithubSummary,
    "reddit_diagnostic_posts": RedditDiagnosticPostsSummary,
    # "youtube_repair_videos": YouTubeRepairVideosSummary,
    "models": ModelsSummary,
    "feature_store": FeatureStoreSummary,
}


def get_model(table_name: str, operation: str = "base"):
    """
    Get the appropriate Pydantic model for a table and operation.

    Args:
        table_name: Name of the table/model
        operation: Type of operation (base, create, update, response, summary)

    Returns:
        Pydantic model class

    Raises:
        KeyError: If table_name or operation is not found

    Example:
        >>> model_class = get_model("users", "create")
        >>> user = model_class(email="test@example.com", ...)
    """
    registries = {
        "base": MODEL_REGISTRY,
        "create": CREATE_MODELS,
        "update": UPDATE_MODELS,
        "response": RESPONSE_MODELS,
        "summary": SUMMARY_MODELS,
    }

    if operation not in registries:
        raise KeyError(f"Unknown operation: {operation}")

    registry = registries[operation]

    if table_name not in registry:
        raise KeyError(f"Unknown table: {table_name}")

    model_class = registry[table_name]

    if model_class is None:
        raise KeyError(f"No {operation} model available for table: {table_name}")

    return model_class


def get_table_names():
    """Get list of all available table names."""
    return list(MODEL_REGISTRY.keys())


def get_available_operations(table_name: str):
    """Get list of available operations for a table."""
    operations = []

    if table_name in MODEL_REGISTRY:
        operations.append("base")
    if table_name in CREATE_MODELS:
        operations.append("create")
    if table_name in UPDATE_MODELS and UPDATE_MODELS[table_name] is not None:
        operations.append("update")
    if table_name in RESPONSE_MODELS:
        operations.append("response")
    if table_name in SUMMARY_MODELS:
        operations.append("summary")

    return operations


# Package metadata
def get_package_info():
    """Get package information."""
    return {
        "version": __version__,
        "generated_from": __generated_from__,
        "generation_date": __generation_date__,
        "model_count": len(MODEL_REGISTRY),
        "tables": get_table_names(),
    }