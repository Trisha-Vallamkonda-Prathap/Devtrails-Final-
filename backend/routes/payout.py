import asyncio
import datetime
import random
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

class PayoutActionRequest(BaseModel):
    payout_id: str
    worker_id: str
    account_number: str = ""
    ifsc: str = ""
    name: str = ""
    contact: str = ""
    email: str = ""

class TriggerPayoutRequest(BaseModel):
    worker_id: str
    zone: str
    trigger_type: str
    disrupted_hours: float

def get_mock_history(worker_id: str):
    now = datetime.datetime.now()
    return [
      {
        "id": "P001", "workerId": worker_id, "triggerType": 0, "amount": 390.0, 
        "status": 1, "triggeredAt": (now - datetime.timedelta(hours=2)).isoformat(),
        "zone": "Hebbal", "description": "Heavy rain 26mm/2hr", "transactionId": "GS-2024149"
      },
      {
        "id": "P002", "workerId": worker_id, "triggerType": 1, "amount": 175.0,
        "status": 1, "triggeredAt": (now - datetime.timedelta(days=1, hours=4)).isoformat(),
        "zone": "Hebbal", "description": "Heat index 43.2°C", "transactionId": "GS-2024148"
      },
      {
        "id": "P003", "workerId": worker_id, "triggerType": 3, "amount": 215.0,
        "status": 2, "triggeredAt": (now - datetime.timedelta(days=7, hours=1)).isoformat(),
        "zone": "Hebbal", "description": "Local zone closure", "transactionId": None
      },
      {
        "id": "P004", "workerId": worker_id, "triggerType": 0, "amount": 324.0,
        "status": 1, "triggeredAt": (now - datetime.timedelta(days=4, hours=8)).isoformat(),
        "zone": "Hebbal", "description": "Heavy rain 29mm/2hr", "transactionId": "GS-2024131"
      }
    ]

@router.get("/history")
async def get_payout_history(worker_id: str):
    """Returns a static list of mock payout history."""
    return get_mock_history(worker_id)

@router.post("/trigger")
async def trigger_payout(request: TriggerPayoutRequest):
    """Calculates and returns a new pending payout."""
    # This is a simplified calculation. A real backend would have worker earnings data.
    daily_avg = 5000 / 7 
    coefficients = {"rain": 0.50, "heat": 0.30, "flood": 1.00, "closure": 1.00, "aqi": 0.25}
    coefficient = coefficients.get(request.trigger_type, 0.3)
    
    raw_amount = daily_avg * coefficient * (request.disrupted_hours / 12)
    amount = round(raw_amount / 5) * 5.0

    return {
        "id": f"PENDING_{int(datetime.datetime.now().timestamp())}",
        "workerId": request.worker_id,
        "triggerType": list(coefficients.keys()).index(request.trigger_type),
        "amount": amount,
        "status": 0, # Pending
        "triggeredAt": datetime.datetime.now().isoformat(),
        "zone": request.zone,
        "description": f"Automatic trigger for {request.trigger_type}",
        "transactionId": None
    }

@router.post("/accept")
async def accept_payout(request: PayoutActionRequest):
    """Accepts a payout and initiates transfer if bank details provided."""
    await asyncio.sleep(1.2)  # Simulate processing time
    
    if request.account_number and request.ifsc:
        # Use Razorpay for real payout
        from .payment import client
        try:
            payout_data = {
                "account_number": request.account_number,
                "fund_account": {
                    "account_type": "bank_account",
                    "bank_account": {
                        "name": request.name,
                        "ifsc": request.ifsc,
                        "account_number": request.account_number
                    },
                    "contact": {
                        "name": request.name,
                        "contact": request.contact,
                        "email": request.email
                    }
                },
                "amount": 10000,  # Example amount in paisa, should be from payout
                "currency": "INR",
                "mode": "IMPS",
                "purpose": "payout",
                "queue_if_low_balance": True,
                "reference_id": f"payout_{request.worker_id}",
                "narration": "GigShield Payout"
            }
            payout = client.payout.create(data=payout_data)
            return {
                "status": "accepted",
                "transaction_id": payout['id'],
                "razorpay_payout_id": payout['id'],
                "settled_at": datetime.datetime.now().isoformat()
            }
        except Exception as e:
            return {"status": "failed", "error": str(e)}
    else:
        # Mock response
        return {
            "status": "accepted",
            "transaction_id": f"GS-{random.randint(1000000, 9999999)}",
            "upi_ref": f"UPI{random.randint(100000000, 999999999)}",
            "settled_at": datetime.datetime.now().isoformat()
        }

@router.post("/decline")
async def decline_payout(request: PayoutActionRequest):
    """Simulates declining a payout."""
    return {"status": "declined", "payout_id": request.payout_id}
