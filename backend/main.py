import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

from routes import weather, risk, policy, payout, payment, auth

app = FastAPI(
    title="GigShield API",
    description="Mock backend for the GigShield Flutter application.",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(weather.router, prefix="/weather", tags=["Weather"])
app.include_router(risk.router, prefix="/risk", tags=["Risk"])
app.include_router(policy.router, prefix="/policy", tags=["Policy"])
app.include_router(payout.router, prefix="/payout", tags=["Payout"])
app.include_router(payment.router, prefix="/payment", tags=["Payment"])
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])

@app.get("/")
async def root():
    return {"status": "GigShield API running", "version": "2.0.0"}
