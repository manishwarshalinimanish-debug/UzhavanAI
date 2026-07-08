from pathlib import Path
import json

import tensorflow as tf
from tensorflow.keras import layers, models


# ==========================================================
# SETTINGS
# ==========================================================

BASE_DIR = Path(__file__).resolve().parent

DATASET_DIR = BASE_DIR / "dataset"
MODEL_DIR = BASE_DIR / "model"

MODEL_DIR.mkdir(parents=True, exist_ok=True)

MODEL_PATH = MODEL_DIR / "crop_model.keras"
CLASS_NAMES_PATH = MODEL_DIR / "class_names.json"

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 10
SEED = 123


# ==========================================================
# CHECK DATASET
# ==========================================================

if not DATASET_DIR.exists():
    raise FileNotFoundError(
        f"Dataset folder not found: {DATASET_DIR}"
    )


# ==========================================================
# LOAD TRAINING DATASET
# ==========================================================

train_dataset = tf.keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    validation_split=0.20,
    subset="training",
    seed=SEED,
    image_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
)


# ==========================================================
# LOAD VALIDATION DATASET
# ==========================================================

validation_dataset = tf.keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    validation_split=0.20,
    subset="validation",
    seed=SEED,
    image_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
)


# ==========================================================
# GET CLASS NAMES
# ==========================================================

class_names = train_dataset.class_names

number_of_classes = len(class_names)

print("\n===================================")
print("CLASS NAMES")
print("===================================")

for index, class_name in enumerate(class_names):
    print(f"{index}: {class_name}")

print(f"\nTotal Classes: {number_of_classes}")


# ==========================================================
# SAVE CLASS NAMES
# ==========================================================

with open(
    CLASS_NAMES_PATH,
    "w",
    encoding="utf-8",
) as file:
    json.dump(
        class_names,
        file,
        ensure_ascii=False,
        indent=2,
    )


# ==========================================================
# PERFORMANCE OPTIMIZATION
# ==========================================================

AUTOTUNE = tf.data.AUTOTUNE

train_dataset = train_dataset.prefetch(
    buffer_size=AUTOTUNE
)

validation_dataset = validation_dataset.prefetch(
    buffer_size=AUTOTUNE
)


# ==========================================================
# DATA AUGMENTATION
# ==========================================================

data_augmentation = tf.keras.Sequential(
    [
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.10),
        layers.RandomZoom(0.10),
    ],
    name="data_augmentation",
)


# ==========================================================
# LOAD MOBILENETV2
# ==========================================================

base_model = tf.keras.applications.MobileNetV2(
    input_shape=IMAGE_SIZE + (3,),
    include_top=False,
    weights="imagenet",
)

base_model.trainable = False


# ==========================================================
# BUILD MODEL
# ==========================================================

inputs = layers.Input(
    shape=IMAGE_SIZE + (3,)
)

x = data_augmentation(inputs)

x = tf.keras.applications.mobilenet_v2.preprocess_input(x)

x = base_model(
    x,
    training=False,
)

x = layers.GlobalAveragePooling2D()(x)

x = layers.Dropout(0.20)(x)

outputs = layers.Dense(
    number_of_classes,
    activation="softmax",
)(x)

model = models.Model(
    inputs=inputs,
    outputs=outputs,
)


# ==========================================================
# COMPILE MODEL
# ==========================================================

model.compile(
    optimizer=tf.keras.optimizers.Adam(
        learning_rate=0.001
    ),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)


# ==========================================================
# SHOW MODEL
# ==========================================================

model.summary()


# ==========================================================
# CALLBACKS
# ==========================================================

callbacks = [
    tf.keras.callbacks.ModelCheckpoint(
        filepath=MODEL_PATH,
        monitor="val_accuracy",
        save_best_only=True,
        mode="max",
        verbose=1,
    ),

    tf.keras.callbacks.EarlyStopping(
        monitor="val_loss",
        patience=3,
        restore_best_weights=True,
        verbose=1,
    ),

    tf.keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.2,
        patience=2,
        min_lr=0.000001,
        verbose=1,
    ),
]


# ==========================================================
# TRAIN MODEL
# ==========================================================

print("\n===================================")
print("STARTING AI MODEL TRAINING")
print("===================================\n")

history = model.fit(
    train_dataset,
    validation_data=validation_dataset,
    epochs=EPOCHS,
    callbacks=callbacks,
)


# ==========================================================
# EVALUATE MODEL
# ==========================================================

validation_loss, validation_accuracy = model.evaluate(
    validation_dataset
)

print("\n===================================")
print("TRAINING COMPLETED")
print("===================================")

print(
    f"Validation Loss: "
    f"{validation_loss:.4f}"
)

print(
    f"Validation Accuracy: "
    f"{validation_accuracy * 100:.2f}%"
)


# ==========================================================
# SAVE FINAL MODEL
# ==========================================================

model.save(MODEL_PATH)

print("\nModel saved successfully:")
print(MODEL_PATH)

print("\nClass names saved successfully:")
print(CLASS_NAMES_PATH)