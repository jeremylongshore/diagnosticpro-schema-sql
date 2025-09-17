"""
Reddit Diagnostic Posts Pydantic Model
Comprehensive validation for Reddit posts with automotive diagnostic information.
Generated from S2b_table_contracts_full.yaml and S2_quality_rules.yaml
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional, List, Literal, Dict, Any
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from pydantic.types import constr, confloat

# Type aliases for better readability
VIN = constr(pattern=r'^[A-HJ-NPR-Z0-9]{17}$')
DTCCode = constr(pattern=r'^[PBCU]\d{4}$')
RedditURL = constr(pattern=r'^https?://(?:www\.)?reddit\.com/r/.+')

# Source type enum
SourceType = Literal['post', 'comment']

# Post status enum
PostStatus = Literal['active', 'deleted', 'removed', 'archived']

# Sentiment enum
Sentiment = Literal['positive', 'negative', 'neutral', 'mixed']

# Solution status enum
SolutionStatus = Literal['solved', 'unsolved', 'partially_solved', 'unknown']


class EquipmentInfo(BaseModel):
    """Equipment information from the Reddit post."""
    vin: Optional[VIN] = Field(None, description="Vehicle VIN if mentioned")
    make: Optional[constr(max_length=100)] = None
    model: Optional[constr(max_length=100)] = None
    year: Optional[int] = Field(None, ge=1900, le=2030)
    mileage: Optional[int] = Field(None, ge=0, le=2000000)
    engine_size: Optional[constr(max_length=50)] = None
    transmission_type: Optional[Literal['manual', 'automatic', 'cvt']] = None
    fuel_type: Optional[Literal['gasoline', 'diesel', 'hybrid', 'electric', 'flex_fuel']] = None

    @model_validator(mode="after")
    def validate_reasonable_year(cls, model):
        """Validate year is reasonable."""
        if v is not None:
            current_year = datetime.now().year
            if v > current_year + 1:
                raise ValueError(f'Year cannot be more than 1 year in the future: {v}')
        return model


class DiagnosticCode(BaseModel):
    """Individual diagnostic trouble code mentioned in post."""
    code: DTCCode = Field(..., description="DTC code in standard format")
    mentioned_context: Optional[constr(max_length=500)] = None
    is_primary_issue: Optional[bool] = Field(False, description="Whether this is the main issue")
    was_cleared: Optional[bool] = Field(None, description="Whether the code was cleared")
    recurrence_mentioned: Optional[bool] = Field(None, description="Whether recurrence was mentioned")

    @model_validator(mode="after")
    def validate_dtc_format(cls, model):
        """Validate DTC code format."""
        if len(v) != 5:
            raise ValueError('DTC code must be exactly 5 characters')

        category = v[0]
        if category not in ['P', 'B', 'C', 'U']:
            raise ValueError('DTC code must start with P, B, C, or U')

        if not v[1:].isdigit():
            raise ValueError('DTC code must have 4 digits after the category letter')

        return model.upper()


class RepairInfo(BaseModel):
    """Information about repairs performed or suggested."""
    parts_replaced: Optional[List[str]] = Field(default_factory=list)
    labor_performed: Optional[List[str]] = Field(default_factory=list)
    cost_mentioned: Optional[Decimal] = Field(None, ge=0, le=100000)
    currency: Optional[constr(pattern=r'^[A-Z]{3}$')] = Field('USD')
    shop_name: Optional[constr(max_length=200)] = None
    diy_repair: Optional[bool] = Field(None, description="Whether repair was DIY")
    warranty_mentioned: Optional[bool] = Field(None)
    success_reported: Optional[bool] = Field(None, description="Whether repair was reported successful")

    @model_validator(mode="after")
    def validate_lists_limit(cls, model):
        """Reasonable limits on list items."""
        if v and len(v) > 20:
            raise ValueError('Maximum 20 items allowed in repair lists')
        return model

    @model_validator(mode="after")
    def validate_currency_with_cost(cls, model):
        """Currency should be specified when cost is mentioned."""
        cost = model.cost_mentioned
        currency = model.currency

        if cost is not None and cost > 0 and not currency:
            model.currency = 'USD'  # Default to USD

        return model


class PostMetrics(BaseModel):
    """Reddit post engagement metrics."""
    upvotes: Optional[int] = Field(None, ge=0)
    downvotes: Optional[int] = Field(None, ge=0)
    net_score: Optional[int] = None
    comment_count: Optional[int] = Field(None, ge=0)
    awards_count: Optional[int] = Field(None, ge=0)
    gilded: Optional[bool] = Field(False)

    @model_validator(mode="after")
    def calculate_net_score(cls, model):
        """Calculate net score from upvotes and downvotes."""
        upvotes = model.upvotes
        downvotes = model.downvotes

        if upvotes is not None and downvotes is not None:
            model.net_score = upvotes - downvotes

        return model


class ExtractionInfo(BaseModel):
    """Information about the data extraction process."""
    extraction_method: Optional[constr(max_length=100)] = None
    confidence_score: Optional[confloat(ge=0.0, le=1.0)] = None
    keywords_matched: Optional[List[str]] = Field(default_factory=list)
    text_quality_score: Optional[confloat(ge=0.0, le=1.0)] = None
    language_detected: Optional[constr(max_length=10)] = Field('en')
    sentiment: Optional[Sentiment] = None


class RedditDiagnosticPosts(BaseModel):
    """
    Reddit posts with automotive diagnostic information.

    Example:
        {
            "url": "https://www.reddit.com/r/MechanicAdvice/comments/abc123/p0301_misfire_help/",
            "title": "P0301 Misfire - Need Help Diagnosing",
            "content_text": "My 2015 Honda Civic is throwing P0301...",
            "author": "car_owner_123",
            "subreddit": "MechanicAdvice",
            "equipment": {
                "make": "Honda",
                "model": "Civic",
                "year": 2015,
                "mileage": 85000
            },
            "diagnostic_codes": [
                {
                    "code": "P0301",
                    "mentioned_context": "Started last week",
                    "is_primary_issue": true
                }
            ],
            "repair_info": {
                "cost_mentioned": 450.00,
                "parts_replaced": ["spark_plugs", "ignition_coil"],
                "diy_repair": false
            },
            "metrics": {
                "upvotes": 25,
                "comment_count": 12,
                "net_score": 23
            },
            "timestamp": "2025-09-16T14:30:00Z",
            "source_type": "post",
            "solution_status": "solved"
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
    url: RedditURL = Field(..., description="Unique Reddit URL")

    # Post content
    title: Optional[constr(max_length=300)] = None
    content_text: Optional[constr(max_length=40000)] = None
    author: Optional[constr(max_length=100)] = None
    subreddit: Optional[constr(max_length=100)] = None

    # Equipment information
    equipment: Optional[EquipmentInfo] = None

    # Diagnostic information
    diagnostic_codes: Optional[List[DiagnosticCode]] = Field(default_factory=list)
    symptoms_described: Optional[List[str]] = Field(default_factory=list)
    solutions_mentioned: Optional[List[str]] = Field(default_factory=list)
    repair_info: Optional[RepairInfo] = None

    # Post metadata
    timestamp: datetime = Field(..., description="Post creation timestamp")
    source_type: SourceType = Field('post', description="Post or comment")
    post_status: Optional[PostStatus] = Field('active')
    solution_status: Optional[SolutionStatus] = Field('unknown')

    # Cost information
    cost: Optional[confloat(ge=0, le=100000)] = Field(None, description="Total cost mentioned")

    # Reddit metrics
    metrics: Optional[PostMetrics] = None

    # Extraction metadata
    extraction: Optional[ExtractionInfo] = None

    # Source tracking
    source: constr(pattern=r'^reddit_[a-z0-9_]+$') = Field(
        ..., description="Source identifier with reddit_ prefix"
    )

    # Processing timestamps
    import_timestamp: datetime = Field(
        default_factory=datetime.utcnow, description="When imported into our system"
    )

    @model_validator(mode="after")
    def validate_reddit_url_format(cls, model):
        """Validate Reddit URL format and structure."""
        if not v.startswith(('https://reddit.com/', 'https://www.reddit.com/')):
            raise ValueError('URL must be a valid Reddit URL')

        # Check for minimum required structure
        if '/r/' not in v:
            raise ValueError('URL must contain a subreddit (/r/)')

        # Basic validation that it looks like a Reddit post/comment URL
        url_parts = v.split('/')
        if len(url_parts) < 6:  # https, '', domain, r, subreddit, comments
            raise ValueError('URL does not appear to be a valid Reddit post URL')

        return model

    @model_validator(mode="after")
    def validate_timestamp_range(cls, model):
        """Validate timestamp is within reasonable range."""
        reddit_founding = datetime(2005, 6, 23)  # Reddit founding date
        if v < reddit_founding:
            raise ValueError('Timestamp cannot be before Reddit was founded (2005-06-23)')

        if v > datetime.utcnow():
            raise ValueError('Timestamp cannot be in the future')

        return model

    @model_validator(mode="after")
    def validate_import_after_post(cls, model):
        """Import timestamp must be after post timestamp."""
        timestamp = model.timestamp
        import_timestamp = model.import_timestamp

        if timestamp and import_timestamp and import_timestamp < timestamp:
            raise ValueError('Import timestamp must be after post timestamp')

        return model

    @model_validator(mode="after")
    def validate_diagnostic_codes_limit(cls, model):
        """Reasonable limit on diagnostic codes."""
        if v and len(v) > 20:
            raise ValueError('Maximum 20 diagnostic codes allowed per post')
        return model

    @model_validator(mode="after")
    def validate_description_lists(cls, model):
        """Validate description lists."""
        if v and len(v) > 50:
            raise ValueError('Maximum 50 items allowed in description lists')

        # Check for reasonable string lengths
        for item in v or []:
            if len(item) > 200:
                raise ValueError('Individual description items cannot exceed 200 characters')

        return model

    @model_validator(mode="after")
    def validate_subreddit_format(cls, model):
        """Validate subreddit name format."""
        if v is not None:
            # Remove r/ prefix if present
            if v.startswith('r/'):
                v = v[2:]

            # Basic validation
            if not v.replace('_', '').replace('-', '').isalnum():
                raise ValueError('Subreddit name contains invalid characters')

            if len(v) < 2 or len(v) > 21:
                raise ValueError('Subreddit name must be 2-21 characters')

        return model

    @model_validator(mode="after")
    def validate_author_format(cls, model):
        """Validate Reddit author username format."""
        if v is not None:
            # Remove u/ prefix if present
            if v.startswith('u/'):
                v = v[2:]

            # Basic validation (Reddit usernames are alphanumeric with underscores and dashes)
            if not v.replace('_', '').replace('-', '').isalnum():
                raise ValueError('Author username contains invalid characters')

            if len(v) < 3 or len(v) > 20:
                raise ValueError('Author username must be 3-20 characters')

        return model

    @model_validator(mode="after")
    def validate_vin_automotive_consistency(cls, model):
        """VIN format validation for automotive posts."""
        equipment = model.equipment

        if equipment and equipment.vin:
            # Additional VIN validation beyond regex
            vin = equipment.vin
            if len(vin) != 17:
                raise ValueError('VIN must be exactly 17 characters')

            # Check for invalid characters
            invalid_chars = ['I', 'O', 'Q']
            if any(char in vin for char in invalid_chars):
                raise ValueError('VIN cannot contain letters I, O, or Q')

        return model

    @model_validator(mode="after")
    def validate_content_completeness(cls, model):
        """Ensure post has meaningful content."""
        title = model.title
        content_text = model.content_text
        diagnostic_codes = model.diagnostic_codes or 0

        # At least one of these should have content
        if not any([
            title and len(title.strip()) > 5,
            content_text and len(content_text.strip()) > 10,
            diagnostic_codes and len(diagnostic_codes) > 0
        ]):
            raise ValueError('Post must have meaningful title, content, or diagnostic codes')

        return model


class RedditDiagnosticPostsCreate(BaseModel):
    """Model for creating new Reddit diagnostic posts."""
    url: RedditURL = Field(..., description="Reddit URL")
    title: Optional[constr(max_length=300)] = None
    content_text: Optional[constr(max_length=40000)] = None
    author: Optional[constr(max_length=100)] = None
    subreddit: Optional[constr(max_length=100)] = None
    equipment: Optional[EquipmentInfo] = None
    diagnostic_codes: Optional[List[DiagnosticCode]] = None
    symptoms_described: Optional[List[str]] = None
    repair_info: Optional[RepairInfo] = None
    timestamp: datetime = Field(..., description="Post timestamp")
    source_type: SourceType = Field('post')
    source: constr(pattern=r'^reddit_[a-z0-9_]+$') = Field(..., description="Source identifier")
    cost: Optional[confloat(ge=0, le=100000)] = None


class RedditDiagnosticPostsUpdate(BaseModel):
    """Model for updating Reddit diagnostic posts."""
    title: Optional[constr(max_length=300)] = None
    content_text: Optional[constr(max_length=40000)] = None
    equipment: Optional[EquipmentInfo] = None
    diagnostic_codes: Optional[List[DiagnosticCode]] = None
    symptoms_described: Optional[List[str]] = None
    solutions_mentioned: Optional[List[str]] = None
    repair_info: Optional[RepairInfo] = None
    post_status: Optional[PostStatus] = None
    solution_status: Optional[SolutionStatus] = None
    cost: Optional[confloat(ge=0, le=100000)] = None
    metrics: Optional[PostMetrics] = None
    extraction: Optional[ExtractionInfo] = None


class RedditDiagnosticPostsResponse(RedditDiagnosticPosts):
    """Model for API responses with computed fields."""

    @property
    def age_days(self) -> int:
        """Calculate post age in days."""
        return (datetime.utcnow() - self.timestamp).days

    @property
    def is_recent(self) -> bool:
        """Check if post is recent (within 30 days)."""
        return self.age_days <= 30

    @property
    def engagement_score(self) -> float:
        """Calculate engagement score based on metrics."""
        if not self.metrics:
            return 0.0

        score = 0.0
        if self.metrics.upvotes:
            score += min(self.metrics.upvotes / 100, 1.0) * 0.4
        if self.metrics.comment_count:
            score += min(self.metrics.comment_count / 50, 1.0) * 0.4
        if self.metrics.awards_count:
            score += min(self.metrics.awards_count / 5, 1.0) * 0.2

        return min(score, 1.0)

    @property
    def has_diagnostic_codes(self) -> bool:
        """Check if post contains diagnostic codes."""
        return bool(self.diagnostic_codes and len(self.diagnostic_codes) > 0)

    @property
    def primary_dtc_code(self) -> Optional[str]:
        """Get the primary DTC code if available."""
        if self.diagnostic_codes:
            for code in self.diagnostic_codes:
                if code.is_primary_issue:
                    return code.code
            # Return first code if no primary is marked
            return self.diagnostic_codes[0].code
        return None

    @property
    def estimated_repair_cost(self) -> Optional[float]:
        """Get estimated repair cost from various sources."""
        # Priority: direct cost > repair_info cost > None
        if self.cost:
            return float(self.cost)
        elif self.repair_info and self.repair_info.cost_mentioned:
            return float(self.repair_info.cost_mentioned)
        return None

    @property
    def content_quality_score(self) -> float:
        """Calculate content quality score."""
        score = 0.0

        # Content length score
        if self.content_text:
            length_score = min(len(self.content_text) / 500, 1.0) * 0.3
            score += length_score

        # Diagnostic codes present
        if self.has_diagnostic_codes:
            score += 0.3

        # Equipment info completeness
        if self.equipment:
            equipment_score = 0
            if self.equipment.make: equipment_score += 1
            if self.equipment.model: equipment_score += 1
            if self.equipment.year: equipment_score += 1
            if self.equipment.mileage: equipment_score += 1
            score += (equipment_score / 4) * 0.2

        # Solution information
        if self.solution_status in ['solved', 'partially_solved']:
            score += 0.2

        return min(score, 1.0)


class RedditDiagnosticPostsSummary(BaseModel):
    """Summary model for dashboard and reporting."""
    url: str
    title: Optional[str]
    author: Optional[str]
    subreddit: Optional[str]
    primary_dtc_code: Optional[str]
    solution_status: Optional[str]
    estimated_cost: Optional[Decimal]
    engagement_score: Optional[float]
    timestamp: datetime
    age_days: Optional[int]


class RedditDiagnosticPostsSearch(BaseModel):
    """Model for Reddit post search requests."""
    query: Optional[str] = None
    subreddit: Optional[str] = None
    author: Optional[str] = None
    dtc_codes: Optional[List[str]] = None
    make: Optional[str] = None
    model: Optional[str] = None
    year_from: Optional[int] = None
    year_to: Optional[int] = None
    solution_status: Optional[SolutionStatus] = None
    cost_min: Optional[Decimal] = None
    cost_max: Optional[Decimal] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    min_engagement_score: Optional[float] = Field(None, ge=0.0, le=1.0)