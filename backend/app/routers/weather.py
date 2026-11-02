from fastapi import APIRouter
from app.models.schemas import WeatherResponse
from app.services.weather_service import WeatherService

router = APIRouter(prefix="/weather", tags=["Weather Forecast"])

@router.get("/{district}", response_model=WeatherResponse)
async def get_weather(district: str):
    """Fetch localized weather forecast and agricultural climate advisories with timeout protection."""
    return await WeatherService.get_weather_forecast(district)
