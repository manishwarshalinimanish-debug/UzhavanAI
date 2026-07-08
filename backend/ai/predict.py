from pathlib import Path
import json

import numpy as np
import tensorflow as tf
from PIL import Image, UnidentifiedImageError


# ==========================================================
# PATHS
# ==========================================================

BASE_DIR = Path(__file__).resolve().parent

MODEL_PATH = BASE_DIR / "model" / "crop_model.keras"
CLASS_NAMES_PATH = BASE_DIR / "model" / "class_names.json"


# ==========================================================
# CHECK REQUIRED FILES
# ==========================================================

if not MODEL_PATH.exists():
    raise FileNotFoundError(
        f"Model not found: {MODEL_PATH}"
    )

if not CLASS_NAMES_PATH.exists():
    raise FileNotFoundError(
        f"Class names file not found: {CLASS_NAMES_PATH}"
    )


# ==========================================================
# LOAD MODEL
# ==========================================================

print("Loading Crop AI model...")

model = tf.keras.models.load_model(MODEL_PATH)

print("Crop AI model loaded successfully.")


# ==========================================================
# LOAD CLASS NAMES
# ==========================================================

with open(
    CLASS_NAMES_PATH,
    "r",
    encoding="utf-8",
) as file:
    class_names = json.load(file)


if not isinstance(class_names, list) or not class_names:
    raise ValueError(
        "class_names.json must contain a non-empty list."
    )


if model.output_shape[-1] != len(class_names):
    raise ValueError(
        "Model output count does not match class_names.json."
    )


# ==========================================================
# FORMAT CLASS NAME
# ==========================================================

def format_prediction(class_name: str):

    parts = class_name.split("___", 1)

    crop = parts[0].replace("_", " ").strip()

    disease = (
        parts[1].replace("_", " ").strip()
        if len(parts) > 1
        else "Unknown"
    )

    return crop, disease


# ==========================================================
# PREDICT IMAGE
# ==========================================================

def predict_image(image_path: str):

    image_path = Path(image_path)

    if not image_path.exists():
        raise FileNotFoundError(
            f"Image not found: {image_path}"
        )

    try:
        with Image.open(image_path) as image:
            image = image.convert("RGB")
            image = image.resize((224, 224))

            image_array = np.asarray(
                image,
                dtype=np.float32,
            )

    except UnidentifiedImageError as error:
        raise ValueError(
            "Uploaded file is not a valid image."
        ) from error


    # MobileNetV2 preprocessing is already stored
    # inside crop_model.keras.

    image_array = np.expand_dims(
        image_array,
        axis=0,
    )


    # ======================================================
    # RUN MODEL
    # ======================================================

    predictions = model.predict(
        image_array,
        verbose=0,
    )


    predicted_index = int(
        np.argmax(predictions[0])
    )


    confidence = float(
        predictions[0][predicted_index]
    )


    predicted_class = class_names[
        predicted_index
    ]


    crop, disease = format_prediction(
        predicted_class
    )


    # ======================================================
    # RETURN RESULT
    # ======================================================

    return {
        "crop": crop,
        "disease": disease,
        "class_name": predicted_class,
        "confidence": round(
            confidence * 100,
            2,
        ),
    }