from typing import List, Tuple
from datetime import datetime
from geopy.distance import geodesic

# 碳排係數 (kg CO2 / km)
CARBON_FACTORS = {
    "motorcycle": 0.055,
    "mrt": 0.005,
    "bus": 0.030,
    "walk": 0.0,
    "bike": 0.0,
}

class TripService:
    @staticmethod
    def calculate_distance_km(points) -> float:
        """
        傳入一組 GPS 點，計算並加總其間的地理距離 (公里)
        """
        if len(points) < 2:
            return 0.0
        
        # 依記錄時間排序點位，確保計算順序正確
        sorted_points = sorted(points, key=lambda p: p.recorded_at)
        
        total_distance = 0.0
        for i in range(len(sorted_points) - 1):
            p1 = sorted_points[i]
            p2 = sorted_points[i + 1]
            
            coord1 = (p1.latitude, p1.longitude)
            coord2 = (p2.latitude, p2.longitude)
            
            # 使用 geopy 計算測地線距離
            total_distance += geodesic(coord1, coord2).km
            
        return round(total_distance, 3)

    @staticmethod
    def calculate_duration_seconds(started_at: datetime, ended_at: datetime) -> int:
        """
        計算旅程持續時間 (秒)
        """
        if not started_at or not ended_at or ended_at < started_at:
            return 0
        return int((ended_at - started_at).total_seconds())

    @staticmethod
    def calculate_carbon_metrics(distance_km: float, transport_type: str) -> Tuple[float, float]:
        """
        計算實際碳排量與減碳量。
        以「機車」做為基準。
        """
        # 標準化交通方式名稱
        transport = (transport_type or "").lower().strip()
        
        # 若是「其他」或「不確定」或未填寫，不計入成果， emission / saved 皆設為 0
        if transport in ["other", "uncertain", "unknown", "其他", "不確定"] or not transport:
            return 0.0, 0.0
            
        motorcycle_factor = CARBON_FACTORS["motorcycle"]
        
        # 若交通工具不在預設列表中，則視為 0.0 直接碳排
        actual_factor = CARBON_FACTORS.get(transport, 0.0)
        
        emission = distance_km * actual_factor
        
        # 減碳量 = 機車基準碳排放 - 實際交通方式碳排放
        saved = max(0.0, (motorcycle_factor - actual_factor) * distance_km)
        
        return round(emission, 4), round(saved, 4)
