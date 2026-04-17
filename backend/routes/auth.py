import random
import re
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime, timedelta

router = APIRouter()

# Store OTPs in memory (in production, use database)
otp_store = {}

class SendOtpRequest(BaseModel):
    phone: str

class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str


def normalize_phone(phone: str) -> str:
    """Normalize phone number to E.164-compatible format."""
    raw = phone.strip().replace(" ", "")

    # Accept local 10-digit Indian number
    if raw.isdigit() and len(raw) == 10:
        return f"+91{raw}"

    # Accept explicit international format like +14155552671
    if raw.startswith("+") and raw[1:].isdigit() and 8 <= len(raw[1:]) <= 15:
        return raw

    raise HTTPException(
        status_code=400,
        detail="Invalid phone number. Use 10-digit Indian number or international format like +14155552671.",
    )

def generate_otp():
    """Generate a 6-digit OTP"""
    return str(random.randint(100000, 999999))

@router.post("/send_otp")
async def send_otp(request: SendOtpRequest):
    """Generate OTP in dummy mode (no SMS provider)."""
    normalized_phone = normalize_phone(request.phone)
    
    # Generate OTP
    otp = generate_otp()
    
    # Store OTP with expiry (10 minutes)
    expiry = datetime.now() + timedelta(minutes=10)
    otp_store[normalized_phone] = {"otp": otp, "expiry": expiry, "attempts": 0}

    response = {
        "status": "success",
        "message": "Dummy OTP generated",
        "phone": normalized_phone,
        "delivery": "dummy",
        "debug_otp": otp,
    }

    return response

@router.post("/verify_otp")
async def verify_otp(request: VerifyOtpRequest):
    """Verify OTP"""
    normalized_phone = normalize_phone(request.phone)
    entered_otp = request.otp.strip()
    
    # Dummy OTP validation: accept any 6-digit value
    if not re.fullmatch(r"\d{6}", entered_otp):
        raise HTTPException(status_code=400, detail="Enter any 6-digit OTP")

    # Cleanup cached OTP for this phone if present.
    if normalized_phone in otp_store:
        del otp_store[normalized_phone]
    
    return {
        "status": "success",
        "message": "OTP verified successfully",
        "phone": normalized_phone
    }

@router.post("/resend_otp")
async def resend_otp(request: SendOtpRequest):
    """Regenerate OTP in dummy mode (no SMS provider)."""
    normalized_phone = normalize_phone(request.phone)
    
    # Generate new OTP
    otp = generate_otp()
    
    # Store OTP with expiry (10 minutes)
    expiry = datetime.now() + timedelta(minutes=10)
    otp_store[normalized_phone] = {"otp": otp, "expiry": expiry, "attempts": 0}

    response = {
        "status": "success",
        "message": "Dummy OTP regenerated",
        "phone": normalized_phone,
        "delivery": "dummy",
        "debug_otp": otp,
    }

    return response
