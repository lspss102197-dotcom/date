import datetime
from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.models.user import Base

class TripModel(Base):
    __tablename__ = "trips"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    started_at = Column(DateTime, nullable=False)
    ended_at = Column(DateTime, nullable=True)
    distance_km = Column(Float, default=0.0)
    duration_seconds = Column(Integer, default=0)
    transport_type = Column(String, nullable=True)
    confidence_score = Column(Float, default=1.0)
    carbon_emission = Column(Float, default=0.0)
    carbon_saved = Column(Float, default=0.0)
    region = Column(String, default="")
    city = Column(String, default="")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    points = relationship("GPSPointModel", back_populates="trip", cascade="all, delete-orphan")

class GPSPointModel(Base):
    __tablename__ = "gps_points"

    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.id", ondelete="CASCADE"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    speed = Column(Float, nullable=True)
    recorded_at = Column(DateTime, nullable=False)

    # Relationships
    trip = relationship("TripModel", back_populates="points")
