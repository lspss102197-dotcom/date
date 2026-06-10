import datetime
from fastapi import FastAPI, Depends
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.api.routes import auth, trips
from app.models.user import Base, UserModel
from app.models.trip import TripModel, GPSPointModel

def test_trip_full_lifecycle(tmp_path):
    # 建立測試資料庫
    database_url = f"sqlite:///{tmp_path / 'trips.db'}"
    engine = create_engine(database_url, connect_args={"check_same_thread": False})
    testing_session_local = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=engine,
    )
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = testing_session_local()
        try:
            yield db
        finally:
            db.close()

    # 建立測試用的 FastAPI App
    app = FastAPI()
    app.include_router(auth.router)
    app.include_router(trips.router)
    
    app.dependency_overrides[auth.get_db] = override_get_db
    app.dependency_overrides[trips.get_db] = override_get_db
    
    client = TestClient(app)

    # 1. 註冊並登入兩個使用者 (User A 與 User B)
    client.post("/api/auth/register", json={
        "username": "user-a",
        "email": "user-a@example.com",
        "password": "password123"
    })
    client.post("/api/auth/register", json={
        "username": "user-b",
        "email": "user-b@example.com",
        "password": "password123"
    })

    login_a = client.post("/api/auth/login", json={"username": "user-a", "password": "password123"}).json()
    login_b = client.post("/api/auth/login", json={"username": "user-b", "password": "password123"}).json()
    
    token_a = login_a["access_token"]
    token_b = login_b["access_token"]
    
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # 2. User A 開始旅程
    started_time = datetime.datetime.utcnow() - datetime.timedelta(minutes=30)
    start_resp = client.post(
        "/api/trips/start",
        json={"started_at": started_time.isoformat()},
        headers=headers_a
    )
    assert start_resp.status_code == 201
    trip_id = start_resp.json()["trip_id"]

    # 3. User A 上傳 GPS 點 (沿著台北大安區一條直線，距離約 1.1 公里)
    # 北科大正門 (25.0423, 121.5358) -> 忠孝復興 (25.0416, 121.5438) -> 忠孝敦化 (25.0413, 121.5478)
    points = [
        {"latitude": 25.0423, "longitude": 121.5358, "speed": 1.5, "recorded_at": (started_time + datetime.timedelta(seconds=0)).isoformat()},
        {"latitude": 25.0416, "longitude": 121.5438, "speed": 2.0, "recorded_at": (started_time + datetime.timedelta(seconds=120)).isoformat()},
        {"latitude": 25.0413, "longitude": 121.5478, "speed": 1.8, "recorded_at": (started_time + datetime.timedelta(seconds=240)).isoformat()}
    ]
    
    pts_resp = client.post(
        f"/api/trips/{trip_id}/points",
        json={"points": points},
        headers=headers_a
    )
    assert pts_resp.status_code == 201
    assert pts_resp.json()["points_uploaded"] == 3

    # 4. User B 試圖上傳 GPS 點到 User A 的旅程 (應被拒絕 403)
    pts_unauth_resp = client.post(
        f"/api/trips/{trip_id}/points",
        json={"points": points},
        headers=headers_b
    )
    assert pts_unauth_resp.status_code == 403

    # 5. User A 結束旅程 (手動選擇捷運 "mrt")
    ended_time = started_time + datetime.timedelta(seconds=240) # 4分鐘
    end_resp = client.post(
        f"/api/trips/{trip_id}/end",
        json={
            "ended_at": ended_time.isoformat(),
            "transport_type": "mrt"
        },
        headers=headers_a
    )
    assert end_resp.status_code == 200
    res_data = end_resp.json()
    assert res_data["duration_seconds"] == 240
    assert res_data["distance_km"] > 1.0  # 大概 1.2 公里左右
    assert res_data["transport_type"] == "mrt"
    # mrt 碳足跡 = distance_km * 0.005, motorcycle = distance_km * 0.055, saved = distance_km * 0.050
    assert res_data["carbon_emission"] > 0.0
    assert res_data["carbon_saved"] > 0.0

    # 6. User A 重複結束旅程 (應被拒絕 400)
    end_repeat_resp = client.post(
        f"/api/trips/{trip_id}/end",
        json={
            "ended_at": ended_time.isoformat(),
            "transport_type": "mrt"
        },
        headers=headers_a
    )
    assert end_repeat_resp.status_code == 400

    # 7. 查詢單次旅程詳細內容
    detail_resp = client.get(f"/api/trips/{trip_id}", headers=headers_a)
    assert detail_resp.status_code == 200
    detail_data = detail_resp.json()
    assert len(detail_data["points"]) == 3
    assert detail_data["points"][0]["latitude"] == 25.0423

    # 8. User B 試圖查詢 User A 的旅程詳細 (應被拒絕 403)
    detail_unauth_resp = client.get(f"/api/trips/{trip_id}", headers=headers_b)
    assert detail_unauth_resp.status_code == 403

    # 9. 查詢旅程列表
    list_a_resp = client.get("/api/trips", headers=headers_a)
    assert list_a_resp.status_code == 200
    assert len(list_a_resp.json()) == 1
    
    list_b_resp = client.get("/api/trips", headers=headers_b)
    assert list_b_resp.status_code == 200
    assert len(list_b_resp.json()) == 0

    # 10. 刪除旅程並確認連帶刪除 GPS 點
    delete_resp = client.delete(f"/api/trips/{trip_id}", headers=headers_a)
    assert delete_resp.status_code == 200
    
    # 用獨立 Session 確認資料表完全清空
    db = testing_session_local()
    assert db.query(TripModel).filter(TripModel.id == trip_id).first() is None
    assert db.query(GPSPointModel).filter(GPSPointModel.trip_id == trip_id).count() == 0
    db.close()


def test_trip_gps_filtering_and_db_carbon_factors(tmp_path):
    # 建立測試資料庫
    database_url = f"sqlite:///{tmp_path / 'trips_filter.db'}"
    engine = create_engine(database_url, connect_args={"check_same_thread": False})
    testing_session_local = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=engine,
    )
    Base.metadata.create_all(bind=engine)
    
    # 寫入測試專用 carbon_factors
    db = testing_session_local()
    from app.models.trip import CarbonFactorModel
    db.add(CarbonFactorModel(transport_type="motorcycle", emission_factor=0.06, created_at=datetime.datetime.utcnow()))
    db.add(CarbonFactorModel(transport_type="mrt", emission_factor=0.01, created_at=datetime.datetime.utcnow()))
    db.commit()
    db.close()

    def override_get_db():
        db = testing_session_local()
        try:
            yield db
        finally:
            db.close()

    app = FastAPI()
    app.include_router(auth.router)
    app.include_router(trips.router)
    
    app.dependency_overrides[auth.get_db] = override_get_db
    app.dependency_overrides[trips.get_db] = override_get_db
    
    client = TestClient(app)

    # 註冊與登入
    client.post("/api/auth/register", json={
        "username": "tester",
        "email": "tester@example.com",
        "password": "password123"
    })
    login_resp = client.post("/api/auth/login", json={"username": "tester", "password": "password123"}).json()
    headers = {"Authorization": f"Bearer {login_resp['access_token']}"}

    # 開始旅程
    started_time = datetime.datetime.utcnow() - datetime.timedelta(minutes=10)
    start_resp = client.post(
        "/api/trips/start",
        json={"started_at": started_time.isoformat()},
        headers=headers
    )
    trip_id = start_resp.json()["trip_id"]

    # 點 1: 忠孝新生 (25.0423, 121.5358)
    # 點 2: 3秒後瞬移到台北車站（離經叛道跳點）
    # 點 3: 4分鐘後到忠孝復興 (25.0416, 121.5438)
    points = [
        {"latitude": 25.0423, "longitude": 121.5358, "speed": 1.0, "recorded_at": (started_time).isoformat()},
        {"latitude": 25.0463, "longitude": 121.5178, "speed": 1.0, "recorded_at": (started_time + datetime.timedelta(seconds=3)).isoformat()},
        {"latitude": 25.0416, "longitude": 121.5438, "speed": 1.0, "recorded_at": (started_time + datetime.timedelta(seconds=240)).isoformat()}
    ]
    
    client.post(
        f"/api/trips/{trip_id}/points",
        json={"points": points},
        headers=headers
    )

    # 結束旅程
    ended_time = started_time + datetime.timedelta(seconds=240)
    end_resp = client.post(
        f"/api/trips/{trip_id}/end",
        json={
            "ended_at": ended_time.isoformat(),
            "transport_type": "mrt"
        },
        headers=headers
    )
    
    assert end_resp.status_code == 200
    res_data = end_resp.json()
    
    # 點 2 (跳點) 應該被過濾且刪除，因此只剩 2 個點
    db = testing_session_local()
    remaining_points = db.query(GPSPointModel).filter(GPSPointModel.trip_id == trip_id).all()
    assert len(remaining_points) == 2
    # 驗證台北車站的點已經不在了
    lats = [p.latitude for p in remaining_points]
    assert 25.0463 not in lats
    db.close()
    
    # 驗證距離計算（只有點 1 到點 3，忠孝新生到忠孝復興約 0.8 公里）
    assert abs(res_data["distance_km"] - 0.811) <= 0.05

    
    # 驗證減碳量與碳排放是使用資料庫中的自訂係數計算的！
    # mrt: 0.01, motorcycle: 0.06
    # emission = distance * 0.01
    # saved = distance * (0.06 - 0.01) = distance * 0.05
    dist = res_data["distance_km"]
    assert abs(res_data["carbon_emission"] - dist * 0.01) <= 0.0002
    assert abs(res_data["carbon_saved"] - dist * 0.05) <= 0.0002


def test_trip_unsupported_transport_type(tmp_path):
    # 建立測試資料庫
    database_url = f"sqlite:///{tmp_path}/trips_unsupported.db"
    engine = create_engine(database_url, connect_args={"check_same_thread": False})
    testing_session_local = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=engine,
    )
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = testing_session_local()
        try:
            yield db
        finally:
            db.close()

    app = FastAPI()
    app.include_router(auth.router)
    app.include_router(trips.router)
    app.dependency_overrides[auth.get_db] = override_get_db
    app.dependency_overrides[trips.get_db] = override_get_db
    client = TestClient(app)

    # 註冊與登入
    client.post("/api/auth/register", json={"username": "tester", "email": "tester@example.com", "password": "password123"})
    login = client.post("/api/auth/login", json={"username": "tester", "password": "password123"}).json()
    headers = {"Authorization": f"Bearer {login['access_token']}"}

    # 開始旅程
    started_time = datetime.datetime.utcnow() - datetime.timedelta(minutes=10)
    start_resp = client.post("/api/trips/start", json={"started_at": started_time.isoformat()}, headers=headers)
    trip_id = start_resp.json()["trip_id"]

    # 上傳遠離任何捷運站的點位
    points = [
        {"latitude": 25.1000, "longitude": 121.3000, "speed": 5.0, "recorded_at": (started_time).isoformat()},
        {"latitude": 25.1050, "longitude": 121.3050, "speed": 5.0, "recorded_at": (started_time + datetime.timedelta(seconds=120)).isoformat()},
        {"latitude": 25.1100, "longitude": 121.3100, "speed": 5.0, "recorded_at": (started_time + datetime.timedelta(seconds=240)).isoformat()}
    ]
    client.post(f"/api/trips/{trip_id}/points", json={"points": points}, headers=headers)

    # 結束旅程
    ended_time = started_time + datetime.timedelta(seconds=240)
    end_resp = client.post(
        f"/api/trips/{trip_id}/end",
        json={
            "ended_at": ended_time.isoformat(),
            "transport_type": "bus"
        },
        headers=headers
    )
    assert end_resp.status_code == 200
    res_data = end_resp.json()
    # 驗證碳排與減碳量皆被設為 0.0
    assert res_data["carbon_emission"] == 0.0
    assert res_data["carbon_saved"] == 0.0



