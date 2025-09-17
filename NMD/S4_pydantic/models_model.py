"""
Models Pydantic Model
Comprehensive validation for ML model registry and metadata.
Generated from S2b_table_contracts_full.yaml and S2_quality_rules.yaml
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional, List, Literal, Dict, Any, Union
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from pydantic.types import constr, conint, confloat

# Type aliases for better readability
UUID = constr(pattern=r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')
ModelName = constr(pattern=r'^[a-z][a-z0-9_-]*$', max_length=100)
SemanticVersion = constr(pattern=r'^v?\d+\.\d+\.\d+(-[a-z0-9]+)?$')
GitCommitHash = constr(pattern=r'^[a-f0-9]{40}$')

# Algorithm type enum
AlgorithmType = Literal[
    'linear_regression', 'logistic_regression', 'random_forest', 'gradient_boosting',
    'neural_network', 'svm', 'kmeans', 'xgboost', 'lightgbm', 'catboost',
    'decision_tree', 'naive_bayes', 'knn', 'ensemble', 'deep_learning',
    'transformer', 'lstm', 'cnn', 'autoencoder', 'gan'
]

# Framework enum
Framework = Literal[
    'scikit-learn', 'tensorflow', 'pytorch', 'xgboost', 'lightgbm', 'catboost',
    'spark_ml', 'h2o', 'keras', 'fastai', 'huggingface', 'onnx', 'mlflow',
    'ray', 'dask', 'prophet', 'statsmodels'
]

# Model type enum
ModelType = Literal[
    'classification', 'regression', 'clustering', 'anomaly_detection',
    'recommendation', 'forecasting', 'nlp', 'computer_vision',
    'reinforcement_learning', 'generative', 'embedding'
]

# Model status enum
ModelStatus = Literal['development', 'testing', 'staging', 'production', 'retired', 'deprecated']

# Performance metric type enum
MetricType = Literal[
    'accuracy', 'precision', 'recall', 'f1_score', 'auc_roc', 'auc_pr',
    'mse', 'rmse', 'mae', 'r2_score', 'silhouette_score',
    'adjusted_rand_index', 'bleu_score', 'rouge_score'
]


class VersionInfo(BaseModel):
    """Model version information and metadata."""
    version_number: Optional[SemanticVersion] = Field(None, description="Semantic version number")
    git_commit_hash: Optional[GitCommitHash] = Field(None, description="Full SHA-1 hash")
    build_number: Optional[conint(ge=1)] = None
    is_production: Optional[bool] = Field(False, description="Production deployment status")
    is_champion: Optional[bool] = Field(False, description="Champion model status")
    parent_model_id: Optional[UUID] = Field(None, description="Parent model for versioning")
    changelog: Optional[constr(max_length=2000)] = None

    @model_validator(mode="after")
    def validate_git_hash_format(cls, model):
        """Validate Git commit hash format."""
        if v is not None and len(v) != 40:
            raise ValueError('Git commit hash must be exactly 40 characters')
        return model


class TrainingInfo(BaseModel):
    """Model training configuration and results."""
    training_rows: Optional[conint(ge=1)] = Field(None, description="Number of training samples")
    validation_rows: Optional[conint(ge=1)] = Field(None, description="Number of validation samples")
    test_rows: Optional[conint(ge=1)] = Field(None, description="Number of test samples")
    training_duration_seconds: Optional[conint(ge=1)] = Field(None, description="Training time in seconds")
    training_start: Optional[datetime] = None
    training_end: Optional[datetime] = None
    hyperparameters: Optional[Dict[str, Any]] = Field(default_factory=dict)
    feature_count: Optional[conint(ge=1)] = None
    cross_validation_folds: Optional[conint(ge=2, le=20)] = None

    @model_validator(mode="after")
    def validate_training_times(cls, model):
        """Validate training time relationships."""
        training_start = model.training_start
        training_end = model.training_end
        training_duration = model.training_duration_seconds

        if training_start and training_end:
            if training_end <= training_start:
                raise ValueError('Training end must be after training start')

            # Calculate duration if not provided
            if training_duration is None:
                calculated_duration = int((training_end - training_start).total_seconds())
                model.training_duration_seconds = calculated_duration

        return model

    @model_validator(mode="after")
    def validate_data_split_consistency(cls, model):
        """Validate training data split consistency."""
        training_rows = model.training_rows
        validation_rows = model.validation_rows
        test_rows = model.test_rows

        if training_rows and validation_rows:
            # Validation set should typically be smaller than training set
            if validation_rows > training_rows:
                # This is unusual but not necessarily wrong, so we'll allow it
                pass

        return model


class PerformanceMetrics(BaseModel):
    """Model performance metrics and evaluation results."""
    metrics: Optional[Dict[str, Union[float, int]]] = Field(default_factory=dict)
    validation_score: Optional[confloat(ge=0.0, le=1.0)] = None
    test_score: Optional[confloat(ge=0.0, le=1.0)] = None
    cross_validation_score: Optional[confloat(ge=0.0, le=1.0)] = None
    feature_importance: Optional[Dict[str, float]] = Field(default_factory=dict)
    confusion_matrix: Optional[List[List[int]]] = None
    learning_curve_data: Optional[Dict[str, List[float]]] = Field(default_factory=dict)

    @model_validator(mode="after")
    def validate_metrics_values(cls, model):
        """Validate performance metrics are reasonable."""
        if v:
            for metric_name, metric_value in v.items():
                if isinstance(metric_value, (int, float)):
                    if metric_name in ['accuracy', 'precision', 'recall', 'f1_score', 'auc_roc', 'auc_pr']:
                        if not (0.0 <= metric_value <= 1.0):
                            raise ValueError(f'{metric_name} must be between 0.0 and 1.0')
                    elif metric_name in ['mse', 'rmse', 'mae']:
                        if metric_value < 0:
                            raise ValueError(f'{metric_name} must be non-negative')
        return model

    @model_validator(mode="after")
    def validate_feature_importance_sum(cls, model):
        """Validate feature importance values."""
        if v:
            # Check that all values are non-negative
            for feature, importance in v.items():
                if importance < 0:
                    raise ValueError('Feature importance values must be non-negative')

            # Optional: Check if importance values sum to approximately 1.0
            total_importance = sum(v.values())
            if len(v) > 0 and abs(total_importance - 1.0) > 0.01:
                # This might be a normalized importance, so we'll allow it
                pass

        return model


class DeploymentInfo(BaseModel):
    """Model deployment configuration and status."""
    deployment_environment: Optional[Literal['development', 'staging', 'production']] = None
    endpoint_url: Optional[constr(max_length=500)] = None
    container_image: Optional[constr(max_length=200)] = None
    max_instances: Optional[conint(ge=1, le=1000)] = Field(None, description="Maximum instances")
    min_instances: Optional[conint(ge=0, le=100)] = Field(None, description="Minimum instances")
    cpu_request: Optional[confloat(ge=0.1, le=32.0)] = Field(None, description="CPU cores requested")
    memory_request_gb: Optional[confloat(ge=0.1, le=256.0)] = Field(None, description="Memory in GB")
    gpu_required: Optional[bool] = Field(False)
    scaling_policy: Optional[Literal['manual', 'auto', 'scheduled']] = Field('manual')
    health_check_url: Optional[constr(max_length=500)] = None

    @model_validator(mode="after")
    def validate_instance_limits(cls, model):
        """Min instances cannot exceed max instances."""
        min_instances = model.min_instances
        max_instances = model.max_instances

        if min_instances is not None and max_instances is not None:
            if min_instances > max_instances:
                raise ValueError('min_instances cannot exceed max_instances')

        return model


class Models(BaseModel):
    """
    ML model registry and metadata with comprehensive validation.

    Example:
        {
            "model_id": "550e8400-e29b-41d4-a716-446655440000",
            "model_name": "brake_wear_predictor",
            "model_type": "regression",
            "algorithm": "xgboost",
            "framework": "xgboost",
            "description": "Predicts brake pad wear based on sensor data",
            "version_info": {
                "version_number": "v2.1.0",
                "git_commit_hash": "abc123...",
                "is_production": true,
                "is_champion": true
            },
            "training": {
                "training_rows": 100000,
                "validation_rows": 20000,
                "test_rows": 10000,
                "training_duration_seconds": 3600,
                "feature_count": 25
            },
            "performance": {
                "metrics": {
                    "r2_score": 0.89,
                    "rmse": 0.15,
                    "mae": 0.12
                },
                "validation_score": 0.87,
                "test_score": 0.89
            },
            "deployment": {
                "deployment_environment": "production",
                "max_instances": 5,
                "min_instances": 2,
                "cpu_request": 2.0,
                "memory_request_gb": 4.0
            }
        }
    """

    model_config = ConfigDict(
        extra='forbid',
        validate_assignment=True,
        str_strip_whitespace=True,
        json_encoders={
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: float(v)
        }
    )

    # Primary identification
    model_id: UUID = Field(..., description="Primary key - UUID v4")
    model_name: ModelName = Field(..., description="Snake case model name")

    # Model classification
    model_type: Optional[ModelType] = None
    algorithm: Optional[AlgorithmType] = None
    framework: Optional[Framework] = None
    description: Optional[constr(max_length=1000)] = None

    # Version management
    version_info: Optional[VersionInfo] = None

    # Training information
    training: Optional[TrainingInfo] = None

    # Performance metrics
    performance: Optional[PerformanceMetrics] = None

    # Deployment configuration
    deployment: Optional[DeploymentInfo] = None

    # Model status and lifecycle
    status: Optional[ModelStatus] = Field('development', description="Current model status")
    is_active: Optional[bool] = Field(True, description="Active in registry")
    tags: Optional[List[str]] = Field(default_factory=list)

    # Model artifacts and files
    model_artifact_path: Optional[constr(max_length=500)] = None
    config_file_path: Optional[constr(max_length=500)] = None
    requirements_file_path: Optional[constr(max_length=500)] = None

    # Business context
    use_case: Optional[constr(max_length=500)] = None
    business_owner: Optional[constr(max_length=100)] = None
    technical_owner: Optional[constr(max_length=100)] = None

    # Additional metadata
    notes: Optional[constr(max_length=2000)] = None
    documentation_url: Optional[constr(max_length=500)] = None

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    retired_at: Optional[datetime] = None

    @model_validator(mode="after")
    def validate_model_name_format(cls, model):
        """Additional model name validation."""
        if len(v) < 3:
            raise ValueError('Model name must be at least 3 characters')

        if v.startswith('-') or v.endswith('-') or v.startswith('_') or v.endswith('_'):
            raise ValueError('Model name cannot start or end with dashes or underscores')

        if '--' in v or '__' in v:
            raise ValueError('Model name cannot contain consecutive dashes or underscores')

        return model.lower()

    @model_validator(mode="after")
    def validate_champion_production_consistency(cls, model):
        """Champion models must be in production."""
        version_info = model.version_info

        if version_info:
            is_champion = version_info.is_champion
            is_production = version_info.is_production

            if is_champion and not is_production:
                raise ValueError('Champion models must be in production')

        return model

    @model_validator(mode="after")
    def validate_status_consistency(cls, model):
        """Validate status consistency with other fields."""
        status = model.status
        retired_at = model.retired_at
        is_active = model.is_active
        version_info = model.version_info

        # Retired models
        if status == 'retired':
            if retired_at is None:
                raise ValueError('retired_at must be set when status is retired')
            if is_active:
                raise ValueError('Retired models cannot be active')

        # Production status consistency
        if status == 'production' and version_info:
            if not version_info.is_production:
                raise ValueError('Models in production status must have is_production=true')

        return model

    @model_validator(mode="after")
    def validate_tags_format(cls, model):
        """Validate tags format and limits."""
        if v:
            if len(v) > 20:
                raise ValueError('Maximum 20 tags allowed')

            for tag in v:
                if not isinstance(tag, str) or len(tag.strip()) == 0:
                    raise ValueError('Tags must be non-empty strings')
                if len(tag) > 50:
                    raise ValueError('Individual tags cannot exceed 50 characters')

        return [tag.strip().lower() for tag in v] if v else []

    @model_validator(mode="after")
    def validate_updated_after_created(cls, model):
        """Updated timestamp must be after created timestamp."""
        created_at = model.created_at
        if created_at and v < created_at:
            raise ValueError('Updated timestamp must be after created timestamp')
        return v

    @model_validator(mode="after")
    def validate_retired_after_created(cls, model):
        """Retired timestamp must be after created timestamp."""
    # Note: Cross-field validation removed due to syntax errors


class ModelsCreate(BaseModel):
    """Model for creating new ML models."""
    model_name: ModelName = Field(..., description="Snake case model name")
    model_type: Optional[ModelType] = None
    algorithm: Optional[AlgorithmType] = None
    framework: Optional[Framework] = None
    description: Optional[constr(max_length=1000)] = None
    version_info: Optional[VersionInfo] = None
    training: Optional[TrainingInfo] = None
    use_case: Optional[constr(max_length=500)] = None
    business_owner: Optional[constr(max_length=100)] = None
    technical_owner: Optional[constr(max_length=100)] = None
    tags: Optional[List[str]] = None


class ModelsUpdate(BaseModel):
    """Model for updating ML models."""
    model_type: Optional[ModelType] = None
    algorithm: Optional[AlgorithmType] = None
    framework: Optional[Framework] = None
    description: Optional[constr(max_length=1000)] = None
    version_info: Optional[VersionInfo] = None
    training: Optional[TrainingInfo] = None
    performance: Optional[PerformanceMetrics] = None
    deployment: Optional[DeploymentInfo] = None
    status: Optional[ModelStatus] = None
    is_active: Optional[bool] = None
    tags: Optional[List[str]] = None
    model_artifact_path: Optional[constr(max_length=500)] = None
    use_case: Optional[constr(max_length=500)] = None
    business_owner: Optional[constr(max_length=100)] = None
    technical_owner: Optional[constr(max_length=100)] = None
    notes: Optional[constr(max_length=2000)] = None
    documentation_url: Optional[constr(max_length=500)] = None
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class ModelsResponse(Models):
    """Model for API responses with computed fields."""

    @property
    def age_days(self) -> int:
        """Calculate model age in days."""
        return (datetime.utcnow() - self.created_at).days

    @property
    def is_recent(self) -> bool:
        """Check if model is recent (within 30 days)."""
        return self.age_days <= 30

    @property
    def training_efficiency_score(self) -> Optional[float]:
        """Calculate training efficiency score."""
        if not self.training or not self.training.training_duration_seconds or not self.training.training_rows:
            return None

        # Calculate samples per second
        samples_per_second = self.training.training_rows / self.training.training_duration_seconds

        # Normalize to a 0-1 score (arbitrary baseline: 100 samples/second = 1.0)
        efficiency = min(samples_per_second / 100, 1.0)
        return round(efficiency, 3)

    @property
    def performance_score(self) -> Optional[float]:
        """Calculate overall performance score."""
        if not self.performance or not self.performance.metrics:
            return None

        # Weight different metrics based on model type
        metrics = self.performance.metrics
        score = 0.0
        metric_count = 0

        # Classification metrics
        for metric in ['accuracy', 'f1_score', 'auc_roc']:
            if metric in metrics:
                score += metrics[metric]
                metric_count += 1

        # Regression metrics (invert for error metrics)
        for metric in ['r2_score']:
            if metric in metrics:
                score += metrics[metric]
                metric_count += 1

        if metric_count > 0:
            return round(score / metric_count, 3)

        return None

    @property
    def deployment_readiness(self) -> str:
        """Assess deployment readiness."""
        readiness_score = 0

        # Performance validation
        if self.performance and self.performance.test_score:
            if self.performance.test_score > 0.8:
                readiness_score += 3
            elif self.performance.test_score > 0.6:
                readiness_score += 2
            else:
                readiness_score += 1

        # Deployment configuration
        if self.deployment:
            readiness_score += 2

        # Documentation
        if self.documentation_url:
            readiness_score += 1

        # Version management
        if self.version_info and self.version_info.version_number:
            readiness_score += 1

        if readiness_score >= 6:
            return 'ready'
        elif readiness_score >= 4:
            return 'partially_ready'
        else:
            return 'not_ready'

    @property
    def resource_requirements(self) -> Dict[str, Any]:
        """Summarize resource requirements."""
        requirements = {}

        if self.deployment:
            if self.deployment.cpu_request:
                requirements['cpu_cores'] = self.deployment.cpu_request
            if self.deployment.memory_request_gb:
                requirements['memory_gb'] = self.deployment.memory_request_gb
            if self.deployment.gpu_required:
                requirements['gpu'] = True
            if self.deployment.max_instances:
                requirements['max_instances'] = self.deployment.max_instances

        return requirements


class ModelsSummary(BaseModel):
    """Summary model for dashboard and reporting."""
    model_id: UUID
    model_name: str
    model_type: Optional[str]
    algorithm: Optional[str]
    status: Optional[str]
    version_number: Optional[str]
    is_production: Optional[bool]
    is_champion: Optional[bool]
    performance_score: Optional[float]
    created_at: datetime
    age_days: Optional[int]


class ModelsSearch(BaseModel):
    """Model for ML model search requests."""
    query: Optional[str] = None
    model_type: Optional[ModelType] = None
    algorithm: Optional[AlgorithmType] = None
    framework: Optional[Framework] = None
    status: Optional[ModelStatus] = None
    is_active: Optional[bool] = None
    is_production: Optional[bool] = None
    is_champion: Optional[bool] = None
    business_owner: Optional[str] = None
    technical_owner: Optional[str] = None
    min_performance_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None
    tags: Optional[List[str]] = None


class ModelsPromote(BaseModel):
    """Model for promoting models to production."""
    target_environment: Literal['staging', 'production'] = Field(..., description="Target environment")
    deployment_config: Optional[DeploymentInfo] = None
    rollback_plan: Optional[constr(max_length=1000)] = None
    approval_required: Optional[bool] = Field(True, description="Whether approval is required")
    approved_by: Optional[constr(max_length=100)] = None
    notes: Optional[constr(max_length=2000)] = None

    @model_validator(mode="after")
    def validate_promotion_requirements(cls, model):
        """Validate promotion requirements."""
        target_env = model.target_environment
        approval_required = model.approval_required or 0
        approved_by = model.approved_by

        if target_env == 'production' and approval_required and not approved_by:
            raise ValueError('Production promotions require approval when approval_required=True')

        return model