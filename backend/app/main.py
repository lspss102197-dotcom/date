from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import engine
from app.models.user import Base
from app.api.routes import auth

# 開機時自動檢查並建立資料表
Base.metadata.create_all(bind=engine)

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

@app.get("/")
def root():
    return {"message": "北科大捷運減碳養成系統後端已成功啟動！"}