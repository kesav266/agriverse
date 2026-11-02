from fastapi import HTTPException, status
from typing import Any, Optional

class AgriVerseException(HTTPException):
    def __init__(self, detail: str, status_code: int = status.HTTP_400_BAD_REQUEST, error_code: str = "BAD_REQUEST", details: Optional[Any] = None):
        super().__init__(status_code=status_code, detail=detail)
        self.error_code = error_code
        self.details = details

class InvalidCredentialsException(AgriVerseException):
    def __init__(self, detail: str = "Invalid phone number or password"):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_401_UNAUTHORIZED,
            error_code="INVALID_CREDENTIALS"
        )

class UnauthorizedException(AgriVerseException):
    def __init__(self, detail: str = "Authentication credentials required or invalid"):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_401_UNAUTHORIZED,
            error_code="UNAUTHORIZED"
        )

class PermissionDeniedException(AgriVerseException):
    def __init__(self, detail: str = "You do not have permission to access or modify this resource"):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_403_FORBIDDEN,
            error_code="FORBIDDEN"
        )

class ProfileNotFoundException(AgriVerseException):
    def __init__(self, identifier: str):
        super().__init__(
            detail=f"Farmer profile '{identifier}' not found",
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="PROFILE_NOT_FOUND"
        )

class FarmNotFoundException(AgriVerseException):
    def __init__(self, farm_id: str):
        super().__init__(
            detail=f"Farm land with ID '{farm_id}' not found",
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="FARM_NOT_FOUND"
        )

class CropCycleNotFoundException(AgriVerseException):
    def __init__(self, cycle_id: str):
        super().__init__(
            detail=f"Crop cycle with ID '{cycle_id}' not found",
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="CROP_CYCLE_NOT_FOUND"
        )

class DuplicateResourceException(AgriVerseException):
    def __init__(self, detail: str):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_409_CONFLICT,
            error_code="DUPLICATE_RESOURCE"
        )
