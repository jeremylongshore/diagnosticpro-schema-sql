"""
Equipment Registry Pydantic Model
Universal equipment tracking with comprehensive validation.
Generated from S2b_table_contracts_full.yaml and S2_quality_rules.yaml
"""

from datetime import datetime, date
from decimal import Decimal
from typing import Optional, Literal, List, Dict, Any
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from pydantic.types import constr, confloat, conint

# Type aliases for better readability
UUID = constr(pattern=r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')

# Equipment category enum
EquipmentCategory = Literal[
    'vehicle', 'heavy_machinery', 'electronics', 'appliance',
    'tool', 'computer', 'industrial', 'marine', 'aviation', 'other'
]

# Equipment type enum for vehicles
VehicleType = Literal[
    'car', 'truck', 'motorcycle', 'suv', 'van', 'bus', 'trailer',
    'atv', 'boat', 'aircraft', 'farm_equipment', 'construction'
]

# Identification type enum
IdentificationType = Literal['vin', 'serial_number', 'model_number', 'part_number', 'asset_tag']


class Specifications(BaseModel):
    """Technical specifications of the equipment."""
    engine_size: Optional[confloat(ge=0.0, le=20.0)] = None  # Liters
    horsepower: Optional[conint(ge=0, le=2000)] = None
    fuel_type: Optional[Literal['gasoline', 'diesel', 'electric', 'hybrid', 'lpg', 'cng']] = None
    transmission_type: Optional[Literal['manual', 'automatic', 'cvt', 'dual_clutch']] = None
    drive_type: Optional[Literal['fwd', 'rwd', 'awd', '4wd']] = None
    weight_kg: Optional[confloat(ge=0.0, le=100000.0)] = None
    dimensions: Optional[Dict[str, float]] = Field(default_factory=dict)
    color: Optional[constr(max_length=50)] = None


class Location(BaseModel):
    """Current location of the equipment."""
    facility_name: Optional[constr(max_length=200)] = None
    address: Optional[constr(max_length=500)] = None
    coordinates: Optional[Dict[str, float]] = Field(default_factory=dict)
    zone: Optional[constr(max_length=100)] = None
    building: Optional[constr(max_length=100)] = None
    floor: Optional[constr(max_length=50)] = None


class EquipmentRegistry(BaseModel):
    """
    Universal equipment registry for all types of equipment with comprehensive validation.

    Example:
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "identification_primary": "1HGBH41JXMN109186",
            "identification_primary_type": "vin",
            "category": "vehicle",
            "type": "car",
            "make": "Honda",
            "model": "Civic",
            "model_year": 2021,
            "manufacture_date": "2021-03-15",
            "specifications": {
                "engine_size": 2.0,
                "horsepower": 158,
                "fuel_type": "gasoline",
                "transmission_type": "automatic"
            },
            "location": {
                "facility_name": "Main Garage",
                "address": "123 Main St, City, State"
            },
            "status": "active",
            "created_at": "2025-09-16T10:00:00Z"
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

    # Primary identification
    id: UUID = Field(..., description="Primary key - UUID v4")
    identification_primary: constr(min_length=1, max_length=50) = Field(
        ..., description="Primary identification (VIN, serial number, etc.)"
    )
    identification_primary_type: IdentificationType = Field(..., description="Type of primary identification")

    # Secondary identifications
    identification_secondary: Optional[constr(max_length=50)] = None
    identification_tertiary: Optional[constr(max_length=50)] = None

    # Basic classification
    category: EquipmentCategory = Field(..., description="High-level equipment category")
    type: Optional[VehicleType] = Field(None, description="Specific type within category")

    # Equipment details
    make: Optional[constr(max_length=100)] = None
    model: Optional[constr(max_length=100)] = None
    model_year: Optional[conint(ge=1900, le=2030)] = None
    manufacture_date: Optional[date] = None

    # Ownership and tracking
    owner_id: Optional[UUID] = Field(None, description="References users.id")
    purchase_date: Optional[date] = None
    purchase_price: Optional[Decimal] = Field(None, ge=0)
    current_value: Optional[Decimal] = Field(None, ge=0)

    # Status and condition
    status: Optional[Literal['active', 'inactive', 'maintenance', 'retired', 'sold']] = Field('active')
    condition: Optional[Literal['excellent', 'good', 'fair', 'poor', 'unknown']] = Field('unknown')
    mileage: Optional[conint(ge=0, le=10000000)] = Field(None, description="Odometer reading")
    hours_operated: Optional[confloat(ge=0.0, le=1000000.0)] = None

    # Nested structures
    specifications: Optional[Specifications] = None
    location: Optional[Location] = None

    # Metadata
    notes: Optional[constr(max_length=2000)] = None
    tags: Optional[List[str]] = Field(default_factory=list)

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    @field_validator('identification_primary')
    def validate_identification_format(cls, v):
        """Validate identification format based on common patterns."""
        if len(v.strip()) == 0:
            raise ValueError('Primary identification cannot be empty')
        return v.upper().strip()

    @field_validator('tags')
    def validate_tags_format(cls, v):
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


class EquipmentRegistryCreate(BaseModel):
    """Model for creating new equipment entries."""
    identification_primary: constr(min_length=1, max_length=50)
    identification_primary_type: IdentificationType
    category: EquipmentCategory
    type: Optional[VehicleType] = None
    make: Optional[constr(max_length=100)] = None
    model: Optional[constr(max_length=100)] = None
    model_year: Optional[conint(ge=1900, le=2030)] = None
    specifications: Optional[Specifications] = None
    location: Optional[Location] = None
    notes: Optional[constr(max_length=2000)] = None


class EquipmentRegistryUpdate(BaseModel):
    """Model for updating equipment entries."""
    identification_secondary: Optional[constr(max_length=50)] = None
    identification_tertiary: Optional[constr(max_length=50)] = None
    type: Optional[VehicleType] = None
    make: Optional[constr(max_length=100)] = None
    model: Optional[constr(max_length=100)] = None
    model_year: Optional[conint(ge=1900, le=2030)] = None
    owner_id: Optional[UUID] = None
    purchase_date: Optional[date] = None
    purchase_price: Optional[Decimal] = None
    current_value: Optional[Decimal] = None
    status: Optional[Literal['active', 'inactive', 'maintenance', 'retired', 'sold']] = None
    condition: Optional[Literal['excellent', 'good', 'fair', 'poor', 'unknown']] = None
    mileage: Optional[conint(ge=0, le=10000000)] = None
    hours_operated: Optional[confloat(ge=0.0, le=1000000.0)] = None
    specifications: Optional[Specifications] = None
    location: Optional[Location] = None
    notes: Optional[constr(max_length=2000)] = None
    tags: Optional[List[str]] = None
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class EquipmentRegistryResponse(EquipmentRegistry):
    """Model for API responses with computed fields."""

    @property
    def age_years(self) -> Optional[int]:
        """Calculate equipment age in years."""
        if self.model_year:
            return datetime.now().year - self.model_year
        return None

    @property
    def is_vintage(self) -> bool:
        """Check if equipment is considered vintage (>25 years old)."""
        age = self.age_years
        return age is not None and age > 25

    @property
    def depreciation_rate(self) -> Optional[float]:
        """Estimate annual depreciation rate based on age."""
        if self.purchase_price and self.current_value and self.age_years:
            if self.purchase_price > 0 and self.age_years > 0:
                return (1 - (float(self.current_value) / float(self.purchase_price))) / self.age_years
        return None


class EquipmentRegistrySummary(BaseModel):
    """Summary model for dashboard and reporting."""
    id: UUID
    identification_primary: str
    identification_primary_type: str
    category: str
    type: Optional[str]
    make: Optional[str]
    model: Optional[str]
    model_year: Optional[int]
    status: Optional[str]
    condition: Optional[str]
    location_facility: Optional[str]
    created_at: datetime