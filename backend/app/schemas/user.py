from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

# 註冊時，前端必須傳進來的資料欄位
class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

# 登入時，前端必須傳進來的資料欄位
class UserLogin(BaseModel):
    username: str
    password: str

# 回傳給前端的用戶資料格式（隱藏密碼，安全第一）
class UserOut(BaseModel):
    id: int
    username: str
    email: str
    visual_state: str
    created_at: datetime

    class Config:
        from_attributes = True  # 支援 SQLAlchemy ORM 轉換

# Token 的回傳格式
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None