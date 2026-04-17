from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import datetime

router = APIRouter()

class PolicyPurchaseRequest(BaseModel):
    worker_id: str
    tier: str
    premium: float

# In-memory "database" for active policies
active_policies = {}

def get_premium(tier: str) -> float:
    return {"high": 120.0, "medium": 90.0, "low": 60.0}.get(tier, 90.0)

def get_coverage(tier: str) -> float:
    return {"high": 2500.0, "medium": 2240.0, "low": 2000.0}.get(tier, 2240.0)

@router.post("/purchase")
async def purchase_policy(request: PolicyPurchaseRequest):
    """Creates and returns a new active policy."""
    now = datetime.datetime.now()
    end_date = now + datetime.timedelta(days=7)
    
    policy = {
        "policy_id": f"POL_{int(now.timestamp())}",
        "worker_id": request.worker_id,
        "status": "active",
        "tier": request.tier,
        "start_date": now.isoformat(),
        "end_date": end_date.isoformat(),
        "weekly_premium": get_premium(request.tier),
        "coverage_limit": get_coverage(request.tier),
        "covered_events": ["rain", "heat", "flood", "closure", "aqi"]
    }
    active_policies[request.worker_id] = policy
    return policy

@router.get("/active")
async def get_active_policy(worker_id: str):
    """Returns the active policy for a worker, or 404 if not found."""
    policy = active_policies.get(worker_id)
    if not policy:
        raise HTTPException(status_code=404, detail="Active policy not found for this worker.")
    
    # Check if policy has expired
    end_date = datetime.datetime.fromisoformat(policy["end_date"])
    if datetime.datetime.now() > end_date:
        policy["status"] = "expired"

    return policy