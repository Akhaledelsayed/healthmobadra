# Backend ↔ Mobile App Integration Guide

## Overview
Your backend (Python API) and Flutter mobile app are now fully integrated. The mobile app can fetch real-time patient data, vitals, and alerts from the backend.

---

## ✅ What Has Been Implemented

### Backend (api.py) - Enhanced Endpoints
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Health check (API online status) |
| `/patients` | GET | Get all patients with latest vitals & predictions |
| `/patients/{patient_id}` | GET | Get detailed info for a specific patient |
| `/vitals/{patient_id}` | GET | Get vital signs history (for charts) |
| `/alerts` | GET | Get recent alerts (all patients) |
| `/alerts/{patient_id}` | GET | Get alerts for a specific patient |
| `/dashboard/summary` | GET | Get dashboard statistics |

### Frontend (api_service.dart) - Enhanced API Service
- ✅ `checkConnection()` - Verify backend is online
- ✅ `fetchData()` - Get first patient (real-time)
- ✅ `fetchAllPatients()` - Get all patients
- ✅ `fetchPatientDetail(patientId)` - Get patient details
- ✅ `fetchVitalsHistory(patientId, limit)` - Get vitals for charts
- ✅ `fetchAlerts(limit)` - Get all alerts
- ✅ `fetchPatientAlerts(patientId, limit)` - Get patient-specific alerts
- ✅ `fetchDashboardSummary()` - Get dashboard statistics

### Data Models (Flutter)
- ✅ `PatientData` - Patient info with vitals & risk
- ✅ `VitalSign` - Individual vital sign record
- ✅ `AlertData` - Alert information
- ✅ `DashboardSummary` - Dashboard statistics

---

## 🚀 How to Start

### Step 1: Start the Backend
```powershell
cd c:\Users\ot\AndroidStudioProjects\healthmobadra
python run_all.py
```

This will start:
- Database (hospital.db)
- Vitals Generator (P001 data every 5s)
- AI Predictor (risk analysis)
- **API Server** (http://127.0.0.1:8000)
- Dashboard (http://localhost:8501)

### Step 2: Test the API
Open your browser and visit:
- **Health Check**: http://127.0.0.1:8000/
- **All Patients**: http://127.0.0.1:8000/patients
- **Alerts**: http://127.0.0.1:8000/alerts
- **Dashboard Summary**: http://127.0.0.1:8000/dashboard/summary

You should see live JSON data.

### Step 3: Run the Flutter App

**For Android Emulator:**
```bash
flutter run
```

**For Physical Device:**
- Make sure your device is on the same network as your PC
- Edit `api_service.dart` and replace `10.0.2.2` with your PC's IP address
- Example: `'http://192.168.x.x:8000'`

---

## 🔌 Network Configuration

### Android Emulator
- Backend URL: `http://10.0.2.2:8000` (automatically detected)
- `10.0.2.2` is the special IP for "localhost" inside Android Emulator

### Physical Android Device
- Backend URL: `http://<your-pc-ip>:8000`
- Example: `http://192.168.1.100:8000`
- Find your PC's IP: Open CMD → `ipconfig` → Look for "IPv4 Address"

### Web/Chrome
- Backend URL: `http://127.0.0.1:8000` (automatically detected)

---

## 📊 Real-Time Data Flow

```
Backend (Python)           Flutter App
    ↓                        ↓
Database ────→ AI Predictor ────→ API Server
    ↓                        ↓
Vitals Generator            ApiService.fetchData()
    ↓                        ↓
Updates every 5s  ←────────  UI Updates every 2s
```

---

## 🐛 Troubleshooting

### Problem: "Connection Error" in App
**Solution:**
1. Check if `run_all.py` is running
2. Verify API is online: Open http://127.0.0.1:8000 in browser
3. Check firewall settings (allow port 8000)
4. If using physical device, ensure device is on same network

### Problem: "Could not connect to Hospital API"
**Solution:**
1. API didn't start. Check terminal for errors
2. Try manually starting API:
   ```powershell
   uvicorn api:app --host 127.0.0.1 --port 8000
   ```

### Problem: Android Emulator can't reach backend
**Solution:**
- Emulator uses `10.0.2.2` for localhost (not `127.0.0.1`)
- This is already configured in `api_service.dart`
- If still not working, check emulator network settings

### Problem: Vitals data not updating
**Solution:**
1. Check if `generate_vitals.py` is running
2. Run manually: `python generate_vitals.py`
3. Check database: `python` → `import sqlite3` → `sqlite3.connect("hospital.db")`

---

## 📝 API Response Examples

### GET /patients
```json
[
  {
    "patient_id": "P001",
    "full_name": "Ahmed Salem",
    "sex": "M",
    "heart_rate_bpm": 85,
    "temperature_c": 37.2,
    "spo2_percent": 98,
    "health_status": "NORMAL",
    "risk_level": "Low Risk",
    "confidence": 0.95
  }
]
```

### GET /dashboard/summary
```json
{
  "total_patients": 1,
  "critical_patients": 0,
  "high_risk_patients": 0,
  "timestamp": "2025-12-08T10:30:45.123456"
}
```

### GET /vitals/P001
```json
[
  {
    "id": 1,
    "patient_id": "P001",
    "heart_rate_bpm": 82,
    "temperature_c": 37.1,
    "spo2_percent": 98,
    "health_status": "NORMAL",
    "timestamp": "2025-12-08T10:20:00"
  },
  {
    "id": 2,
    "patient_id": "P001",
    "heart_rate_bpm": 85,
    "temperature_c": 37.2,
    "spo2_percent": 98,
    "health_status": "NORMAL",
    "timestamp": "2025-12-08T10:25:00"
  }
]
```

---

## 🔄 How the Mobile App Uses the API

### In Home Dashboard Screen
```dart
final ApiService _apiService = ApiService();

void _fetchData() async {
  // This calls GET /patients and gets first patient
  final data = await _apiService.fetchData();
  setState(() {
    _patientData = data;
  });
}

// Updates every 2 seconds for real-time display
_timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchData());
```

### Available Methods in Your App
```dart
// Check if backend is online
bool isOnline = await _apiService.checkConnection();

// Get all patients
List<PatientData> patients = await _apiService.fetchAllPatients();

// Get patient details
Map<String, dynamic>? details = await _apiService.fetchPatientDetail("P001");

// Get vitals history (for charts)
List<VitalSign> vitals = await _apiService.fetchVitalsHistory("P001", limit: 20);

// Get alerts
List<AlertData> alerts = await _apiService.fetchAlerts(limit: 20);

// Get dashboard stats
DashboardSummary? summary = await _apiService.fetchDashboardSummary();
```

---

## 📱 Next Steps

1. **Display Vitals Charts** - Use `fetchVitalsHistory()` with a charting library
2. **Show Alerts** - Implement alert notifications using `fetchAlerts()`
3. **Multiple Patients** - Use `fetchAllPatients()` to display patient list
4. **Add Push Notifications** - Alert users when critical status is detected
5. **Offline Support** - Cache data locally using `shared_preferences`

---

## ✨ CORS Already Enabled
Your API has CORS enabled, so the Flutter app can make requests from any origin. No additional authentication needed (yet).

---

## 📞 Need Help?
1. Check API logs in terminal running `run_all.py`
2. Check Flutter logs: `flutter logs`
3. Verify database: `python -c "import sqlite3; print(sqlite3.connect('hospital.db').execute('SELECT * FROM patients').fetchall())"`

---

**Status**: ✅ Backend-Mobile Integration Complete!
