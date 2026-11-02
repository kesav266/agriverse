import asyncio
from datetime import datetime, timezone
from typing import Any, Dict

import httpx

from app.core.config import settings
from app.core.exceptions import AgriVerseException
from app.core.logging import logger
from app.models.schemas import WeatherForecastPoint, WeatherResponse


class WeatherService:
    BASE_URL = "https://api.openweathermap.org"

    @classmethod
    async def get_weather_forecast(cls, district: str) -> WeatherResponse:
        if not settings.WEATHER_API_KEY:
            raise AgriVerseException(
                "Weather provider is not configured. Set WEATHER_API_KEY on the backend.",
                status_code=503,
                error_code="WEATHER_NOT_CONFIGURED",
            )

        timeout = httpx.Timeout(settings.WEATHER_REQUEST_TIMEOUT_SECONDS)
        async with httpx.AsyncClient(timeout=timeout) as client:
            location = await cls._get_json(
                client,
                "/geo/1.0/direct",
                {"q": f"{district},IN", "limit": 1, "appid": settings.WEATHER_API_KEY},
            )
            if not isinstance(location, list) or not location:
                raise AgriVerseException(
                    "The weather provider could not resolve this district.",
                    status_code=404,
                    error_code="WEATHER_LOCATION_NOT_FOUND",
                )
            latitude = location[0].get("lat")
            longitude = location[0].get("lon")
            if latitude is None or longitude is None:
                raise cls._provider_error()

            params = {
                "lat": latitude,
                "lon": longitude,
                "appid": settings.WEATHER_API_KEY,
                "units": "metric",
            }
            current, forecast = await asyncio.gather(
                cls._get_json(client, "/data/2.5/weather", params),
                cls._get_json(client, "/data/2.5/forecast", {**params, "cnt": 40}),
            )

        try:
            current_main = current["main"]
            current_condition = current["weather"][0]["description"].strip().title()
            observed_at = datetime.fromtimestamp(current["dt"], tz=timezone.utc)
            points = [
                WeatherForecastPoint(
                    timestamp=datetime.fromtimestamp(item["dt"], tz=timezone.utc),
                    temperature_celsius=float(item["main"]["temp"]),
                    rainfall_mm=cls._rainfall(item.get("rain"), "3h"),
                    forecast_condition=item["weather"][0]["description"].strip().title(),
                )
                for item in forecast.get("list", [])
                if item.get("dt") is not None
                and item.get("main", {}).get("temp") is not None
                and item.get("weather")
            ]
            forecast_rain = [p.rainfall_mm for p in points[:8] if p.rainfall_mm is not None]
            advisory_en, advisory_te = cls._advisory(
                float(current_main["temp"]), max(forecast_rain) if forecast_rain else None
            )
            return WeatherResponse(
                district=(location[0].get("name") or district).strip(),
                temperature_celsius=float(current_main["temp"]),
                humidity_percentage=(float(current_main["humidity"]) if current_main.get("humidity") is not None else None),
                rainfall_mm=cls._rainfall(current.get("rain"), "1h"),
                wind_speed_kmh=(round(float(current["wind"]["speed"]) * 3.6, 1) if current.get("wind", {}).get("speed") is not None else None),
                forecast_condition=current_condition,
                advisory_en=advisory_en,
                advisory_te=advisory_te,
                data_source="OpenWeather Current Weather and 5-day/3-hour Forecast",
                recorded_at=observed_at,
                forecast=points,
            )
        except (KeyError, IndexError, TypeError, ValueError):
            raise cls._provider_error()

    @classmethod
    async def _get_json(
        cls,
        client: httpx.AsyncClient,
        path: str,
        params: Dict[str, Any],
    ) -> Any:
        for attempt in range(2):
            try:
                response = await client.get(f"{cls.BASE_URL}{path}", params=params)
                if response.status_code in {401, 403}:
                    raise AgriVerseException(
                        "Weather provider rejected its configured credentials.",
                        status_code=503,
                        error_code="WEATHER_PROVIDER_AUTH_FAILED",
                    )
                if response.status_code == 404:
                    raise AgriVerseException(
                        "The weather provider could not find this location.",
                        status_code=404,
                        error_code="WEATHER_LOCATION_NOT_FOUND",
                    )
                if response.status_code == 429:
                    if attempt == 0:
                        await asyncio.sleep(0.2)
                        continue
                    raise cls._provider_error()
                if response.status_code < 500:
                    try:
                        response.raise_for_status()
                    except httpx.HTTPStatusError:
                        raise cls._provider_error()
                    return response.json()
                if attempt == 0:
                    await asyncio.sleep(0.2)
                    continue
                raise cls._provider_error()
            except AgriVerseException:
                raise
            except (httpx.TimeoutException, httpx.TransportError, ValueError):
                if attempt == 0:
                    await asyncio.sleep(0.2)
                    continue
                logger.warning("Weather provider request failed (%s)", path)
                raise cls._provider_error()
        raise cls._provider_error()

    @staticmethod
    def _rainfall(raw: Any, period: str) -> float | None:
        if not isinstance(raw, dict) or raw.get(period) is None:
            return None
        try:
            return max(0.0, float(raw[period]))
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _advisory(temperature: float, forecast_rain_mm: float | None) -> tuple[str, str]:
        if forecast_rain_mm is not None and forecast_rain_mm >= 10:
            return (
                "The provider forecast shows notable rainfall in the next 24 hours. Check local field conditions and drainage before irrigation or spraying.",
                "వచ్చే 24 గంటల్లో వర్ష సూచన ఉంది. నీరు పెట్టడం లేదా పిచికారీకి ముందు పొలం పరిస్థితి, నీటి పారుదలను పరిశీలించండి.",
            )
        if temperature >= 36:
            return (
                "The current provider observation is hot. Monitor crop stress and check locally recommended irrigation timing.",
                "ప్రస్తుత వాతావరణ పరిశీలనలో వేడి ఎక్కువగా ఉంది. పంట ఒత్తిడిని గమనించి, స్థానికంగా సూచించిన నీటి సమయాన్ని తెలుసుకోండి.",
            )
        return (
            "Use the timestamped local forecast together with field observations. This advisory does not replace a farm-specific assessment.",
            "సమయంతో ఉన్న స్థానిక వర్ష సూచనను పొలం పరిశీలనతో కలిపి చూడండి. ఈ సలహా పొలం-ప్రత్యేక అంచనాకు ప్రత్యామ్నాయం కాదు.",
        )

    @staticmethod
    def _provider_error() -> AgriVerseException:
        return AgriVerseException(
            "Weather data is temporarily unavailable from the configured provider.",
            status_code=503,
            error_code="WEATHER_PROVIDER_UNAVAILABLE",
        )
