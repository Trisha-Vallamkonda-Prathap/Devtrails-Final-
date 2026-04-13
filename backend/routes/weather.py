from fastapi import APIRouter
import datetime

router = APIRouter()

@router.get("/conditions")
async def get_weather_conditions(zone: str):
    """Returns a mock list of weather triggers and an AI insight."""
    return {
        "triggers": [
            {
                "id": "rain",
                "type": 0,
                "currentValue": 14.0,
                "threshold": 20.0,
                "unit": "mm/2hr",
                "isTriggered": False,
                "zone": zone,
                "detectedAt": datetime.datetime.now().isoformat(),
            },
            {
                "id": "heat",
                "type": 1,
                "currentValue": 38.0,
                "threshold": 42.0,
                "unit": "°C",
                "isTriggered": False,
                "zone": zone,
                "detectedAt": datetime.datetime.now().isoformat(),
            },
            {
                "id": "aqi",
                "type": 4,
                "currentValue": 142.0,
                "threshold": 400.0,
                "unit": "AQI",
                "isTriggered": False,
                "zone": zone,
                "detectedAt": datetime.datetime.now().isoformat(),
            }
        ],
        "aiInsight": "Rainfall nearing threshold. Risk of disruption in ~40 min."
    }

@router.post("/simulate-rain")
async def simulate_rain_event(zone: str):
    """Returns a mock response with a triggered rain event."""
    return {
        "triggers": [
            {
                "id": "rain",
                "type": 0,
                "currentValue": 26.0,
                "threshold": 20.0,
                "unit": "mm/2hr",
                "isTriggered": True,
                "zone": zone,
                "detectedAt": datetime.datetime.now().isoformat(),
            },
            {
                "id": "heat",
                "type": 1,
                "currentValue": 38.0,
                "threshold": 42.0,
                "unit": "°C",
                "isTriggered": False,
                "zone": zone,
                "detectedAt": datetime.datetime.now().isoformat(),
            },
            {
                "id": "aqi",
                "type": 4,
                "currentValue": 142.0,
                "threshold": 400.0,
                "unit": "AQI",
                "isTriggered": False,
                "zone": zone,
                "detectedAt": datetime.datetime.now().isoformat(),
            }
        ],
        "aiInsight": "Rainfall TRIGGERED. High disruption expected."
    }
