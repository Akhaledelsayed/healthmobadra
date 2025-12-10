# Quick Setup Checklist ✅

## Before Running the Mobile App

### 1. Backend Setup (Python)
- [ ] Navigate to project folder: `cd c:\Users\ot\AndroidStudioProjects\healthmobadra`
- [ ] Start all services: `python run_all.py`
- [ ] Wait for: "ALL SERVICES STARTED SUCCESSFULLY!" message
- [ ] Verify API is online: Open http://127.0.0.1:8000 in browser (should show JSON)

### 2. Test API Connection
```powershell
python test_api_connection.py
```
Expected output: ✅ All tests passed!

### 3. Frontend Setup (Flutter)

#### For Android Emulator:
- [ ] Start Android Emulator (AVD Manager)
- [ ] Connect to backend: automatically uses `http://10.0.2.2:8000`
- [ ] Run Flutter: `flutter run`

#### For Physical Device:
- [ ] Find PC's IP Address:
  ```powershell
  ipconfig
  # Look for "IPv4 Address" (e.g., 192.168.1.100)
  ```
- [ ] Edit `lib/api_service.dart`
- [ ] Change line 13:
  ```dart
  return 'http://YOUR_PC_IP:8000';  // Replace YOUR_PC_IP
  ```
- [ ] Save and run: `flutter run`

#### For Web (Chrome):
- [ ] Backend uses: `http://127.0.0.1:8000` ✅ (automatic)
- [ ] Run: `flutter run -d chrome`

---

## API Endpoints Available

| Endpoint | Purpose |
|----------|---------|
| `GET /` | Health check |
| `GET /patients` | All patients + latest vitals |
| `GET /patients/{id}` | Patient details |
| `GET /vitals/{id}` | Vitals history (for charts) |
| `GET /alerts` | All recent alerts |
| `GET /alerts/{id}` | Patient-specific alerts |
| `GET /dashboard/summary` | Dashboard statistics |

---

## Troubleshooting

### ❌ "Could not connect to Hospital API"
- [ ] Check if `run_all.py` is still running
- [ ] Test API manually: http://127.0.0.1:8000
- [ ] Check Windows Firewall (allow port 8000)
- [ ] Restart `run_all.py`

### ❌ "Connection timeout"
- [ ] Firewall blocking port 8000 → Allow it
- [ ] Network issue → Use same WiFi/network
- [ ] Wrong URL → Check IP address in `api_service.dart`

### ❌ Data not updating
- [ ] Check if vitals are being generated: `python generate_vitals.py`
- [ ] Check database: `python -c "import sqlite3; conn = sqlite3.connect('hospital.db'); print(conn.execute('SELECT * FROM vitals ORDER BY id DESC LIMIT 1').fetchone())"`

### ❌ Emulator says "device offline"
- [ ] Emulator needs network access (WiFi or bridged)
- [ ] Try running `adb devices` to verify connection
- [ ] Restart emulator

---

## File Changes Made

✅ **api.py** - Added 7 new endpoints for mobile integration
✅ **api_service.dart** - Added 8 new methods + better error handling  
✅ **BACKEND_MOBILE_INTEGRATION.md** - Complete integration guide
✅ **test_api_connection.py** - Test script to verify setup
✅ **QUICK_SETUP.md** - This file

---

## Live Monitoring While Testing

### Terminal 1: Backend Services
```powershell
python run_all.py
```

### Terminal 2: Test API
```powershell
python test_api_connection.py
```
(Run multiple times to verify data updates)

### Terminal 3: Dashboard
Already running at: http://localhost:8501

### Terminal 4: Flutter App
```bash
flutter run
```

---

## Expected Behavior

✅ **Home Screen** shows:
- Patient name & vitals (heart rate, temperature, SpO2)
- Health status (NORMAL/CRITICAL)
- Risk level (Low/High Risk)
- Data refreshes every 2 seconds

✅ **Every 5 seconds**:
- New vitals are generated in database
- API updates /patients endpoint
- App fetches fresh data automatically

✅ **Alerts appear** when:
- Critical status detected
- High-risk prediction made
- Fetched from `/alerts` endpoint

---

## Next Advanced Features

1. **Multi-patient dashboard** - Use `/patients` instead of just first patient
2. **Vital signs chart** - Use `/vitals/{id}` with charts library
3. **Real-time alerts** - Use `/alerts` with notifications
4. **Patient details page** - Use `/patients/{id}` for deep dive
5. **Authentication** - Add login via API (future enhancement)

---

## API Documentation (Auto-generated)

Once `run_all.py` is running, visit:
🔗 http://127.0.0.1:8000/docs

This shows:
- All endpoints
- Request/response examples
- Try endpoints directly in browser

---

**Status**: Backend-Mobile Integration Complete! 🚀
