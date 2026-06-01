from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.api.routes import auth
from app.models.user import Base


def test_register_login_and_me(tmp_path):
    database_url = f"sqlite:///{tmp_path / 'auth.db'}"
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
    app.dependency_overrides[auth.get_db] = override_get_db
    client = TestClient(app)

    register_response = client.post(
        "/api/auth/register",
        json={
            "username": "demo-user",
            "email": "demo@example.com",
            "password": "secret123",
        },
    )

    assert register_response.status_code == 201

    login_response = client.post(
        "/api/auth/login",
        json={"username": "demo-user", "password": "secret123"},
    )

    assert login_response.status_code == 200
    token = login_response.json()["access_token"]

    me_response = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert me_response.status_code == 200
    assert me_response.json()["username"] == "demo-user"
    assert me_response.json()["email"] == "demo@example.com"
