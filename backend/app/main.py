from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import engine, SessionLocal
from app.models.user import Base
# 匯入旅程相關 Model，確保自動建立資料表
from app.models.trip import TripModel, GPSPointModel, CarbonFactorModel
from app.api.routes import auth, trips
import datetime

# 開機時自動檢查並建立資料表
Base.metadata.create_all(bind=engine)

def seed_carbon_factors():
    db = SessionLocal()
    try:
        if db.query(CarbonFactorModel).count() == 0:
            default_factors = [
                {"transport_type": "motorcycle", "emission_factor": 0.055, "source_name": "環境部"},
                {"transport_type": "mrt", "emission_factor": 0.005, "source_name": "環境部"},
                {"transport_type": "bus", "emission_factor": 0.030, "source_name": "環境部"},
                {"transport_type": "walk", "emission_factor": 0.0, "source_name": "環境部"},
                {"transport_type": "bike", "emission_factor": 0.0, "source_name": "環境部"},
            ]
            for factor in default_factors:
                db_factor = CarbonFactorModel(
                    transport_type=factor["transport_type"],
                    emission_factor=factor["emission_factor"],
                    source_name=factor["source_name"],
                    created_at=datetime.datetime.utcnow()
                )
                db.add(db_factor)
            db.commit()
    except Exception as e:
        print(f"Error seeding carbon factors: {e}")
    finally:
        db.close()

seed_carbon_factors()


app = FastAPI(title="北科大捷運減碳養成系統 API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 重點：將拆出去的路由「掛載」進來
app.include_router(auth.router)
app.include_router(trips.router)

from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

# 統一錯誤格式 Exception Handlers
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": exc.status_code,
                "message": exc.detail
            }
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    errors = []
    for err in exc.errors():
        loc = " -> ".join(str(x) for x in err["loc"])
        errors.append(f"{loc}: {err['msg']}")
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": {
                "code": 422,
                "message": "資料格式驗證失敗",
                "details": errors
            }
        }
    )

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": {
                "code": 500,
                "message": f"伺服器內部錯誤: {str(exc)}"
            }
        }
    )

@app.get("/")
def root():
    return {"message": "北科大捷運減碳養成系統後端已成功啟動！"}