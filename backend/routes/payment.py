import razorpay
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os

router = APIRouter()

# Initialize Razorpay client
# Note: Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in environment variables
client = razorpay.Client(auth=(os.getenv("RAZORPAY_KEY_ID"), os.getenv("RAZORPAY_KEY_SECRET")))
client.set_app_details({"title": "GigShield", "version": "1.0.0"})

class CreateOrderRequest(BaseModel):
    amount: int  # Amount in paisa (e.g., 10000 for ₹100)
    currency: str = "INR"
    receipt: str
    notes: dict = {}

class PaymentVerificationRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str

class PayoutRequest(BaseModel):
    account_number: str
    ifsc: str
    amount: int  # in paisa
    name: str
    contact: str
    email: str = ""

@router.post("/create_order")
async def create_order(request: CreateOrderRequest):
    """Create a Razorpay order for payment."""
    try:
        order_data = {
            "amount": request.amount,
            "currency": request.currency,
            "receipt": request.receipt,
            "notes": request.notes
        }
        order = client.order.create(data=order_data)
        return order
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/verify_payment")
async def verify_payment(request: PaymentVerificationRequest):
    """Verify payment signature."""
    try:
        params_dict = {
            'razorpay_order_id': request.razorpay_order_id,
            'razorpay_payment_id': request.razorpay_payment_id,
            'razorpay_signature': request.razorpay_signature
        }
        client.utility.verify_payment_signature(params_dict)
        return {"status": "success", "message": "Payment verified"}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Payment verification failed")

@router.post("/payout")
async def initiate_payout(request: PayoutRequest):
    """Initiate a payout to a bank account."""
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
            "amount": request.amount,
            "currency": "INR",
            "mode": "IMPS",
            "purpose": "payout",
            "queue_if_low_balance": True,
            "reference_id": f"payout_{request.contact}",
            "narration": "GigShield Payout"
        }
        payout = client.payout.create(data=payout_data)
        return payout
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Webhook endpoint for payment events
@router.post("/webhook")
async def payment_webhook(data: dict):
    """Handle Razorpay webhooks."""
    # Verify webhook signature (implement signature verification)
    # For now, just log the event
    print("Webhook received:", data)
    return {"status": "ok"}