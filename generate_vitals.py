import sqlite3
import time
import random
from datetime import datetime, timezone
import json

DB_PATH = "hospital.db"
PATIENT_ID = "P001"
DEVICE_ID = "DEV_P001"

# Global state for realistic streaming (vitals remember previous values)
class VitalState:
    def __init__(self):
        # Start in a normal range per user request:
        # heart rate: 70-80 bpm, temperature: 36.0-42.0 °C, SpO2: 92-100%
        self.heart_rate = random.randint(70, 80)
        self.temperature = round(random.uniform(36.0, 42.0), 1)
        self.spo2 = random.randint(92, 100)
        self.systolic_bp = 120
        self.diastolic_bp = 80
        self.rr = 16
        self.episode_counter = 0  # Count frames in "episode" state

state = VitalState()

def get_connection():
    # keep simple single-thread connection
    return sqlite3.connect(DB_PATH)

def generate_vitals_sample():
    """
    Generate realistic vitals that vary smoothly from previous readings.
    - 85% normal state: small variations around baseline
    - 15% episode state: gradual increase in HR/temp, decrease in SpO2
    """
    global state

    # 10% chance to enter or continue an episode (worsening state)
    if random.random() < 0.10 or state.episode_counter > 0:
        state.episode_counter += 1
        
        # Episode lasts 3-8 iterations (15-40 seconds)
        if state.episode_counter > random.randint(3, 8):
            state.episode_counter = 0  # Exit episode, return to normal
        else:
            # During episode: moderate worsening (kept reasonable)
            state.heart_rate += random.randint(2, 6)
            state.temperature += random.uniform(0.1, 0.4)
            state.spo2 -= random.randint(1, 3)
            state.systolic_bp += random.randint(1, 4)
            state.diastolic_bp += random.randint(1, 3)
            state.rr += random.randint(0, 2)
    else:
        # Normal state: very small, smooth variations per-sample
        state.heart_rate += random.randint(-1, 1)  # ±1 bpm
        state.temperature += random.uniform(-0.05, 0.05)  # ±0.05°C
        # Spo2 mostly stable; small chance of ±1
        state.spo2 += random.choice([-1, 0, 0, 0, 1])
        state.systolic_bp += random.randint(-1, 1)
        state.diastolic_bp += random.randint(-1, 1)
        state.rr += random.randint(-1, 1)

    # Clamp values to realistic ranges
    state.heart_rate = max(50, min(180, state.heart_rate))
    # Keep reasonable clamps (allow episodes to drive outside 'normal')
    state.temperature = max(36.0, min(42.0, state.temperature))
    state.spo2 = max(80, min(100, state.spo2))
    state.systolic_bp = max(90, min(180, state.systolic_bp))
    state.diastolic_bp = max(50, min(110, state.diastolic_bp))
    state.rr = max(10, min(40, state.rr))

    return {
        "heart_rate_bpm": round(state.heart_rate),
        "temperature_c": round(state.temperature, 1),
        "spo2_percent": round(state.spo2),
        "systolic_bp": round(state.systolic_bp),
        "diastolic_bp": round(state.diastolic_bp),
        "rr": round(state.rr),
    }

def classify_status(v):
    """
    Simple rule-based label used by your system (NORMAL / WARNING / CRITICAL).
    """
    hr = v["heart_rate_bpm"]
    temp = v["temperature_c"]
    spo2 = v["spo2_percent"]

    if hr > 130 or temp >= 39.0 or spo2 < 90:
        return "CRITICAL"
    elif hr > 110 or temp >= 38.0 or spo2 < 94:
        return "WARNING"
    else:
        return "NORMAL"

def insert_one_reading(conn):
    c = conn.cursor()
    vitals = generate_vitals_sample()
    status = classify_status(vitals)
    ts = datetime.now(timezone.utc).isoformat()

    raw_payload = json.dumps(vitals)

    c.execute("""
        INSERT INTO vitals (
            timestamp_utc,
            patient_id,
            device_id,
            heart_rate_bpm,
            temperature_c,
            spo2_percent,
            systolic_bp,
            diastolic_bp,
            rr,
            raw_payload,
            health_status
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?)
    """, (
        ts,
        PATIENT_ID,
        DEVICE_ID,
        vitals["heart_rate_bpm"],
        vitals["temperature_c"],
        vitals["spo2_percent"],
        vitals["systolic_bp"],
        vitals["diastolic_bp"],
        vitals["rr"],
        raw_payload,
        status
    ))

    conn.commit()
    print(f"[{ts}] P001 → {vitals} | Status: {status}")

def main():
    print("[OK] Realistic vitals generator started (P001, every 5 seconds)...")
    print("    - Vitals vary smoothly from previous readings")
    print("    - 10% chance of stress episode (HR^, Temp^, SpO2v)")
    conn = get_connection()

    try:
        while True:
            insert_one_reading(conn)
            time.sleep(5)
    except KeyboardInterrupt:
        print("\nStopped by user.")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
