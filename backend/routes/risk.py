from fastapi import APIRouter

router = APIRouter()

def get_tier_from_zone(zone: str):
    lower_zone = zone.lower()
    if "hebbal" in lower_zone or "koramangala" in lower_zone or "kurla" in lower_zone:
        return "high"
    if "dharavi" in lower_zone or "secunderabad" in lower_zone:
        return "medium"
    if "tambaram" in lower_zone:
        return "low"
    return "medium"

@router.get("/profile")
async def get_risk_profile(zone: str, city: str, platform: str):
    """Determines risk profile based on zone."""
    tier = get_tier_from_zone(zone)
    
    risk_data = {
        "high": {"score": 0.78, "reason": "Zone has high flood/waterlogging history during monsoon season."},
        "medium": {"score": 0.55, "reason": "Zone has moderate disruption history with manageable risk."},
        "low": {"score": 0.32, "reason": "Zone has stable delivery conditions with low historical disruptions."}
    }
    
    return {
        "zone": zone,
        "city": city,
        "platform": platform,
        "tier": tier,
        "risk_score": risk_data[tier]["score"],
        "risk_reasoning": risk_data[tier]["reason"]
    }
