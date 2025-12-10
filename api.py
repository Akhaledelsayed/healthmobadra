# api.py - ENHANCED VERSION WITH MOBILE APP INTEGRATION
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
import sqlite3
import uvicorn
from datetime import datetime, timedelta
import hashlib
import secrets
from typing import Optional

app = FastAPI(title="Al-Salam Hospital API")

# Enable CORS for Flutter Mobile & Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Flutter app can access from any network
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    conn = sqlite3.connect("hospital.db")
    conn.row_factory = sqlite3.Row
    return conn


def _ensure_auth_tables():
    conn = get_db()
    c = conn.cursor()
    # Users table
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            full_name TEXT,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            created_at TEXT
        )
    ''')
    # Sessions table
    c.execute('''
        CREATE TABLE IF NOT EXISTS sessions (
            token TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL,
            expires_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')
    # User-Patient mapping table
    c.execute('''
        CREATE TABLE IF NOT EXISTS user_patients (
            user_id INTEGER PRIMARY KEY,
            patient_id TEXT UNIQUE NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')
    conn.commit()
    conn.close()


def _hash_password(password: str, salt: Optional[str] = None):
    if salt is None:
        salt = secrets.token_hex(16)
    # PBKDF2-HMAC-SHA256
    pwd_hash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000)
    return salt, pwd_hash.hex()


def _verify_password(password: str, salt: str, pwd_hash_hex: str) -> bool:
    _, calc = _hash_password(password, salt)
    return secrets.compare_digest(calc, pwd_hash_hex)


def _create_session(user_id: int, days_valid: int = 7) -> str:
    token = secrets.token_urlsafe(32)
    expires = (datetime.utcnow() + timedelta(days=days_valid)).isoformat()
    conn = get_db()
    c = conn.cursor()
    c.execute('INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)', (token, user_id, expires))
    conn.commit()
    conn.close()
    return token


def _get_user_by_token(token: str):
    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT user_id, expires_at FROM sessions WHERE token = ?', (token,))
    row = c.fetchone()
    if not row:
        conn.close()
        return None
    # check expiry
    try:
        expires = datetime.fromisoformat(row['expires_at'])
    except Exception:
        conn.close()
        return None
    if expires < datetime.utcnow():
        # session expired - delete
        c.execute('DELETE FROM sessions WHERE token = ?', (token,))
        conn.commit()
        conn.close()
        return None
    user_id = row['user_id']
    c.execute('SELECT id, username, full_name, created_at FROM users WHERE id = ?', (user_id,))
    user = c.fetchone()
    conn.close()
    return dict(user) if user else None


def _get_patient_id_for_user(user_id: int) -> str:
    """Get or create a patient ID for a user."""
    conn = get_db()
    c = conn.cursor()
    
    # Check if user already has a patient
    c.execute('SELECT patient_id FROM user_patients WHERE user_id = ?', (user_id,))
    row = c.fetchone()
    
    if row:
        conn.close()
        return row['patient_id']
    
    # Generate new patient ID
    patient_id = f"USER_{user_id:04d}"
    
    # Ensure patient exists in patients table
    c.execute('SELECT patient_id FROM patients WHERE patient_id = ?', (patient_id,))
    if not c.fetchone():
        # Create new patient record
        c.execute('''
            INSERT INTO patients (patient_id, full_name, sex, age)
            VALUES (?, ?, ?, ?)
        ''', (patient_id, f"User {user_id}", "M", 35))
    
    # Link user to patient
    c.execute('INSERT INTO user_patients (user_id, patient_id) VALUES (?, ?)', (user_id, patient_id))
    conn.commit()
    conn.close()
    
    return patient_id

@app.get("/")
def root():
    """Health check endpoint for mobile app"""
    return {
        "status": "online",
        "service": "Al-Salam Hospital API",
        "timestamp": datetime.now().isoformat()
    }


@app.post('/auth/register')
async def register(request: Request):
    """Register a new user. Returns access token on success."""
    _ensure_auth_tables()
    data = await request.json()
    username = (data.get('username') or '').strip()
    password = data.get('password')
    full_name = data.get('full_name') or ''

    if not username or not password:
        raise HTTPException(status_code=400, detail='username and password required')

    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT id FROM users WHERE username = ?', (username,))
    if c.fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail='username already exists')

    salt, pwd_hash = _hash_password(password)
    created_at = datetime.utcnow().isoformat()
    c.execute('INSERT INTO users (username, full_name, password_hash, salt, created_at) VALUES (?, ?, ?, ?, ?)',
              (username, full_name, pwd_hash, salt, created_at))
    conn.commit()
    user_id = c.lastrowid
    conn.close()

    token = _create_session(user_id)
    return {"user_id": user_id, "access_token": token, "token_type": "bearer"}


@app.post('/auth/login')
async def login(request: Request):
    """Login with username/password. Returns access token."""
    _ensure_auth_tables()
    data = await request.json()
    username = (data.get('username') or '').strip()
    password = data.get('password')

    if not username or not password:
        raise HTTPException(status_code=400, detail='username and password required')

    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT id, password_hash, salt FROM users WHERE username = ?', (username,))
    row = c.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=401, detail='invalid credentials')
    user_id = row['id']
    pwd_hash = row['password_hash']
    salt = row['salt']
    if not _verify_password(password, salt, pwd_hash):
        conn.close()
        raise HTTPException(status_code=401, detail='invalid credentials')
    conn.close()
    token = _create_session(user_id)
    return {"access_token": token, "token_type": "bearer"}


@app.get('/users/me')
def users_me(request: Request):
    """Return profile for authenticated user (use Authorization: Bearer <token>)"""
    auth = request.headers.get('authorization') or ''
    if not auth.lower().startswith('bearer '):
        raise HTTPException(status_code=401, detail='Authorization header missing')
    token = auth.split(' ', 1)[1].strip()
    user = _get_user_by_token(token)
    if not user:
        raise HTTPException(status_code=401, detail='invalid or expired token')
    
    # Get patient ID for this user
    user_id = user['id']
    patient_id = _get_patient_id_for_user(user_id)
    user['patient_id'] = patient_id
    
    return {"user": user}

@app.get("/patients")
def get_patients():
    conn = get_db()
    c = conn.cursor()
    
    # THIS QUERY IS THE FIX — always returns latest vital + prediction for each patient
    c.execute("""
        SELECT 
            p.patient_id,
            p.full_name,
            p.sex,
            v.heart_rate_bpm,
            v.temperature_c,
            v.spo2_percent,
            COALESCE(v.health_status, 'NORMAL') as health_status,
            COALESCE(pr.predicted_label, 'Low Risk') as risk_level,
            COALESCE(pr.confidence, 0.0) as confidence
        FROM patients p
        LEFT JOIN (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY id DESC) as rn
            FROM vitals
        ) v ON p.patient_id = v.patient_id AND v.rn = 1
        LEFT JOIN (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY id DESC) as rn
            FROM predictions
        ) pr ON p.patient_id = pr.patient_id AND pr.rn = 1
    """)
    
    rows = c.fetchall()
    conn.close()
    
    result = []
    for row in rows:
        result.append({
            "patient_id": row["patient_id"],
            "full_name": row["full_name"],
            "sex": row["sex"],
            "heart_rate_bpm": row["heart_rate_bpm"] or 0,
            "temperature_c": round(row["temperature_c"], 1) if row["temperature_c"] else 0.0,
            "spo2_percent": row["spo2_percent"] or 0,
            "health_status": row["health_status"],
            "risk_level": row["risk_level"],
            "confidence": float(row["confidence"])
        })
    return result

@app.get("/patients/{patient_id}")
def get_patient_detail(patient_id: str):
    """Get detailed info for a specific patient with vitals history"""
    conn = get_db()
    c = conn.cursor()
    
    # Get patient info
    c.execute("SELECT * FROM patients WHERE patient_id = ?", (patient_id,))
    patient = c.fetchone()
    
    if not patient:
        conn.close()
        return {"error": "Patient not found"}
    
    # Get latest vitals
    c.execute("""
        SELECT * FROM vitals 
        WHERE patient_id = ? 
        ORDER BY id DESC 
        LIMIT 1
    """, (patient_id,))
    vital = c.fetchone()
    
    # Get latest prediction
    c.execute("""
        SELECT * FROM predictions 
        WHERE patient_id = ? 
        ORDER BY id DESC 
        LIMIT 1
    """, (patient_id,))
    prediction = c.fetchone()
    
    conn.close()
    
    return {
        "patient": dict(patient) if patient else None,
        "latest_vital": dict(vital) if vital else None,
        "latest_prediction": dict(prediction) if prediction else None
    }

@app.get("/vitals/{patient_id}")
def get_vitals_history(patient_id: str, limit: int = 20):
    """Get vital signs history for a patient (for charts)"""
    conn = get_db()
    c = conn.cursor()
    c.execute("""
        SELECT id, patient_id, heart_rate_bpm, temperature_c, spo2_percent, 
               health_status, timestamp
        FROM vitals 
        WHERE patient_id = ? 
        ORDER BY timestamp DESC 
        LIMIT ?
    """, (patient_id, limit))
    
    rows = c.fetchall()
    conn.close()
    
    # Return in chronological order
    result = [dict(row) for row in reversed(rows)]
    return result

@app.get("/alerts")
def get_alerts(limit: int = 20):
    """Get recent alerts for all patients or specific patient"""
    conn = get_db()
    c = conn.cursor()
    c.execute("""
        SELECT a.*, p.full_name
        FROM alerts a
        JOIN patients p ON a.patient_id = p.patient_id
        ORDER BY a.id DESC LIMIT ?
    """, (limit,))
    rows = c.fetchall()
    conn.close()
    return [dict(row) for row in rows]

@app.get("/alerts/{patient_id}")
def get_patient_alerts(patient_id: str, limit: int = 10):
    """Get alerts for a specific patient"""
    conn = get_db()
    c = conn.cursor()
    c.execute("""
        SELECT a.*, p.full_name
        FROM alerts a
        JOIN patients p ON a.patient_id = p.patient_id
        WHERE a.patient_id = ?
        ORDER BY a.id DESC LIMIT ?
    """, (patient_id, limit))
    rows = c.fetchall()
    conn.close()
    return [dict(row) for row in rows]

@app.get("/dashboard/summary")
def get_dashboard_summary():
    """Get summary stats for the dashboard"""
    conn = get_db()
    c = conn.cursor()
    
    # Count critical vs normal
    c.execute("""
        SELECT 
            COUNT(*) as total_patients,
            SUM(CASE WHEN health_status = 'CRITICAL' THEN 1 ELSE 0 END) as critical_count,
            SUM(CASE WHEN risk_level = 'High Risk' THEN 1 ELSE 0 END) as high_risk_count
        FROM (
            SELECT DISTINCT p.patient_id, 
                   COALESCE(v.health_status, 'NORMAL') as health_status,
                   COALESCE(pr.predicted_label, 'Low Risk') as risk_level
            FROM patients p
            LEFT JOIN (
                SELECT *, ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY id DESC) as rn
                FROM vitals
            ) v ON p.patient_id = v.patient_id AND v.rn = 1
            LEFT JOIN (
                SELECT *, ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY id DESC) as rn
                FROM predictions
            ) pr ON p.patient_id = pr.patient_id AND pr.rn = 1
        )
    """)
    
    summary = c.fetchone()
    conn.close()
    
    return {
        "total_patients": summary["total_patients"] or 0,
        "critical_patients": summary["critical_count"] or 0,
        "high_risk_patients": summary["high_risk_count"] or 0,
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    print("API Server → http://127.0.0.1:8000")
    uvicorn.run(app, host="127.0.0.1", port=8000)