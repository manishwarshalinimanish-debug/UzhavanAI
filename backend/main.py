import httpx
from pathlib import Path
import shutil
import uuid
import time

from fastapi import FastAPI, UploadFile, File, HTTPException, Response
from pydantic import BaseModel
from sqlalchemy import text

from database import engine
from ai.predict import predict_image
from ai.recommendations import get_recommendation


app = FastAPI(
    title="UzhavanAI API",
    description="AI Crop Disease Detection and Smart Farming Assistant",
    version="1.0.0",
)

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_FOLDER = BASE_DIR / "uploads"
UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)

WEATHER_CACHE = {}
WEATHER_CACHE_SECONDS = 60 * 30


class FarmerCreate(BaseModel):
    name: str
    phone: str
    village: str


@app.get("/")
def home():
    return {
        "message": "Welcome to UzhavanAI API",
        "status": "running",
    }


@app.head("/")
def home_head():
    return Response(status_code=200)


@app.get("/farmers")
def get_farmers():
    with engine.connect() as connection:
        result = connection.execute(
            text("""
                SELECT id, name, phone, village
                FROM farmers
                ORDER BY id DESC
            """)
        )

        farmers = []

        for row in result:
            farmers.append({
                "id": row.id,
                "name": row.name,
                "phone": row.phone,
                "village": row.village,
            })

    return farmers


@app.post("/farmers")
def add_farmer(farmer: FarmerCreate):
    with engine.begin() as connection:
        connection.execute(
            text("""
                INSERT INTO farmers (name, phone, village)
                VALUES (:name, :phone, :village)
            """),
            {
                "name": farmer.name,
                "phone": farmer.phone,
                "village": farmer.village,
            },
        )

    return {"message": "Farmer added successfully"}


@app.put("/farmers/{id}")
def update_farmer(id: int, farmer: FarmerCreate):
    with engine.begin() as connection:
        result = connection.execute(
            text("""
                UPDATE farmers
                SET name = :name, phone = :phone, village = :village
                WHERE id = :id
            """),
            {
                "id": id,
                "name": farmer.name,
                "phone": farmer.phone,
                "village": farmer.village,
            },
        )

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Farmer not found")

    return {"message": "Farmer updated successfully"}


@app.delete("/farmers/{id}")
def delete_farmer(id: int):
    with engine.begin() as connection:
        result = connection.execute(
            text("DELETE FROM farmers WHERE id = :id"),
            {"id": id},
        )

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Farmer not found")

    return {"message": "Farmer deleted successfully"}


@app.get("/predictions")
def get_predictions():
    with engine.connect() as connection:
        result = connection.execute(
            text("""
                SELECT
                    id, crop, disease, class_name, confidence,
                    treatment, prevention, fertilizer,
                    image_name, created_at
                FROM predictions
                ORDER BY id DESC
            """)
        )

        predictions = []

        for row in result:
            predictions.append({
                "id": row.id,
                "crop": row.crop,
                "disease": row.disease,
                "class_name": row.class_name,
                "confidence": row.confidence,
                "treatment": row.treatment,
                "prevention": row.prevention,
                "fertilizer": row.fertilizer,
                "image_name": row.image_name,
                "created_at": row.created_at.isoformat() if row.created_at else None,
            })

    return predictions


@app.post("/predict-crop")
async def predict_crop(file: UploadFile = File(...)):
    allowed_types = {"image/jpeg", "image/jpg", "image/png"}

    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG and PNG images are allowed.",
        )

    original_filename = Path(file.filename).name if file.filename else "leaf.jpg"
    extension = Path(original_filename).suffix.lower() or ".jpg"

    unique_filename = f"{uuid.uuid4().hex}{extension}"
    file_path = UPLOAD_FOLDER / unique_filename

    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as error:
        raise HTTPException(status_code=500, detail=f"Failed to save image: {error}")
    finally:
        await file.close()

    try:
        prediction = predict_image(str(file_path))
    except ValueError as error:
        file_path.unlink(missing_ok=True)
        raise HTTPException(status_code=400, detail=str(error))
    except Exception as error:
        file_path.unlink(missing_ok=True)
        raise HTTPException(status_code=500, detail=f"AI prediction failed: {error}")

    recommendation = get_recommendation(
        prediction["crop"],
        prediction["disease"],
    )

    try:
        with engine.begin() as connection:
            connection.execute(
                text("""
                    INSERT INTO predictions (
                        crop, disease, class_name, confidence,
                        treatment, prevention, fertilizer, image_name
                    )
                    VALUES (
                        :crop, :disease, :class_name, :confidence,
                        :treatment, :prevention, :fertilizer, :image_name
                    )
                """),
                {
                    "crop": prediction["crop"],
                    "disease": prediction["disease"],
                    "class_name": prediction["class_name"],
                    "confidence": prediction["confidence"],
                    "treatment": recommendation["treatment"],
                    "prevention": recommendation["prevention"],
                    "fertilizer": recommendation["fertilizer"],
                    "image_name": unique_filename,
                },
            )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Prediction succeeded, but database save failed: {error}",
        )

    return {
        "crop": prediction["crop"],
        "disease": prediction["disease"],
        "class_name": prediction["class_name"],
        "confidence": prediction["confidence"],
        "treatment": recommendation["treatment"],
        "prevention": recommendation["prevention"],
        "fertilizer": recommendation["fertilizer"],
        "image": unique_filename,
    }


def get_weather_advice(rain, weather_code):
    if rain > 0:
        return (
            "Rainy",
            "Rain detected. Avoid pesticide spraying and unnecessary irrigation.",
        )

    if weather_code in [0, 1]:
        return (
            "Clear",
            "Good weather for irrigation, harvesting and field inspection.",
        )

    if weather_code in [2, 3]:
        return (
            "Cloudy",
            "Suitable for field work. Monitor soil and crop moisture.",
        )

    return (
        "Moderate",
        "Check crop conditions and plan farm activities according to local weather.",
    )


def _weather_cache_key(latitude: float, longitude: float):
    return f"{round(latitude, 2)}:{round(longitude, 2)}"


def _get_cached_weather(key: str):
    item = WEATHER_CACHE.get(key)

    if not item:
        return None

    if time.time() - item["time"] > WEATHER_CACHE_SECONDS:
        return None

    return item["data"]


def _save_cached_weather(key: str, data: dict):
    WEATHER_CACHE[key] = {
        "time": time.time(),
        "data": data,
    }


def _fallback_weather(latitude: float, longitude: float, reason: str = ""):
    return {
        "city": "Current Location",
        "latitude": latitude,
        "longitude": longitude,
        "temperature": "--",
        "condition": "Weather temporarily unavailable",
        "rain": "--",
        "farming_advice": (
            "Weather service is busy now. Avoid repeated refresh. "
            "Try again after some time."
        ),
        "source": "fallback",
        "note": reason,
    }


def _fetch_weather_from_open_meteo(latitude: float, longitude: float):
    response = httpx.get(
        "https://api.open-meteo.com/v1/forecast",
        params={
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m,precipitation,weather_code",
        },
        timeout=10,
    )

    response.raise_for_status()
    weather_data = response.json()

    if "current" not in weather_data:
        raise ValueError("Weather service returned invalid data.")

    current = weather_data["current"]

    temperature = current.get("temperature_2m", "--")
    rain = current.get("precipitation", 0)
    weather_code = current.get("weather_code", 0)

    condition, advice = get_weather_advice(rain, weather_code)

    return {
        "city": "Current Location",
        "latitude": latitude,
        "longitude": longitude,
        "temperature": f"{temperature}°C",
        "condition": condition,
        "rain": f"{rain} mm",
        "farming_advice": advice,
        "source": "open-meteo",
    }


@app.get("/weather-by-location")
def get_weather_by_location(latitude: float, longitude: float):
    key = _weather_cache_key(latitude, longitude)

    cached = _get_cached_weather(key)
    if cached:
        return cached

    try:
        data = _fetch_weather_from_open_meteo(latitude, longitude)
        _save_cached_weather(key, data)
        return data

    except httpx.HTTPStatusError as error:
        cached = WEATHER_CACHE.get(key)
        if cached:
            return cached["data"]

        return _fallback_weather(
            latitude,
            longitude,
            reason=f"Weather API status error: {error.response.status_code}",
        )

    except Exception as error:
        cached = WEATHER_CACHE.get(key)
        if cached:
            return cached["data"]

        return _fallback_weather(
            latitude,
            longitude,
            reason=str(error),
        )


@app.get("/weather/{city}")
def get_weather(city: str):
    city_key = f"city:{city.lower().strip()}"

    cached = _get_cached_weather(city_key)
    if cached:
        return cached

    try:
        geo_response = httpx.get(
            "https://geocoding-api.open-meteo.com/v1/search",
            params={
                "name": city,
                "count": 1,
                "language": "en",
                "format": "json",
            },
            timeout=10,
        )

        geo_response.raise_for_status()
        geo_data = geo_response.json()

        if "results" not in geo_data or not geo_data["results"]:
            raise HTTPException(status_code=404, detail="City not found")

        location = geo_data["results"][0]
        latitude = location["latitude"]
        longitude = location["longitude"]

        data = _fetch_weather_from_open_meteo(latitude, longitude)
        data["city"] = city

        _save_cached_weather(city_key, data)
        return data

    except HTTPException:
        raise

    except Exception as error:
        return {
            "city": city,
            "temperature": "--",
            "condition": "Weather temporarily unavailable",
            "rain": "--",
            "farming_advice": (
                "Weather service is busy now. Try again after some time."
            ),
            "source": "fallback",
            "note": str(error),
        }


class RecoveryStart(BaseModel):
    prediction_id: int


class RecoveryNote(BaseModel):
    notes: str | None = None


def calculate_recovery_status(old_confidence, new_confidence, disease):
    disease_lower = disease.lower()

    if disease_lower == "healthy":
        return "Recovered"

    difference = old_confidence - new_confidence

    if difference >= 10:
        return "Improving"

    if difference <= -10:
        return "Worsening"

    return "Stable"


@app.post("/recovery-trackers/{prediction_id}")
def start_recovery_tracker(prediction_id: int):
    with engine.begin() as connection:
        prediction = connection.execute(
            text("""
                SELECT id, crop, disease
                FROM predictions
                WHERE id = :prediction_id
            """),
            {"prediction_id": prediction_id},
        ).fetchone()

        if prediction is None:
            raise HTTPException(status_code=404, detail="Prediction not found")

        existing = connection.execute(
            text("""
                SELECT id
                FROM recovery_trackers
                WHERE prediction_id = :prediction_id
            """),
            {"prediction_id": prediction_id},
        ).fetchone()

        if existing is not None:
            return {
                "message": "Recovery tracker already exists",
                "tracker_id": existing.id,
            }

        result = connection.execute(
            text("""
                INSERT INTO recovery_trackers (
                    prediction_id, crop, disease, status
                )
                VALUES (
                    :prediction_id, :crop, :disease, 'Monitoring'
                )
            """),
            {
                "prediction_id": prediction.id,
                "crop": prediction.crop,
                "disease": prediction.disease,
            },
        )

        tracker_id = result.lastrowid

    return {
        "message": "Recovery tracker started successfully",
        "tracker_id": tracker_id,
    }


@app.get("/recovery-trackers")
def get_recovery_trackers():
    with engine.connect() as connection:
        result = connection.execute(
            text("""
                SELECT id, prediction_id, crop, disease, started_at, status
                FROM recovery_trackers
                ORDER BY id DESC
            """)
        )

        trackers = []

        for row in result:
            trackers.append({
                "id": row.id,
                "prediction_id": row.prediction_id,
                "crop": row.crop,
                "disease": row.disease,
                "started_at": row.started_at.isoformat() if row.started_at else None,
                "status": row.status,
            })

    return trackers


@app.get("/recovery-trackers/{tracker_id}")
def get_recovery_tracker_details(tracker_id: int):
    with engine.connect() as connection:
        tracker = connection.execute(
            text("""
                SELECT id, prediction_id, crop, disease, started_at, status
                FROM recovery_trackers
                WHERE id = :tracker_id
            """),
            {"tracker_id": tracker_id},
        ).fetchone()

        if tracker is None:
            raise HTTPException(status_code=404, detail="Recovery tracker not found")

        updates_result = connection.execute(
            text("""
                SELECT id, tracker_id, image_name, confidence, notes, created_at
                FROM recovery_updates
                WHERE tracker_id = :tracker_id
                ORDER BY id DESC
            """),
            {"tracker_id": tracker_id},
        )

        updates = []

        for row in updates_result:
            updates.append({
                "id": row.id,
                "tracker_id": row.tracker_id,
                "image_name": row.image_name,
                "confidence": row.confidence,
                "notes": row.notes,
                "created_at": row.created_at.isoformat() if row.created_at else None,
            })

    return {
        "id": tracker.id,
        "prediction_id": tracker.prediction_id,
        "crop": tracker.crop,
        "disease": tracker.disease,
        "started_at": tracker.started_at.isoformat() if tracker.started_at else None,
        "status": tracker.status,
        "updates": updates,
    }


@app.post("/recovery-trackers/{tracker_id}/update")
async def add_recovery_update(
    tracker_id: int,
    file: UploadFile = File(...),
    notes: str | None = None,
):
    allowed_types = {"image/jpeg", "image/jpg", "image/png"}

    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG and PNG images are allowed.",
        )

    with engine.connect() as connection:
        tracker = connection.execute(
            text("""
                SELECT id, prediction_id, crop, disease, status
                FROM recovery_trackers
                WHERE id = :tracker_id
            """),
            {"tracker_id": tracker_id},
        ).fetchone()

        if tracker is None:
            raise HTTPException(status_code=404, detail="Recovery tracker not found")

        original_prediction = connection.execute(
            text("""
                SELECT confidence
                FROM predictions
                WHERE id = :prediction_id
            """),
            {"prediction_id": tracker.prediction_id},
        ).fetchone()

        if original_prediction is None:
            raise HTTPException(status_code=404, detail="Original prediction not found")

    original_filename = Path(file.filename).name if file.filename else "recovery_leaf.jpg"
    extension = Path(original_filename).suffix.lower() or ".jpg"

    unique_filename = f"recovery_{uuid.uuid4().hex}{extension}"
    file_path = UPLOAD_FOLDER / unique_filename

    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as error:
        raise HTTPException(status_code=500, detail=f"Failed to save recovery image: {error}")
    finally:
        await file.close()

    try:
        prediction = predict_image(str(file_path))
    except Exception as error:
        file_path.unlink(missing_ok=True)
        raise HTTPException(status_code=500, detail=f"Recovery prediction failed: {error}")

    new_confidence = prediction["confidence"]

    new_status = calculate_recovery_status(
        original_prediction.confidence,
        new_confidence,
        prediction["disease"],
    )

    with engine.begin() as connection:
        connection.execute(
            text("""
                INSERT INTO recovery_updates (
                    tracker_id, image_name, confidence, notes
                )
                VALUES (
                    :tracker_id, :image_name, :confidence, :notes
                )
            """),
            {
                "tracker_id": tracker_id,
                "image_name": unique_filename,
                "confidence": new_confidence,
                "notes": notes,
            },
        )

        connection.execute(
            text("""
                UPDATE recovery_trackers
                SET status = :status
                WHERE id = :tracker_id
            """),
            {
                "status": new_status,
                "tracker_id": tracker_id,
            },
        )

    return {
        "message": "Recovery update added successfully",
        "tracker_id": tracker_id,
        "crop": prediction["crop"],
        "disease": prediction["disease"],
        "confidence": new_confidence,
        "status": new_status,
        "image": unique_filename,
        "notes": notes,
    }


@app.delete("/recovery-trackers/{tracker_id}")
def delete_recovery_tracker(tracker_id: int):
    with engine.begin() as connection:
        result = connection.execute(
            text("DELETE FROM recovery_trackers WHERE id = :tracker_id"),
            {"tracker_id": tracker_id},
        )

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Recovery tracker not found")

    return {"message": "Recovery tracker deleted successfully"}


@app.get("/analytics")
def get_analytics():
    with engine.connect() as connection:
        total_farmers = connection.execute(
            text("SELECT COUNT(*) FROM farmers")
        ).scalar()

        total_predictions = connection.execute(
            text("SELECT COUNT(*) FROM predictions")
        ).scalar()

        healthy_predictions = connection.execute(
            text("""
                SELECT COUNT(*)
                FROM predictions
                WHERE LOWER(disease) = 'healthy'
            """)
        ).scalar()

        diseased_predictions = connection.execute(
            text("""
                SELECT COUNT(*)
                FROM predictions
                WHERE LOWER(disease) != 'healthy'
            """)
        ).scalar()

        recovery_trackers = connection.execute(
            text("SELECT COUNT(*) FROM recovery_trackers")
        ).scalar()

    return {
        "total_farmers": total_farmers,
        "total_predictions": total_predictions,
        "healthy_predictions": healthy_predictions,
        "diseased_predictions": diseased_predictions,
        "recovery_trackers": recovery_trackers,
    }


@app.get("/report-data")
def get_report_data():
    with engine.connect() as connection:
        analytics = get_analytics()

        farmers_result = connection.execute(
            text("""
                SELECT id, name, phone, village
                FROM farmers
                ORDER BY id DESC
            """)
        )

        farmers = [
            {
                "id": row.id,
                "name": row.name,
                "phone": row.phone,
                "village": row.village,
            }
            for row in farmers_result
        ]

        predictions_result = connection.execute(
            text("""
                SELECT
                    id, crop, disease, confidence,
                    treatment, prevention, fertilizer,
                    image_name, created_at
                FROM predictions
                ORDER BY id DESC
            """)
        )

        predictions = [
            {
                "id": row.id,
                "crop": row.crop,
                "disease": row.disease,
                "confidence": row.confidence,
                "treatment": row.treatment,
                "prevention": row.prevention,
                "fertilizer": row.fertilizer,
                "image_name": row.image_name,
                "created_at": row.created_at.isoformat() if row.created_at else None,
            }
            for row in predictions_result
        ]

        recovery_result = connection.execute(
            text("""
                SELECT id, prediction_id, crop, disease, started_at, status
                FROM recovery_trackers
                ORDER BY id DESC
            """)
        )

        recovery_trackers = [
            {
                "id": row.id,
                "prediction_id": row.prediction_id,
                "crop": row.crop,
                "disease": row.disease,
                "started_at": row.started_at.isoformat() if row.started_at else None,
                "status": row.status,
            }
            for row in recovery_result
        ]

    return {
        "project": "UzhavanAI",
        "description": "AI Crop Disease Detection and Smart Farming Assistant",
        "analytics": analytics,
        "farmers": farmers,
        "predictions": predictions,
        "recovery_trackers": recovery_trackers,
    }