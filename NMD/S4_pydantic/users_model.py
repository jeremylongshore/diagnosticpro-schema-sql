"""
Users Pydantic Model
Comprehensive validation for user authentication and profile management.
Generated from S2b_table_contracts_full.yaml and S2_quality_rules.yaml
"""

from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from pydantic.types import constr, conint

# Type aliases for better readability
UUID = constr(pattern=r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')
PhoneNumber = constr(pattern=r'^\+?[\d\s\-\(\)]{10,20}$')
Timezone = constr(pattern=r'^[A-Za-z]+/[A-Za-z_]+$')
CountryCode = constr(pattern=r'^[A-Z]{2}$')
Email = constr(pattern=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')

# User type enum
UserType = Literal['customer', 'technician', 'administrator', 'shop_owner', 'fleet_manager']


class Profile(BaseModel):
    """User profile information nested structure."""
    first_name: Optional[constr(max_length=100)] = None
    last_name: Optional[constr(max_length=100)] = None
    phone: Optional[PhoneNumber] = None
    timezone: Optional[Timezone] = None
    country: Optional[CountryCode] = None
    avatar_url: Optional[constr(max_length=500)] = None
    bio: Optional[constr(max_length=1000)] = None

    @model_validator(mode="after")
    def validate_phone_format(cls, model):
        """Validate phone number format."""
        if model.phone is not None:
            # Remove common formatting characters for validation
            cleaned = model.phone.replace(' ', '').replace('-', '').replace('(', '').replace(')', '')
            if len(cleaned) < 10:
                raise ValueError('Phone number must have at least 10 digits')
        return model


class AuthSecurity(BaseModel):
    """Authentication and security settings nested structure."""
    mfa_enabled: Optional[bool] = Field(False, description="Multi-factor authentication enabled")
    failed_login_attempts: Optional[conint(ge=0, le=10)] = Field(0, description="Failed login attempt count")
    locked_until: Optional[datetime] = Field(None, description="Account lock expiration timestamp")
    last_password_change: Optional[datetime] = None
    security_question_hash: Optional[constr(max_length=255)] = None

    @model_validator(mode="after")
    def validate_lock_with_failed_attempts(cls, model):
        """Locked users must have locked_until timestamp when failed attempts >= 5."""
        failed_attempts = model.failed_login_attempts or 0
        if failed_attempts >= 5 and model.locked_until is None:
            raise ValueError('locked_until must be set when failed_login_attempts >= 5')
        return model


class Preferences(BaseModel):
    """User preferences and settings."""
    language: Optional[constr(max_length=10)] = Field('en', description="Language preference (ISO 639-1)")
    date_format: Optional[constr(max_length=20)] = Field('YYYY-MM-DD', description="Preferred date format")
    time_format: Optional[constr(max_length=10)] = Field('24h', description="12h or 24h time format")
    notifications_email: Optional[bool] = Field(True, description="Email notifications enabled")
    notifications_sms: Optional[bool] = Field(False, description="SMS notifications enabled")
    notifications_push: Optional[bool] = Field(True, description="Push notifications enabled")
    theme: Optional[constr(max_length=20)] = Field('light', description="UI theme preference")


class Users(BaseModel):
    """
    Core user authentication and profile data with nested structures.

    Example:
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "john.doe@example.com",
            "email_verified": true,
            "email_verified_at": "2025-09-16T10:30:00Z",
            "password_hash": "$2b$12$LQv3c1yqBwsyqFJK5F8Q7OG7mYwB3vJ6nP8nE7qA1rR2sL9uH8wX.",
            "user_type": "customer",
            "profile": {
                "first_name": "John",
                "last_name": "Doe",
                "phone": "+1-555-123-4567",
                "timezone": "America/New_York",
                "country": "US"
            },
            "auth": {
                "mfa_enabled": true,
                "failed_login_attempts": 0,
                "locked_until": null
            },
            "preferences": {
                "language": "en",
                "notifications_email": true,
                "theme": "dark"
            },
            "last_login_at": "2025-09-16T09:15:00Z",
            "is_active": true,
            "created_at": "2025-09-15T14:22:00Z",
            "updated_at": "2025-09-16T10:30:00Z"
        }
    """

    model_config = ConfigDict(
        extra='forbid',
        validate_assignment=True,
        str_strip_whitespace=True,
        json_encoders={
            datetime: lambda v: v.isoformat()
        }
    )

    # Primary identification
    id: UUID = Field(..., description="Primary key - UUID v4")
    email: Email = Field(..., description="User email address - unique")

    # Email verification
    email_verified: Optional[bool] = Field(False, description="Email verification status")
    email_verified_at: Optional[datetime] = Field(None, description="Email verification timestamp")

    # Authentication
    password_hash: constr(min_length=60, max_length=255) = Field(
        ..., description="Bcrypt password hash - minimum 60 characters"
    )
    user_type: UserType = Field(..., description="User role/type")

    # Nested structures
    profile: Optional[Profile] = None
    auth: Optional[AuthSecurity] = None
    preferences: Optional[Preferences] = None

    # Activity tracking
    last_login_at: Optional[datetime] = Field(None, description="Last successful login timestamp")
    is_active: Optional[bool] = Field(True, description="Account active status")

    # Metadata
    notes: Optional[constr(max_length=1000)] = None

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    @field_validator('password_hash')
    def validate_bcrypt_hash(cls, v):
        """Validate bcrypt hash format."""
        if v and not v.startswith('$2b$') and not v.startswith('$2a$') and not v.startswith('$2y$'):
            raise ValueError('Password hash must be a valid bcrypt hash')
        return v

    @model_validator(mode="after")
    def validate_email_verification_consistency(cls, model):
        """email_verified_at must be set when email_verified is true."""
        email_verified = model.email_verified or 0
        email_verified_at = model.email_verified_at
        created_at = model.created_at

        if email_verified and email_verified_at is None:
            raise ValueError('email_verified_at must be set when email_verified is true')

        if email_verified_at and created_at and email_verified_at < created_at:
            raise ValueError('email_verified_at cannot be before created_at')

        return model

    @model_validator(mode="after")
    def validate_login_tracking(cls, model):
        """Last login must be after account creation."""
        last_login_at = model.last_login_at
        created_at = model.created_at

        if last_login_at and created_at and last_login_at < created_at:
            raise ValueError('last_login_at cannot be before created_at')

        return model

    @model_validator(mode="after")
    def validate_deleted_user_inactive(cls, model):
        """Deleted users cannot be active."""
        deleted_at = model.deleted_at
        is_active = model.is_active

        if deleted_at is not None and is_active is True:
            raise ValueError('Deleted users cannot be active')

        return model

    # Note: Cross-field validation for timestamps would go here

    @model_validator(mode="after")
    def validate_user_type_permissions(cls, model):
        """Additional validation for specific user types."""
        valid_types = ['customer', 'technician', 'administrator', 'shop_owner', 'fleet_manager']
        if model.user_type and model.user_type not in valid_types:
            raise ValueError(f'Invalid user type. Must be one of: {valid_types}')
        return model


class UsersCreate(BaseModel):
    """Model for creating new users."""
    email: Email = Field(..., description="User email address")
    password: constr(min_length=8, max_length=128) = Field(..., description="Plain text password (will be hashed)")
    user_type: UserType = Field(..., description="User role/type")
    profile: Optional[Profile] = None
    preferences: Optional[Preferences] = None
    is_active: Optional[bool] = Field(True, description="Account active status")

    @model_validator(mode="after")
    def validate_password_strength(cls, model):
        """Validate password strength requirements."""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')

        # Check for various character types
        has_lower = any(c.islower() for c in v)
        has_upper = any(c.isupper() for c in v)
        has_digit = any(c.isdigit() for c in v)
        has_special = any(c in '!@#$%^&*()_+-=[]{}|;:,.<>?' for c in v)

        strength_score = sum([has_lower, has_upper, has_digit, has_special])

        if strength_score < 3:
            raise ValueError(
                'Password must contain at least 3 of: lowercase, uppercase, digit, special character'
            )

        return model


class UsersUpdate(BaseModel):
    """Model for updating user information."""
    email: Optional[Email] = None
    email_verified: Optional[bool] = None
    email_verified_at: Optional[datetime] = None
    user_type: Optional[UserType] = None
    profile: Optional[Profile] = None
    auth: Optional[AuthSecurity] = None
    preferences: Optional[Preferences] = None
    last_login_at: Optional[datetime] = None
    is_active: Optional[bool] = None
    notes: Optional[constr(max_length=1000)] = None
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class UsersPasswordChange(BaseModel):
    """Model for password change operations."""
    current_password: constr(min_length=1, max_length=128) = Field(..., description="Current password for verification")
    new_password: constr(min_length=8, max_length=128) = Field(..., description="New password")

    @model_validator(mode="after")
    def validate_new_password_strength(cls, model):
        """Validate new password strength."""
        if len(v) < 8:
            raise ValueError('New password must be at least 8 characters long')

        has_lower = any(c.islower() for c in v)
        has_upper = any(c.isupper() for c in v)
        has_digit = any(c.isdigit() for c in v)
        has_special = any(c in '!@#$%^&*()_+-=[]{}|;:,.<>?' for c in v)

        strength_score = sum([has_lower, has_upper, has_digit, has_special])

        if strength_score < 3:
            raise ValueError(
                'New password must contain at least 3 of: lowercase, uppercase, digit, special character'
            )

        return model

    @model_validator(mode="after")
    def validate_passwords_different(cls, model):
        """New password must be different from current password."""
        current = model.current_password
        new = model.new_password

        if current and new and current == new:
            raise ValueError('New password must be different from current password')

        return model


class UsersResponse(Users):
    """Model for API responses - excludes sensitive fields."""
    password_hash: Optional[str] = Field(None, exclude=True)  # Exclude from serialization

    @property
    def display_name(self) -> str:
        """Generate human-readable display name."""
        if self.profile and (self.profile.first_name or self.profile.last_name):
            parts = []
            if self.profile.first_name:
                parts.append(self.profile.first_name)
            if self.profile.last_name:
                parts.append(self.profile.last_name)
            return ' '.join(parts)
        return self.email.split('@')[0]  # Use email username as fallback

    @property
    def account_age_days(self) -> int:
        """Calculate account age in days."""
        return (datetime.utcnow() - self.created_at).days

    @property
    def is_verified(self) -> bool:
        """Check if user email is verified."""
        return bool(self.email_verified)


class UsersLogin(BaseModel):
    """Model for user login requests."""
    email: Email = Field(..., description="User email address")
    password: constr(min_length=1, max_length=128) = Field(..., description="User password")
    remember_me: Optional[bool] = Field(False, description="Extended session duration")


class UsersLoginResponse(BaseModel):
    """Model for login response."""
    user: UsersResponse
    access_token: str = Field(..., description="JWT access token")
    refresh_token: Optional[str] = Field(None, description="JWT refresh token")
    expires_at: datetime = Field(..., description="Token expiration timestamp")
    token_type: str = Field('Bearer', description="Token type")