import datetime
import os

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from app.core.database import get_db
from app.models.user import UserModel
from app.schemas.user import UserCreate, UserLogin, UserOut

router = APIRouter(prefix="/api/auth", tags=["帳號認證"])
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
bearer_scheme = HTTPBearer()

SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))


def _create_access_token(username: str) -> str:
    exp = datetime.datetime.utcnow() + datetime.timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )
    token_data = {"sub": username, "exp": exp}
    return jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> UserModel:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="無效或已過期的登入憑證",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            credentials.credentials,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )
        username = payload.get("sub")
    except jwt.PyJWTError as exc:
        raise credentials_exception from exc

    if not username:
        raise credentials_exception

    user = db.query(UserModel).filter(UserModel.username == username).first()
    if user is None:
        raise credentials_exception

    return user

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
    
    token = _create_access_token(db_user.username)
    
    return {"access_token": token, "token_type": "bearer", "message": "登入成功！已發放第一週 JWT Token。"}


@router.get("/me", response_model=UserOut)
def me(current_user: UserModel = Depends(get_current_user)):
    return current_user
