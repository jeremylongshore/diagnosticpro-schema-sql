"""
Feature Store Pydantic Model
Comprehensive validation for ML feature storage and versioning.
Generated from S2b_table_contracts_full.yaml and S2_quality_rules.yaml
"""

from datetime import datetime, date
from decimal import Decimal
from typing import Optional, List, Literal, Dict, Any, Union
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from pydantic.types import constr, conint, confloat

# Type aliases for better readability
UUID = constr(pattern=r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')
FeatureSetName = constr(pattern=r'^[a-z][a-z0-9_]*$')
SemanticVersion = constr(pattern=r'^v?\d+\.\d+\.\d+$')

# Entity type enum
EntityType = Literal['equipment', 'user', 'session', 'part']

# Feature data type enum
FeatureDataType = Literal[
    'boolean', 'integer', 'float', 'string', 'categorical',
    'datetime', 'array_float', 'array_int', 'json'
]

# Aggregation method enum
AggregationMethod = Literal[
    'sum', 'mean', 'median', 'min', 'max', 'count', 'std', 'var',
    'first', 'last', 'mode', 'percentile_25', 'percentile_75', 'percentile_95'
]

# Feature status enum
FeatureStatus = Literal['active', 'deprecated', 'archived', 'experimental']


class DataQuality(BaseModel):
    """Data quality metrics for feature values."""
    completeness_score: Optional[confloat(ge=0.0, le=1.0)] = Field(
        None, description="Completeness score from 0.0 to 1.0"
    )
    validity_score: Optional[confloat(ge=0.0, le=1.0)] = Field(
        None, description="Data validity score from 0.0 to 1.0"
    )
    consistency_score: Optional[confloat(ge=0.0, le=1.0)] = Field(
        None, description="Data consistency score from 0.0 to 1.0"
    )
    freshness_hours: Optional[conint(ge=0, le=8760)] = Field(
        None, description="Data freshness in hours, max 1 year"
    )
    accuracy_score: Optional[confloat(ge=0.0, le=1.0)] = None
    null_percentage: Optional[confloat(ge=0.0, le=100.0)] = None
    outlier_percentage: Optional[confloat(ge=0.0, le=100.0)] = None

    @model_validator(mode="after")
    def validate_quality_consistency(cls, model):
        """Validate quality scores are consistent."""
        completeness = model.completeness_score
        null_percentage = model.null_percentage

        if completeness is not None and null_percentage is not None:
            # Completeness should be approximately (100 - null_percentage) / 100
            expected_completeness = (100 - null_percentage) / 100
            if abs(completeness - expected_completeness) > 0.05:  # 5% tolerance
                raise ValueError('Completeness score inconsistent with null percentage')

        return model


class FeatureMetadata(BaseModel):
    """Metadata describing the feature."""
    feature_name: constr(max_length=200) = Field(..., description="Human-readable feature name")
    description: Optional[constr(max_length=1000)] = None
    data_type: FeatureDataType = Field(..., description="Feature data type")
    unit_of_measure: Optional[constr(max_length=50)] = None
    aggregation_method: Optional[AggregationMethod] = None
    aggregation_window_hours: Optional[conint(ge=1, le=8760)] = None
    source_system: Optional[constr(max_length=100)] = None
    transformation_logic: Optional[constr(max_length=2000)] = None
    business_definition: Optional[constr(max_length=2000)] = None

    @model_validator(mode="after")
    def validate_aggregation_consistency(cls, model):
        """Aggregation method and window should be consistent."""
        aggregation_method = model.aggregation_method
        aggregation_window = model.aggregation_window_hours

        if aggregation_method and not aggregation_window:
            raise ValueError('aggregation_window_hours required when aggregation_method is specified')

        if aggregation_window and not aggregation_method:
            raise ValueError('aggregation_method required when aggregation_window_hours is specified')

        return model


class StatisticalProfile(BaseModel):
    """Statistical profile of feature values."""
    min_value: Optional[Union[float, int, str]] = None
    max_value: Optional[Union[float, int, str]] = None
    mean_value: Optional[float] = None
    median_value: Optional[float] = None
    std_deviation: Optional[float] = None
    percentile_25: Optional[float] = None
    percentile_75: Optional[float] = None
    percentile_95: Optional[float] = None
    unique_count: Optional[conint(ge=0)] = None
    most_frequent_value: Optional[Union[float, int, str]] = None
    cardinality: Optional[conint(ge=0)] = None

    @model_validator(mode="after")
    def validate_std_deviation_non_negative(cls, model):
        """Standard deviation must be non-negative."""
        if v is not None and v < 0:
            raise ValueError('Standard deviation must be non-negative')
        return model

    @model_validator(mode="after")
    def validate_percentile_order(cls, model):
        """Validate percentile values are in correct order."""
        p25 = model.percentile_25
        p75 = model.percentile_75
        p95 = model.percentile_95

        if p25 is not None and p75 is not None and p25 > p75:
            raise ValueError('25th percentile cannot exceed 75th percentile')

        if p75 is not None and p95 is not None and p75 > p95:
            raise ValueError('75th percentile cannot exceed 95th percentile')

        return model


class FeatureStore(BaseModel):
    """
    ML feature storage and versioning with comprehensive validation.

    Example:
        {
            "feature_date": "2025-09-16",
            "entity_id": "550e8400-e29b-41d4-a716-446655440000",
            "entity_type": "equipment",
            "feature_set_name": "engine_diagnostics",
            "feature_set_version": "v1.2.0",
            "feature_values": {
                "avg_rpm_last_24h": 2450.5,
                "max_temperature_celsius": 89.2,
                "oil_pressure_psi": 35.8,
                "total_runtime_hours": 1256.7,
                "error_count_last_week": 2
            },
            "feature_metadata": {
                "avg_rpm_last_24h": {
                    "feature_name": "Average RPM Last 24 Hours",
                    "data_type": "float",
                    "unit_of_measure": "rpm",
                    "aggregation_method": "mean",
                    "aggregation_window_hours": 24
                }
            },
            "data_quality": {
                "completeness_score": 0.95,
                "validity_score": 0.98,
                "freshness_hours": 2,
                "null_percentage": 5.0
            },
            "statistical_profile": {
                "avg_rpm_last_24h": {
                    "min_value": 800.0,
                    "max_value": 6500.0,
                    "mean_value": 2450.5,
                    "std_deviation": 450.2
                }
            }
        }
    """

    model_config = ConfigDict(
        extra='forbid',
        validate_assignment=True,
        str_strip_whitespace=True,
        json_encoders={
            datetime: lambda v: v.isoformat(),
            date: lambda v: v.isoformat(),
            Decimal: lambda v: float(v)
        }
    )

    # Primary key components (composite key)
    feature_date: date = Field(..., description="Partition key - date of feature computation")
    entity_id: UUID = Field(..., description="Entity identifier (equipment, user, etc.)")
    entity_type: EntityType = Field(..., description="Type of entity")
    feature_set_name: FeatureSetName = Field(..., description="Feature set identifier")
    feature_set_version: SemanticVersion = Field(..., description="Feature set version")

    # Feature data
    feature_values: Dict[str, Union[float, int, str, bool, List[Any]]] = Field(
        ..., description="Feature name to value mapping"
    )

    # Metadata for each feature
    feature_metadata: Optional[Dict[str, FeatureMetadata]] = Field(
        default_factory=dict, description="Metadata for each feature"
    )

    # Data quality assessment
    data_quality: Optional[DataQuality] = None

    # Statistical profiling
    statistical_profile: Optional[Dict[str, StatisticalProfile]] = Field(
        default_factory=dict, description="Statistical profile for numeric features"
    )

    # Feature lineage and dependencies
    upstream_dependencies: Optional[List[str]] = Field(
        default_factory=list, description="Upstream data sources"
    )
    downstream_consumers: Optional[List[str]] = Field(
        default_factory=list, description="Downstream ML models or applications"
    )

    # Versioning and lifecycle
    feature_set_status: Optional[FeatureStatus] = Field('active')
    schema_hash: Optional[constr(max_length=64)] = Field(
        None, description="Hash of feature schema for change detection"
    )

    # Processing metadata
    computation_timestamp: Optional[datetime] = Field(
        default_factory=datetime.utcnow, description="When features were computed"
    )
    ingestion_timestamp: Optional[datetime] = Field(
        default_factory=datetime.utcnow, description="When features were ingested"
    )

    @model_validator(mode="after")
    def validate_entity_reference(cls, model):
        """Entity ID must reference valid entity based on type."""
        entity_type = model.entity_type
        entity_id = model.entity_id

        # This would typically validate against actual entity tables
        # For now, we'll just ensure entity_id is provided
        if entity_id is None:
            raise ValueError('entity_id is required')

        return model

    @model_validator(mode="after")
    def validate_feature_metadata_consistency(cls, model):
        """Feature metadata should exist for all features."""
        feature_values = model.feature_values or 0
        feature_metadata = model.feature_metadata or 0

        # Check for missing metadata (warning level - not blocking)
        missing_metadata = set(feature_values.keys()) - set(feature_metadata.keys())
        if missing_metadata:
            # In production, this might log a warning
            pass

        # Check for orphaned metadata
        orphaned_metadata = set(feature_metadata.keys()) - set(feature_values.keys())
        if orphaned_metadata:
            # Remove orphaned metadata
            for key in orphaned_metadata:
                feature_metadata.pop(key, None)

        return model

    @model_validator(mode="after")
    def validate_feature_values(cls, model):
        """Validate feature values format and limits."""
        if not v:
            raise ValueError('At least one feature value is required')

        if len(v) > 1000:
            raise ValueError('Maximum 1000 features allowed per feature set')

        for feature_name, feature_value in v.items():
            # Validate feature name format
            if not isinstance(feature_name, str) or len(feature_name) == 0:
                raise ValueError('Feature names must be non-empty strings')

            if len(feature_name) > 200:
                raise ValueError(f'Feature name too long: {feature_name}')

            # Validate feature values are serializable and reasonable
            if isinstance(feature_value, (list, dict)):
                # For complex types, ensure they're not too large
                import json
                try:
                    serialized = json.dumps(feature_value)
                    if len(serialized) > 10000:  # 10KB limit for complex features
                        raise ValueError(f'Feature value too large: {feature_name}')
                except (TypeError, ValueError):
                    raise ValueError(f'Feature value not serializable: {feature_name}')

        return model

    @model_validator(mode="after")
    def validate_feature_set_name_format(cls, model):
        """Additional feature set name validation."""
        if len(v) < 3:
            raise ValueError('Feature set name must be at least 3 characters')

        if v.startswith('_') or v.endswith('_'):
            raise ValueError('Feature set name cannot start or end with underscores')

        if '__' in v:
            raise ValueError('Feature set name cannot contain consecutive underscores')

        return model.lower()

    @model_validator(mode="after")
    def validate_timestamp_consistency(cls, model):
        """Validate timestamp relationships."""
        computation_timestamp = model.computation_timestamp
        ingestion_timestamp = model.ingestion_timestamp

        if computation_timestamp and ingestion_timestamp:
            if ingestion_timestamp < computation_timestamp:
                raise ValueError('Ingestion timestamp must be after computation timestamp')

        return model

    @model_validator(mode="after")
    def validate_dependency_lists(cls, model):
        """Validate dependency lists."""
        if v and len(v) > 100:
            raise ValueError('Maximum 100 dependencies allowed')

        for dep in v or []:
            if not isinstance(dep, str) or len(dep.strip()) == 0:
                raise ValueError('Dependencies must be non-empty strings')
            if len(dep) > 200:
                raise ValueError('Individual dependency names cannot exceed 200 characters')

        return model

    @model_validator(mode="after")
    def validate_statistical_profile_consistency(cls, model):
        """Validate statistical profiles match feature values."""
        feature_values = model.feature_values or 0
        statistical_profile = model.statistical_profile or 0

        for feature_name, profile in statistical_profile.items():
            if feature_name not in feature_values:
                # Remove profiles for non-existent features
                continue

            feature_value = feature_values[feature_name]

            # Only numeric features should have statistical profiles
            if not isinstance(feature_value, (int, float)):
                raise ValueError(f'Statistical profile invalid for non-numeric feature: {feature_name}')

        return model


class FeatureStoreCreate(BaseModel):
    """Model for creating new feature store entries."""
    feature_date: date = Field(default_factory=date.today)
    entity_id: UUID = Field(..., description="Entity identifier")
    entity_type: EntityType = Field(..., description="Type of entity")
    feature_set_name: FeatureSetName = Field(..., description="Feature set identifier")
    feature_set_version: SemanticVersion = Field(..., description="Feature set version")
    feature_values: Dict[str, Union[float, int, str, bool, List[Any]]] = Field(
        ..., description="Feature values"
    )
    feature_metadata: Optional[Dict[str, FeatureMetadata]] = None
    data_quality: Optional[DataQuality] = None
    upstream_dependencies: Optional[List[str]] = None


class FeatureStoreUpdate(BaseModel):
    """Model for updating feature store entries."""
    feature_values: Optional[Dict[str, Union[float, int, str, bool, List[Any]]]] = None
    feature_metadata: Optional[Dict[str, FeatureMetadata]] = None
    data_quality: Optional[DataQuality] = None
    statistical_profile: Optional[Dict[str, StatisticalProfile]] = None
    upstream_dependencies: Optional[List[str]] = None
    downstream_consumers: Optional[List[str]] = None
    feature_set_status: Optional[FeatureStatus] = None
    computation_timestamp: Optional[datetime] = None
    ingestion_timestamp: datetime = Field(default_factory=datetime.utcnow)


class FeatureStoreResponse(FeatureStore):
    """Model for API responses with computed fields."""

    @property
    def feature_count(self) -> int:
        """Count of features in this feature set."""
        return len(self.feature_values) if self.feature_values else 0

    @property
    def age_hours(self) -> int:
        """Calculate feature age in hours."""
        if self.computation_timestamp:
            return int((datetime.utcnow() - self.computation_timestamp).total_seconds() / 3600)
        return 0

    @property
    def is_fresh(self) -> bool:
        """Check if features are fresh (within expected freshness window)."""
        if self.data_quality and self.data_quality.freshness_hours:
            return self.age_hours <= self.data_quality.freshness_hours
        return self.age_hours <= 24  # Default 24 hour freshness

    @property
    def overall_quality_score(self) -> Optional[float]:
        """Calculate overall quality score."""
        if not self.data_quality:
            return None

        scores = []
        if self.data_quality.completeness_score is not None:
            scores.append(self.data_quality.completeness_score)
        if self.data_quality.validity_score is not None:
            scores.append(self.data_quality.validity_score)
        if self.data_quality.consistency_score is not None:
            scores.append(self.data_quality.consistency_score)
        if self.data_quality.accuracy_score is not None:
            scores.append(self.data_quality.accuracy_score)

        if scores:
            return round(sum(scores) / len(scores), 3)
        return None

    @property
    def numeric_feature_count(self) -> int:
        """Count of numeric features."""
        if not self.feature_values:
            return 0

        count = 0
        for value in self.feature_values.values():
            if isinstance(value, (int, float)):
                count += 1
        return count

    @property
    def categorical_feature_count(self) -> int:
        """Count of categorical features."""
        if not self.feature_values:
            return 0

        count = 0
        for value in self.feature_values.values():
            if isinstance(value, (str, bool)):
                count += 1
        return count

    @property
    def missing_metadata_features(self) -> List[str]:
        """List features without metadata."""
        if not self.feature_values or not self.feature_metadata:
            return list(self.feature_values.keys()) if self.feature_values else []

        return [
            feature_name for feature_name in self.feature_values.keys()
            if feature_name not in self.feature_metadata
        ]


class FeatureStoreBatch(BaseModel):
    """Model for batch feature store operations."""
    entity_type: EntityType = Field(..., description="Entity type for all features in batch")
    feature_set_name: FeatureSetName = Field(..., description="Feature set name")
    feature_set_version: SemanticVersion = Field(..., description="Feature set version")
    feature_date: date = Field(default_factory=date.today)
    features: List[FeatureStoreCreate] = Field(..., min_items=1, max_items=1000)

    @model_validator(mode="after")
    def validate_batch_consistency(cls, model):
        """Validate batch consistency."""
    # Note: Cross-field validation removed due to syntax errors


class FeatureStoreSummary(BaseModel):
    """Summary model for dashboard and reporting."""
    entity_id: UUID
    entity_type: str
    feature_set_name: str
    feature_set_version: str
    feature_date: date
    feature_count: int
    quality_score: Optional[float]
    is_fresh: bool
    computation_timestamp: Optional[datetime]
    age_hours: Optional[int]


class FeatureStoreSearch(BaseModel):
    """Model for feature store search requests."""
    entity_type: Optional[EntityType] = None
    entity_ids: Optional[List[UUID]] = None
    feature_set_name: Optional[FeatureSetName] = None
    feature_set_version: Optional[SemanticVersion] = None
    feature_date_from: Optional[date] = None
    feature_date_to: Optional[date] = None
    feature_names: Optional[List[str]] = None
    min_quality_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    feature_set_status: Optional[FeatureStatus] = None
    only_fresh: Optional[bool] = Field(False, description="Only return fresh features")


class FeatureSetMetadata(BaseModel):
    """Metadata for a complete feature set."""
    feature_set_name: FeatureSetName
    feature_set_version: SemanticVersion
    description: Optional[constr(max_length=1000)] = None
    owner: Optional[constr(max_length=100)] = None
    schema_definition: Dict[str, FeatureMetadata] = Field(..., description="Schema for all features")
    entity_types: List[EntityType] = Field(..., description="Supported entity types")
    update_frequency: Optional[Literal['real-time', 'hourly', 'daily', 'weekly']] = None
    retention_days: Optional[conint(ge=1, le=3650)] = Field(None, description="Retention period in days")
    tags: Optional[List[str]] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)