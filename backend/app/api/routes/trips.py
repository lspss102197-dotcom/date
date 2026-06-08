from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import datetime
from typing import List
import os

from app.core.database import get_db
from app.api.routes.auth import get_current_user
from app.models.user import UserModel
from app.models.trip import TripModel, GPSPointModel
from app.schemas.trip import (
    TripStart, TripStartOut, GPSPointsUpload, TripEnd, TripOut, TripDetailOut
)
from app.services.trip_service import TripService

router = APIRouter(prefix="/api/trips", tags=["旅程紀錄"])

@router.post("/start", response_model=TripStartOut, status_code=status.HTTP_201_CREATED)
def start_trip(
    trip_data: TripStart,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    started_at = trip_data.started_at or datetime.datetime.utcnow()
    new_trip = TripModel(
        user_id=current_user.id,
        started_at=started_at,
        created_at=datetime.datetime.utcnow()
    )
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)
    return {
        "trip_id": new_trip.id,
        "started_at": new_trip.started_at,
        "message": "旅程已成功開始！"
    }

@router.post("/{trip_id}/points", status_code=status.HTTP_201_CREATED)
def upload_gps_points(
    trip_id: int,
    points_data: GPSPointsUpload,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    trip = db.query(TripModel).filter(TripModel.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="找不到此旅程")
    
    if trip.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="您無權編輯此旅程")
        
    if trip.ended_at is not None:
        raise HTTPException(status_code=400, detail="已結束的旅程無法再上傳 GPS 點")

    db_points = []
    for pt in points_data.points:
        db_point = GPSPointModel(
            trip_id=trip_id,
            latitude=pt.latitude,
            longitude=pt.longitude,
            speed=pt.speed,
            recorded_at=pt.recorded_at
        )
        db.add(db_point)
        db_points.append(db_point)
        
    db.commit()
    return {
        "message": "GPS 點上傳成功！",
        "points_uploaded": len(db_points)
    }

@router.post("/{trip_id}/end", response_model=TripOut)
def end_trip(
    trip_id: int,
    end_data: TripEnd,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    trip = db.query(TripModel).filter(TripModel.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="找不到此旅程")
        
    if trip.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="您無權編輯此旅程")
        
    if trip.ended_at is not None:
        raise HTTPException(status_code=400, detail="此旅程已經結束，無法重複結束")
        
    ended_at = end_data.ended_at.replace(tzinfo=None) if end_data.ended_at.tzinfo else end_data.ended_at
    if ended_at < trip.started_at:
        raise HTTPException(status_code=400, detail="結束時間不能早於開始時間")

    trip.ended_at = ended_at
    
    # 計算持續時間
    trip.duration_seconds = TripService.calculate_duration_seconds(trip.started_at, trip.ended_at)
    
    # 抓出此旅程所有已上傳的 GPS 點並進行過濾
    points = db.query(GPSPointModel).filter(GPSPointModel.trip_id == trip_id).all()
    
    # 讀取合理時速上限並過濾飄移點
    max_speed_kmh = float(os.getenv("GPS_MAX_REASONABLE_SPEED_KMH", "120.0"))
    filtered_points = TripService.filter_unreasonable_points(points, max_speed_kmh)
    
    # 從資料庫中刪除不合理的點位
    filtered_ids = {pt.id for pt in filtered_points}
    for pt in points:
        if pt.id not in filtered_ids:
            db.delete(pt)
            
    # 使用過濾後的點計算距離
    trip.distance_km = TripService.calculate_distance_km(filtered_points)
    
    # 自動偵測交通方式 (無視前端帶入的手動選項，以提升自動判定精準度)
    detected_transport = TripService.detect_transport_type(filtered_points, trip.started_at, trip.ended_at)
    trip.transport_type = detected_transport
    
    # 計算碳排與減碳量 (傳入 db 階段)
    emission, saved = TripService.calculate_carbon_metrics(db, trip.distance_km, detected_transport)
    trip.carbon_emission = emission
    trip.carbon_saved = saved
    
    db.commit()
    db.refresh(trip)
    return trip

@router.get("/", response_model=List[TripOut])
def list_trips(
    limit: int = 20,
    offset: int = 0,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    trips = db.query(TripModel)\
        .filter(TripModel.user_id == current_user.id)\
        .order_by(TripModel.started_at.desc())\
        .offset(offset)\
        .limit(limit)\
        .all()
    return trips

@router.get("/{trip_id}", response_model=TripDetailOut)
def get_trip_detail(
    trip_id: int,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    trip = db.query(TripModel).filter(TripModel.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="找不到此旅程")
        
    if trip.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="您無權存取此旅程")
        
    return trip

@router.delete("/{trip_id}")
def delete_trip(
    trip_id: int,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    trip = db.query(TripModel).filter(TripModel.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="找不到此旅程")
        
    if trip.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="您無權刪除此旅程")
        
    db.delete(trip)
    db.commit()
    return {"message": "旅程已成功刪除。"}
