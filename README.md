git add README.md
git commit -m "Add project README"
git push

# 🌾 UzhavanAI – AI Crop Disease Detection & Smart Farming Assistant

UzhavanAI is a full-stack AI-powered smart farming mobile application designed to help farmers identify crop diseases, receive treatment recommendations, view weather information, track crop recovery, and manage farming-related data.

The application combines a Flutter mobile frontend, a FastAPI backend, an AI crop disease classification model, and a cloud-hosted MySQL database.

The main goal of UzhavanAI is to make AI-based agricultural assistance accessible to farmers through a simple bilingual mobile application supporting Tamil and English.

---

## 📱 Project Overview

Farmers often face difficulties identifying crop diseases at an early stage. Delayed disease detection can lead to crop damage, reduced yield, and financial loss.

UzhavanAI provides a mobile-based solution where farmers can:

- Register and manage farmer information.
- Upload crop leaf images.
- Detect crop diseases using an AI model.
- Receive treatment and farming recommendations.
- View prediction history.
- Monitor crop recovery progress.
- View live weather information.
- Access application features in Tamil and English.
- Use the application through a deployed cloud backend.

---

## ✨ Main Features

### 👨‍🌾 Farmer Management

- Add farmer details.
- View registered farmers.
- Edit farmer information.
- Delete farmer records.
- Store farmer information in a MySQL database.

### 🤖 AI Crop Disease Detection

- Select crop leaf images from the mobile device.
- Upload images to the FastAPI backend.
- Process images using the trained AI model.
- Predict crop disease.
- Display prediction confidence.
- Provide disease information.
- Provide treatment recommendations.
- Provide farming advice.

### 📊 Analytics Dashboard

The application dashboard displays:

- Total farmers.
- Total AI predictions.
- Healthy crop predictions.
- Diseased crop predictions.
- Recovery tracker count.

### 🌦️ Weather Integration

- Retrieve weather information using location coordinates.
- Display temperature.
- Display weather condition.
- Display rainfall information.
- Provide weather-based farming advice.
- Graceful fallback response when the external weather service is temporarily unavailable.

### 📜 Prediction History

- Store AI prediction results.
- View previous disease predictions.
- Review prediction details.

### 🌱 Crop Recovery Tracker

- Monitor crop recovery after treatment.
- Maintain crop recovery information.
- Track progress over time.

### 📄 Reports

- View farming and prediction reports.
- Access collected application data for analysis.

### 🌐 Tamil & English Support

The application supports:

- English interface.
- Tamil interface.
- Runtime language switching.

This makes the application easier to use for Tamil-speaking farmers.

---

## 🏗️ System Architecture

```text
                     ┌─────────────────────┐
                     │    Flutter Mobile   │
                     │     Application     │
                     └──────────┬──────────┘
                                │
                                │ HTTPS / REST API
                                ▼
                     ┌─────────────────────┐
                     │   FastAPI Backend   │
                     │       Python        │
                     └──────┬────────┬─────┘
                            │        │
                  SQLAlchemy│        │AI Prediction
                            │        │
                            ▼        ▼
                  ┌────────────┐  ┌───────────────┐
                  │   MySQL    │  │ Trained Crop  │
                  │  Database  │  │ Disease Model │
                  └────────────┘  └───────────────┘
                            │
                            │
                            ▼
                  ┌──────────────────────┐
                  │ External Weather API │
                  └──────────────────────┘
```

---

## 🛠️ Technology Stack

### Mobile Application

- Flutter
- Dart
- Provider
- HTTP package
- Image Picker
- Android

### Backend

- Python
- FastAPI
- Uvicorn
- SQLAlchemy
- PyMySQL
- Pydantic

### Artificial Intelligence

- TensorFlow / Keras
- Image Classification
- Crop Disease Prediction Model

### Database

- MySQL
- Cloud-hosted MySQL database

### Deployment

- Render – FastAPI backend deployment
- Railway – MySQL database hosting
- GitHub – Source code and version control

---

## 📂 Project Structure

```text
UzhavanAI/
│
├── backend/
│   │
│   ├── ai/
│   │   ├── model/
│   │   │   ├── class_names.json
│   │   │   └── crop_model.keras
│   │   │
│   │   ├── predict.py
│   │   ├── recommendations.py
│   │   └── train_model.py
│   │
│   ├── database.py
│   ├── main.py
│   ├── requirements.txt
│   ├── Procfile
│   ├── .python-version
│   └── .gitignore
│
├── frontend/
│   │
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── main.dart
│   │
│   ├── pubspec.yaml
│   └── README.md
│
├── .gitignore
└── README.md
```

---

## 🔄 Application Workflow

```text
User Opens Mobile Application
            ↓
Flutter Dashboard Loads
            ↓
Connects to Deployed FastAPI Backend
            ↓
FastAPI Connects to MySQL Database
            ↓
Farmer Data and Analytics Are Loaded
            ↓
User Uploads Crop Leaf Image
            ↓
Image Sent to AI Prediction API
            ↓
AI Model Processes Image
            ↓
Disease Prediction Generated
            ↓
Treatment Recommendation Returned
            ↓
Prediction Stored in Database
            ↓
Result Displayed in Tamil or English
            ↓
User Can Track Crop Recovery
```

---

## 🔌 REST API Endpoints

### Farmer APIs

```text
GET     /farmers
POST    /farmers
PUT     /farmers/{farmer_id}
DELETE  /farmers/{farmer_id}
```

### AI Prediction APIs

```text
POST    /predict
```

### Prediction History APIs

```text
GET     /predictions
```

### Recovery Tracker APIs

```text
GET     /recovery
POST    /recovery
```

### Analytics API

```text
GET     /analytics
```

### Weather API

```text
GET     /weather-by-location
```

Interactive FastAPI documentation is available at:

```text
<DEPLOYED_BACKEND_URL>/docs
```

---

## ⚙️ Backend Setup

### 1. Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd UzhavanAI/backend
```

### 2. Create Python Virtual Environment

Windows:

```powershell
py -m venv venv
.\venv\Scripts\Activate.ps1
```

Linux/macOS:

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables

Create a `.env` file inside the `backend` directory.

```env
DB_HOST=your_mysql_host
DB_PORT=your_mysql_port
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password
DB_NAME=your_database_name
```

Do not upload `.env` files, passwords, API keys, or database credentials to GitHub.

### 5. Start the Backend

```bash
uvicorn main:app --reload
```

Backend development server:

```text
http://127.0.0.1:8000
```

FastAPI documentation:

```text
http://127.0.0.1:8000/docs
```

---

## 📱 Flutter Application Setup

### 1. Open the Frontend Directory

```bash
cd frontend
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Backend URL

Update the deployed backend URL inside:

```text
lib/services/api_service.dart
```

Example:

```dart
static const String baseUrl =
    "https://your-backend-service.example";
```

### 4. Run the Application

```bash
flutter run
```

### 5. Build Release APK

```bash
flutter build apk --release
```

Generated APK:

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## ☁️ Deployment Architecture

```text
Android Mobile Application
           │
           │ HTTPS Requests
           ▼
    Deployed FastAPI Backend
           │
           │ SQL Connection
           ▼
      Cloud MySQL Database

FastAPI Backend
      │
      ├──── AI Crop Disease Model
      │
      └──── External Weather Service
```

The deployed backend allows the Android application to work from different internet connections without requiring the development laptop and mobile device to be connected to the same Wi-Fi network.

---

## 🔐 Security Practices

- Database credentials are stored using environment variables.
- `.env` files are excluded from Git version control.
- Backend communication uses HTTPS in production.
- Database passwords and deployment credentials should never be committed to GitHub.
- API inputs should be validated by the backend.
- Uploaded images should be validated before AI processing.

---

## 🚀 Future Enhancements

Future versions of UzhavanAI can include:

- More crop varieties and disease classes.
- Improved AI model accuracy.
- Offline crop disease prediction.
- Voice-based Tamil farming assistant.
- Government agricultural scheme information.
- Fertilizer recommendation based on soil conditions.
- Market price prediction.
- Nearby agricultural service center information.
- Push notifications for weather warnings.
- Satellite-based crop monitoring.
- Farmer authentication and secure user accounts.
- Advanced crop recovery analytics.

---

## 🎯 Project Objective

The objective of UzhavanAI is to develop an accessible smart farming platform that combines artificial intelligence, mobile application development, cloud deployment, weather information, and database technologies to assist farmers in identifying crop diseases and making better crop-management decisions.

---

## 🎓 Academic Purpose

UzhavanAI was developed as a final-year academic project demonstrating practical implementation of:

- Mobile Application Development.
- REST API Development.
- Artificial Intelligence and Deep Learning.
- Image Classification.
- Database Management.
- Cloud Deployment.
- Full-Stack Application Development.
- Multilingual User Interfaces.

---

## 👨‍💻 Developer

**Manishwar M.**

Final Year Computer Science Student

Project: **UzhavanAI – AI Crop Disease Detection & Smart Farming Assistant**

---

## 📄 License

This project was developed primarily for educational and academic purposes.

If the project is reused, modified, or extended, appropriate attribution to the original developer is appreciated.

---

## ⭐ Support

If you find this project useful, consider giving the repository a star.

Contributions, suggestions, and improvements are welcome.
