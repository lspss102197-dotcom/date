from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional

# 註冊時，前端必須傳進來的資料欄位（加上安全長度限制）
class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=20, description="使用者名稱")
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=50, description="密碼")

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