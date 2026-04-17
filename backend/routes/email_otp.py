from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
import random
import time
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

router = APIRouter()

# Simple in-memory OTP store
otp_store = {}

GMAIL_USER = os.getenv("GMAIL_USER")
GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD")


class SendOtpRequest(BaseModel):
    email: str


class VerifyOtpRequest(BaseModel):
    email: str
    otp: str


def generate_otp():
    return str(random.randint(100000, 999999))


def send_email_otp(receiver_email: str, otp: str):
    if not GMAIL_USER or not GMAIL_APP_PASSWORD:
        raise Exception("Missing Gmail credentials in .env")

    subject = "Your GigShield OTP"
    body = f"Your OTP is {otp}. It will expire in 5 minutes."

    msg = MIMEMultipart()
    msg["From"] = GMAIL_USER
    msg["To"] = receiver_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    with smtplib.SMTP("smtp.gmail.com", 587) as server:
        server.starttls()
        server.login(GMAIL_USER, GMAIL_APP_PASSWORD)
        server.sendmail(GMAIL_USER, receiver_email, msg.as_string())


@router.post("/send-email-otp")
async def send_email_otp_route(request: SendOtpRequest):
    try:
        otp = generate_otp()
        expiry = time.time() + 300  # 5 minutes

        otp_store[request.email] = {
            "otp": otp,
            "expiry": expiry
        }

        send_email_otp(request.email, otp)

        return {"message": "OTP sent successfully"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/verify-email-otp")
async def verify_email_otp_route(request: VerifyOtpRequest):
    record = otp_store.get(request.email)

    if not record:
        raise HTTPException(status_code=400, detail="No OTP found for this email")

    if time.time() > record["expiry"]:
        del otp_store[request.email]
        raise HTTPException(status_code=400, detail="OTP expired")

    if record["otp"] != request.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    del otp_store[request.email]
    return {"message": "OTP verified successfully"}