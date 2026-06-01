from pydantic import BaseModel, Field
from datetime import datetime
from typing import List, Optional

# GPS 點上傳與輸出結構
class GPSPointCreate(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="緯度")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="經度")
    speed: Optional[float] = Field(None, ge=0.0, description="速度 (m/s 或 km/h)")
    recorded_at: datetime = Field(..., description="記錄時間戳記")

class GPSPointsUpload(BaseModel):
    points: List[GPSPointCreate] = Field(..., description="GPS 座標點列表")

class GPSPointOut(BaseModel):
    id: int
    trip_id: int
    latitude: float
    longitude: float
    speed: Optional[float]
    recorded_at: datetime

    class Config:
        from_attributes = True

# 旅程開始結構
class TripStart(BaseModel):
    started_at: Optional[datetime] = Field(None, description="旅程開始時間，預設為伺服器時間")

class TripStartOut(BaseModel):
    trip_id: int
    started_at: datetime
    message: str

# 旅程結束結構
class TripEnd(BaseModel):
    ended_at: datetime = Field(..., description="旅程結束時間")
    transport_type: str = Field(..., description="使用者手動選擇的交通方式")

# 旅程回傳結構
class TripOut(BaseModel):
    id: int
    user_id: int
    started_at: datetime
    ended_at: Optional[datetime]
    distance_km: float
    duration_seconds: int
    transport_type: Optional[str]
    confidence_score: float
    carbon_emission: float
    carbon_saved: float
    region: str
    city: str
    created_at: datetime

    class Config:
        from_attributes = True

# 旅程詳細回傳結構 (包含 GPS 點)
class TripDetailOut(TripOut):
    points: List[GPSPointOut] = []

    class Config:
        from_attributes = True
