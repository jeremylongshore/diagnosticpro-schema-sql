"""
Diagnostic Sessions Pydantic Model
Comprehensive validation for equipment diagnostic session tracking.
Generated from S2b_table_contracts_full.yaml and S2_quality_rules.yaml
"""

from datetime import datetime, date
from decimal import Decimal
from typing import Optional, List, Literal
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from pydantic.types import constr, conint

# Type aliases for better readability
UUID = constr(pattern=r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')
DTCCode = constr(pattern=r'^[PBCU]\d{4}$')

# Session type enum
SessionType = Literal['routine_maintenance', 'diagnostic', 'repair', 'inspection', 'warranty']

# Session status enum
SessionStatus = Literal['pending', 'in_progress', 'completed', 'cancelled']

# Priority level enum
PriorityLevel = Literal['low', 'medium', 'high', 'critical']


class DiagnosticCode(BaseModel):
    """Individual diagnostic trouble code information."""
    code: DTCCode = Field(..., description="DTC code in standard format (P0XXX, B0XXX, C0XXX, U0XXX)")
    description: Optional[constr(max_length=500)] = None
    severity: Optional[PriorityLevel] = None
    status: Optional[Literal['active', 'pending', 'resolved']] = Field('active', description="Code status")
    first_detected: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

    @field_validator('code')
    def validate_dtc_format(cls, v):
        """Validate DTC code format and category consistency."""
        if len(v) != 5:
            raise ValueError('DTC code must be exactly 5 characters')

        category = v[0]
        if category not in ['P', 'B', 'C', 'U']:
            raise ValueError('DTC code must start with P, B, C, or U')

        if not v[1:].isdigit():
            raise ValueError('DTC code must have 4 digits after the category letter')

        return v


class Resolution(BaseModel):
    """Session resolution details and costs."""
    total_cost: Optional[Decimal] = Field(None, ge=0, description="Total repair/service cost")
    labor_hours: Optional[Decimal] = Field(None, ge=0, le=100, description="Labor hours, max 100")
    parts_cost: Optional[Decimal] = Field(None, ge=0, description="Parts cost")
    labor_cost: Optional[Decimal] = Field(None, ge=0, description="Labor cost")
    tax_amount: Optional[Decimal] = Field(None, ge=0, description="Tax amount")
    currency_code: Optional[constr(pattern=r'^[A-Z]{3}$')] = Field('USD', description="Currency code")
    warranty_months: Optional[conint(ge=0, le=120)] = Field(None, description="Warranty in months")


class SessionMetrics(BaseModel):
    """Session performance and quality metrics."""
    completion_percentage: Optional[Decimal] = Field(None, ge=0, le=100, description="Completion percentage")
    quality_score: Optional[Decimal] = Field(None, ge=0, le=10, description="Quality score 0-10")
    customer_satisfaction: Optional[conint(ge=1, le=5)] = Field(None, description="Customer rating 1-5")
    technician_efficiency: Optional[Decimal] = Field(None, ge=0, le=5, description="Efficiency rating")
    diagnostic_accuracy: Optional[Decimal] = Field(None, ge=0, le=100, description="Diagnostic accuracy percentage")


class DiagnosticSessions(BaseModel):
    """
    Equipment diagnostic session tracking with comprehensive validation.

    Example:
        {
            "session_id": "550e8400-e29b-41d4-a716-446655440000",
            "session_date": "2025-09-16",
            "equipment_id": "123e4567-e89b-12d3-a456-426614174000",
            "technician_id": "789e0123-e45b-67c8-d901-234567890123",
            "customer_id": "456e7890-e123-45f6-a789-012345678901",
            "session_type": "diagnostic",
            "session_status": "completed",
            "priority": "high",
            "diagnostic_codes": [
                {
                    "code": "P0301",
                    "description": "Cylinder 1 Misfire Detected",
                    "severity": "high",
                    "status": "resolved"
                }
            ],
            "resolution": {
                "total_cost": 450.00,
                "labor_hours": 2.5,
                "parts_cost": 125.00,
                "labor_cost": 300.00,
                "tax_amount": 25.00,
                "warranty_months": 12
            },
            "started_at": "2025-09-16T09:00:00Z",
            "completed_at": "2025-09-16T12:30:00Z",
            "duration_minutes": 210
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
    session_id: UUID = Field(..., description="Primary key - UUID v4")
    session_date: date = Field(..., description="Partition key - session date")

    # Related entities
    equipment_id: UUID = Field(..., description="References equipment_registry.id")
    technician_id: Optional[UUID] = Field(None, description="References users.id")
    customer_id: Optional[UUID] = Field(None, description="References users.id")

    # Session classification
    session_type: Optional[SessionType] = None
    session_status: Optional[SessionStatus] = Field('pending', description="Current session status")
    priority: Optional[PriorityLevel] = Field('medium', description="Session priority level")

    # Diagnostic information
    diagnostic_codes: Optional[List[DiagnosticCode]] = Field(default_factory=list)
    symptoms_reported: Optional[constr(max_length=2000)] = None
    work_performed: Optional[constr(max_length=5000)] = None
    recommendations: Optional[constr(max_length=2000)] = None

    # Resolution and costs
    resolution: Optional[Resolution] = None

    # Performance metrics
    metrics: Optional[SessionMetrics] = None

    # Timing
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    duration_minutes: Optional[conint(ge=1, le=10080)] = Field(None, description="Duration in minutes, max 1 week")

    # Additional information
    notes: Optional[constr(max_length=2000)] = None
    internal_notes: Optional[constr(max_length=2000)] = None

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    @field_validator('diagnostic_codes')
    def validate_diagnostic_codes_limit(cls, v):
        """Reasonable limit on number of diagnostic codes."""
        if v and len(v) > 50:
            raise ValueError('Maximum 50 diagnostic codes allowed per session')
        return v


class DiagnosticSessionsCreate(BaseModel):
    """Model for creating new diagnostic sessions."""
    session_date: date = Field(default_factory=date.today)
    equipment_id: UUID = Field(..., description="References equipment_registry.id")
    technician_id: Optional[UUID] = None
    customer_id: Optional[UUID] = None
    session_type: Optional[SessionType] = Field('diagnostic')
    priority: Optional[PriorityLevel] = Field('medium')
    symptoms_reported: Optional[constr(max_length=2000)] = None
    notes: Optional[constr(max_length=2000)] = None


class DiagnosticSessionsUpdate(BaseModel):
    """Model for updating diagnostic sessions."""
    technician_id: Optional[UUID] = None
    customer_id: Optional[UUID] = None
    session_type: Optional[SessionType] = None
    session_status: Optional[SessionStatus] = None
    priority: Optional[PriorityLevel] = None
    diagnostic_codes: Optional[List[DiagnosticCode]] = None
    symptoms_reported: Optional[constr(max_length=2000)] = None
    work_performed: Optional[constr(max_length=5000)] = None
    recommendations: Optional[constr(max_length=2000)] = None
    resolution: Optional[Resolution] = None
    metrics: Optional[SessionMetrics] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    duration_minutes: Optional[conint(ge=1, le=10080)] = None
    notes: Optional[constr(max_length=2000)] = None
    internal_notes: Optional[constr(max_length=2000)] = None
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class DiagnosticSessionsResponse(DiagnosticSessions):
    """Model for API responses with computed fields."""

    @property
    def is_billable(self) -> bool:
        """Determine if session is billable."""
        return bool(
            self.session_status == 'completed' and
            self.resolution and
            self.resolution.total_cost and
            self.resolution.total_cost > 0
        )

    @property
    def active_dtc_count(self) -> int:
        """Count of active diagnostic codes."""
        if not self.diagnostic_codes:
            return 0
        return len([code for code in self.diagnostic_codes if code.status == 'active'])

    @property
    def estimated_completion(self) -> Optional[datetime]:
        """Estimate completion time based on average duration for session type."""
        if self.started_at and not self.completed_at:
            # Default estimates by session type (in minutes)
            estimates = {
                'routine_maintenance': 60,
                'diagnostic': 90,
                'repair': 180,
                'inspection': 45,
                'warranty': 120
            }
            estimate_minutes = estimates.get(self.session_type, 90)
            from datetime import timedelta
            return self.started_at + timedelta(minutes=estimate_minutes)
        return None


class DiagnosticSessionsSummary(BaseModel):
    """Summary model for dashboard and reporting."""
    session_id: UUID
    session_date: date
    equipment_id: UUID
    session_type: Optional[SessionType]
    session_status: Optional[SessionStatus]
    priority: Optional[PriorityLevel]
    technician_id: Optional[UUID]
    customer_id: Optional[UUID]
    duration_minutes: Optional[int]
    total_cost: Optional[Decimal]
    dtc_count: Optional[int]
    created_at: datetime