from typing import List, Tuple
from datetime import datetime
from geopy.distance import geodesic
from sqlalchemy.orm import Session

# 備用碳排係數 (以防資料庫查詢失敗時的後備方案)
BACKUP_CARBON_FACTORS = {
    "motorcycle": 0.055,
    "mrt": 0.005,
    "bus": 0.030,
    "walk": 0.0,
    "bike": 0.0,
}

# 台北主要捷運站坐標定義，用於自動偵測起訖點是否鄰近捷運站
MRT_STATIONS = {
    "Zhongxiao_Xinsheng": (25.0423, 121.5358),
    "Zhongxiao_Fuxing": (25.0416, 121.5438),
    "Zhongxiao_Dunhua": (25.0413, 121.5478),
    "Sun_Yat_Sen_Memorial_Hall": (25.0413, 121.5583),
    "Taipei_City_Hall": (25.0412, 121.5652),
    "Yongchun": (25.0410, 121.5762),
    "Houshanpi": (25.0450, 121.5815),
    "Kunyang": (25.0505, 121.5933),
    "Nangang": (25.0521, 121.6068),
    "Nangang_Exhibition_Center": (25.0572, 121.6160),
    "Shandao_Temple": (25.0446, 121.5228),
    "Taipei_Main_Station": (25.0463, 121.5178),
    "Ximen": (25.0422, 121.5083),
    "Longshan_Temple": (25.0354, 121.4996),
    "Jiangzicui": (25.0302, 121.4796),
    "Xinpu": (25.0260, 121.4682),
    "Banqiao": (25.0136, 121.4621),
    "Fuzhong": (25.0086, 121.4594),
    "Songjiang_Nanjing": (25.0519, 121.5332),
    "Nanjing_Fuxing": (25.0519, 121.5434),
    "Dongmen": (25.0338, 121.5288),
    "Guting": (25.0263, 121.5228),
    "Daan": (25.0329, 121.5435),
    "Technology_Building": (25.0262, 121.5434),
    "Gongguan": (25.0130, 121.5342),
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
    def filter_unreasonable_points(points, max_speed_kmh: float = 120.0):
        """
        過濾不合理的 GPS 點 (時速大於 max_speed_kmh，或時間差為 0 或負)
        """
        if len(points) < 2:
            return points

        # 依記錄時間排序點位
        sorted_points = sorted(points, key=lambda p: p.recorded_at)
        filtered = [sorted_points[0]]

        for p in sorted_points[1:]:
            p_prev = filtered[-1]
            time_diff = (p.recorded_at - p_prev.recorded_at).total_seconds()
            
            # 若時間間隔為 0 或為負，視為無效或異常重複點，予以排除
            if time_diff <= 0:
                continue
            
            # 計算與前一個點的地理距離
            dist = geodesic((p_prev.latitude, p_prev.longitude), (p.latitude, p.longitude)).km
            
            # 計算這段移動的時速 (km/h)
            calculated_speed = dist / (time_diff / 3600.0)
            
            # 如果計算時速小於等於合理上限，則保留
            if calculated_speed <= max_speed_kmh:
                filtered.append(p)
                
        return filtered

    @staticmethod
    def calculate_duration_seconds(started_at: datetime, ended_at: datetime) -> int:
        """
        計算旅程持續時間 (秒)
        """
        if not started_at or not ended_at or ended_at < started_at:
            return 0
        return int((ended_at - started_at).total_seconds())

    @staticmethod
    def detect_transport_type(points, started_at: datetime, ended_at: datetime) -> str:
        """
        自動偵測交通工具類型。
        主要區分：mrt (捷運) 與其他 (other / motorcycle / bus / walk 等)。
        """
        if len(points) < 2:
            return "other"

        # 排序點位
        sorted_pts = sorted(points, key=lambda p: p.recorded_at)
        start_pt = sorted_pts[0]
        end_pt = sorted_pts[-1]
        
        # 計算總距離與持續時間
        total_dist = TripService.calculate_distance_km(sorted_pts)
        total_seconds = (ended_at - started_at).total_seconds()
        if total_seconds <= 0:
            return "other"
            
        avg_speed_kmh = total_dist / (total_seconds / 3600.0)
        
        # 1. 速度過慢排除 (步行或慢速騎車，非捷運)
        if avg_speed_kmh < 10.0:
            return "other"
            
        # 2. 檢查起點與終點是否鄰近捷運站 (350 公尺內)
        is_start_near_mrt = any(
            geodesic((start_pt.latitude, start_pt.longitude), station_coords).m <= 350 
            for station_coords in MRT_STATIONS.values()
        )
        is_end_near_mrt = any(
            geodesic((end_pt.latitude, end_pt.longitude), station_coords).m <= 350 
            for station_coords in MRT_STATIONS.values()
        )
        
        if not (is_start_near_mrt and is_end_near_mrt):
            return "other"
            
        # 3. 檢查是否有紅綠燈停等 (道路車輛特徵：在遠離捷運站 > 200m 的地方時速小於 1.8km/h)
        has_road_stop = False
        for pt in sorted_pts:
            is_stopped = (pt.speed is not None and pt.speed < 0.5)
            if is_stopped:
                near_any_station = any(
                    geodesic((pt.latitude, pt.longitude), station_coords).m <= 200
                    for station_coords in MRT_STATIONS.values()
                )
                if not near_any_station:
                    has_road_stop = True
                    break
                    
        if has_road_stop:
            return "other"
            
        # 4. 檢查 GPS 訊號斷訊特徵 (地下捷運特徵)
        max_time_gap = 0.0
        for i in range(len(sorted_pts) - 1):
            gap = (sorted_pts[i+1].recorded_at - sorted_pts[i].recorded_at).total_seconds()
            if gap > max_time_gap:
                max_time_gap = gap
                
        # 地下捷運斷訊特徵 (行駛隧道中通常有斷訊)
        if max_time_gap > 100.0:
            return "mrt"
            
        # 5. 高架捷運特徵 (如文湖線，速度較快且穩定)
        if 15.0 <= avg_speed_kmh <= 80.0:
            return "mrt"
            
        return "other"

    @staticmethod
    def calculate_carbon_metrics(db: Session, distance_km: float, transport_type: str) -> Tuple[float, float]:
        """
        計算實際碳排量與減碳量。
        僅計算「捷運」與「機車」比較的減碳量。其餘偵測結果皆不計入（回傳 0.0, 0.0）。
        """
        transport = (transport_type or "").lower().strip()
        
        # 僅有偵測為 mrt 時才可計入減碳，並與 motorcycle 進行比較
        if transport != "mrt":
            return 0.0, 0.0
            
        # 從資料庫查詢對應的碳排係數
        from app.models.trip import CarbonFactorModel
        
        # 取得機車的係數作為基準
        motorcycle_record = db.query(CarbonFactorModel).filter(CarbonFactorModel.transport_type == "motorcycle").first()
        motorcycle_factor = motorcycle_record.emission_factor if motorcycle_record else BACKUP_CARBON_FACTORS["motorcycle"]
        
        # 取得捷運的係數
        mrt_record = db.query(CarbonFactorModel).filter(CarbonFactorModel.transport_type == "mrt").first()
        mrt_factor = mrt_record.emission_factor if mrt_record else BACKUP_CARBON_FACTORS["mrt"]
        
        emission = distance_km * mrt_factor
        saved = max(0.0, (motorcycle_factor - mrt_factor) * distance_km)
            
        return round(emission, 4), round(saved, 4)



