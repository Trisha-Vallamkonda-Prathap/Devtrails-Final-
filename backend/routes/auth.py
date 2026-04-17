import random
import os
import asyncio
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
from datetime import datetime, timedelta

router = APIRouter()

# Twilio setup
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID", "")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN", "")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER", "")
OTP_FALLBACK_ENABLED = os.getenv("OTP_FALLBACK_ENABLED", "true").lower() == "true"
TWILIO_TEST_MODE = os.getenv("TWILIO_TEST_MODE", "false").lower() == "true"

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

def send_otp_via_twilio(phone: str, otp: str):
    """Send OTP via Twilio SMS"""
    try:
        # Only send if credentials are available
        if not TWILIO_ACCOUNT_SID or not TWILIO_AUTH_TOKEN or not TWILIO_PHONE_NUMBER:
            print(f"Twilio credentials not configured. Demo OTP for {phone}: {otp}")
            return True
        
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            body=f"Your GigShield OTP is: {otp}. Valid for 10 minutes.",
            from_=TWILIO_PHONE_NUMBER,
            to=phone
        )
        print(f"OTP sent to {phone}: {message.sid}")
        return True
    except TwilioRestException as e:
        print(f"Twilio API error while sending OTP to {phone}: {str(e)}")
        return False
    except Exception as e:
        print(f"Error sending OTP: {str(e)}")
        return False

@router.post("/send_otp")
async def send_otp(request: SendOtpRequest):
    """Send OTP to phone number"""
    normalized_phone = normalize_phone(request.phone)
    
    # Generate OTP
    otp = generate_otp()
    
    # Store OTP with expiry (10 minutes)
    expiry = datetime.now() + timedelta(minutes=10)
    otp_store[normalized_phone] = {"otp": otp, "expiry": expiry, "attempts": 0}

    # Send OTP with timeout guard to avoid hanging requests
    used_fallback = False
    if TWILIO_TEST_MODE:
        success = True
        used_fallback = True
    else:
        try:
            success = await asyncio.wait_for(
                asyncio.to_thread(send_otp_via_twilio, normalized_phone, otp),
                timeout=15,
            )
        except asyncio.TimeoutError:
            success = False

    if not success and OTP_FALLBACK_ENABLED:
        used_fallback = True
        success = True
    
    if not success:
        del otp_store[normalized_phone]
        raise HTTPException(status_code=500, detail="Failed to send OTP")

    response = {
        "status": "success",
        "message": "OTP sent to your phone number",
        "phone": normalized_phone
    }

    if used_fallback:
        if TWILIO_TEST_MODE:
            response["message"] = "OTP generated in Twilio test mode"
        else:
            response["message"] = "OTP generated in fallback mode"
        response["delivery"] = "fallback"
        response["debug_otp"] = otp

    return response

@router.post("/verify_otp")
async def verify_otp(request: VerifyOtpRequest):
    """Verify OTP"""
    normalized_phone = normalize_phone(request.phone)
    entered_otp = request.otp.strip()
    
    # Check if OTP exists for phone
    if normalized_phone not in otp_store:
        raise HTTPException(status_code=400, detail="OTP not found. Please request a new OTP.")

    otp_data = otp_store[normalized_phone]
    
    # Check attempts
    if otp_data["attempts"] >= 5:
        del otp_store[normalized_phone]
        raise HTTPException(status_code=400, detail="Too many attempts. Please request a new OTP.")
    
    # Check expiry
    if datetime.now() > otp_data["expiry"]:
        del otp_store[normalized_phone]
        raise HTTPException(status_code=400, detail="OTP expired. Please request a new OTP.")
    
    # Verify OTP
    if entered_otp != otp_data["otp"]:
        otp_data["attempts"] += 1
        raise HTTPException(status_code=400, detail="Incorrect OTP. Please try again.")
    
    # OTP verified successfully
    del otp_store[normalized_phone]
    
    return {
        "status": "success",
        "message": "OTP verified successfully",
        "phone": normalized_phone
    }

@router.post("/resend_otp")
async def resend_otp(request: SendOtpRequest):
    """Resend OTP"""
    normalized_phone = normalize_phone(request.phone)
    
    # Generate new OTP
    otp = generate_otp()
    
    # Store OTP with expiry (10 minutes)
    expiry = datetime.now() + timedelta(minutes=10)
    otp_store[normalized_phone] = {"otp": otp, "expiry": expiry, "attempts": 0}

    # Send OTP with timeout guard to avoid hanging requests
    used_fallback = False
    if TWILIO_TEST_MODE:
        success = True
        used_fallback = True
    else:
        try:
            success = await asyncio.wait_for(
                asyncio.to_thread(send_otp_via_twilio, normalized_phone, otp),
                timeout=15,
            )
        except asyncio.TimeoutError:
            success = False

    if not success and OTP_FALLBACK_ENABLED:
        used_fallback = True
        success = True
    
    if not success:
        del otp_store[normalized_phone]
        raise HTTPException(status_code=500, detail="Failed to send OTP")

    response = {
        "status": "success",
        "message": "OTP resent to your phone number",
        "phone": normalized_phone
    }

    if used_fallback:
        if TWILIO_TEST_MODE:
            response["message"] = "OTP regenerated in Twilio test mode"
        else:
            response["message"] = "OTP regenerated in fallback mode"
        response["delivery"] = "fallback"
        response["debug_otp"] = otp

    return response
