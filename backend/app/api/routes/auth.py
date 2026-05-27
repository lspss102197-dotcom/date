from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import os, jwt, datetime

from app.core.database import get_db
from app.schemas.user import UserCreate, UserLogin
from app.models.user import UserModel

router = APIRouter(prefix="/api/auth", tags=["帳號認證"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.username == user_data.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="該帳號已被註冊")
    
    hashed_pwd = pwd_context.hash(user_data.password)
    new_user = UserModel(
        username=user_data.username, 
        email=user_data.email, 
        hashed_password=hashed_pwd
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "註冊成功！使用者已寫入 PostgreSQL 資料庫。"}

@router.post("/login")
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(UserModel).filter(UserModel.username == user_data.username).first()
    if not db_user or not pwd_context.verify(user_data.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="帳號或密碼錯誤")
    
    exp = datetime.datetime.utcnow() + datetime.timedelta(minutes=60)
    token_data = {"sub": db_user.username, "exp": exp}
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"access_token": token, "token_type": "bearer", "message": "登入成功！已發放第一週 JWT Token。"}