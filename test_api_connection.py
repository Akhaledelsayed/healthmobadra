#!/usr/bin/env python3
"""
test_api_connection.py - Test Backend-Mobile App Integration
Run this script to verify your API is working correctly
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://127.0.0.1:8000"

def print_header(text):
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}")

def test_health_check():
    """Test 1: Health Check"""
    print_header("TEST 1: Health Check (/)")
    try:
        response = requests.get(f"{BASE_URL}/", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API is ONLINE")
            print(f"   Status: {data['status']}")
            print(f"   Service: {data['service']}")
            print(f"   Timestamp: {data['timestamp']}")
            return True
        else:
            print(f"❌ Unexpected status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print(f"   Make sure run_all.py is running!")
        return False

def test_get_patients():
    """Test 2: Get All Patients"""
    print_header("TEST 2: Get All Patients (/patients)")
    try:
        response = requests.get(f"{BASE_URL}/patients", timeout=5)
        if response.status_code == 200:
            patients = response.json()
            print(f"✅ Retrieved {len(patients)} patient(s)")
            for p in patients:
                print(f"\n   Patient: {p['full_name']} ({p['patient_id']})")
                print(f"   ├─ Heart Rate: {p['heart_rate_bpm']} bpm")
                print(f"   ├─ Temperature: {p['temperature_c']}°C")
                print(f"   ├─ SpO2: {p['spo2_percent']}%")
                print(f"   ├─ Status: {p['health_status']}")
                print(f"   ├─ Risk Level: {p['risk_level']}")
                print(f"   └─ Confidence: {p['confidence']:.2%}")
            return True
        else:
            print(f"❌ Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False

def test_get_alerts():
    """Test 3: Get Alerts"""
    print_header("TEST 3: Get Alerts (/alerts)")
    try:
        response = requests.get(f"{BASE_URL}/alerts?limit=5", timeout=5)
        if response.status_code == 200:
            alerts = response.json()
            if alerts:
                print(f"✅ Retrieved {len(alerts)} alert(s)")
                for a in alerts[:3]:  # Show first 3
                    print(f"\n   Alert ID {a['id']}: {a['alert_type']}")
                    print(f"   ├─ Patient: {a['full_name']} ({a['patient_id']})")
                    if a.get('message'):
                        print(f"   ├─ Message: {a['message']}")
                    print(f"   └─ Time: {a.get('timestamp', 'N/A')}")
            else:
                print("✅ No alerts (good sign!)")
            return True
        else:
            print(f"❌ Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False

def test_dashboard_summary():
    """Test 4: Dashboard Summary"""
    print_header("TEST 4: Dashboard Summary (/dashboard/summary)")
    try:
        response = requests.get(f"{BASE_URL}/dashboard/summary", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Dashboard Summary Retrieved")
            print(f"   Total Patients: {data['total_patients']}")
            print(f"   Critical Patients: {data['critical_patients']}")
            print(f"   High Risk Patients: {data['high_risk_patients']}")
            print(f"   Timestamp: {data['timestamp']}")
            return True
        else:
            print(f"❌ Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False

def test_vitals_history():
    """Test 5: Vitals History"""
    print_header("TEST 5: Vitals History (/vitals/{patient_id})")
    try:
        # First get a patient ID
        response = requests.get(f"{BASE_URL}/patients", timeout=5)
        if response.status_code != 200:
            print("❌ Could not get patients first")
            return False
        
        patients = response.json()
        if not patients:
            print("❌ No patients found")
            return False
        
        patient_id = patients[0]['patient_id']
        
        # Now get vitals history
        response = requests.get(f"{BASE_URL}/vitals/{patient_id}?limit=5", timeout=5)
        if response.status_code == 200:
            vitals = response.json()
            print(f"✅ Retrieved {len(vitals)} vital record(s) for {patient_id}")
            for v in vitals[-3:]:  # Show last 3
                print(f"\n   Record: HR={v['heart_rate_bpm']} | Temp={v['temperature_c']}°C | SpO2={v['spo2_percent']}%")
                print(f"   └─ Time: {v.get('timestamp', 'N/A')}")
            return True
        else:
            print(f"❌ Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False

def main():
    print(f"\n{'='*60}")
    print(f"  BACKEND-MOBILE APP INTEGRATION TEST")
    print(f"  API URL: {BASE_URL}")
    print(f"  Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}")

    results = []
    
    # Run all tests
    results.append(("Health Check", test_health_check()))
    if not results[-1][1]:  # If health check failed, stop here
        print("\n⚠️  API is not running. Start it with: python run_all.py")
        return
    
    results.append(("Get Patients", test_get_patients()))
    results.append(("Get Alerts", test_get_alerts()))
    results.append(("Dashboard Summary", test_dashboard_summary()))
    results.append(("Vitals History", test_vitals_history()))
    
    # Summary
    print_header("TEST SUMMARY")
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\nResult: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Your backend-mobile integration is working!")
        print("\nNext steps:")
        print("1. Run Flutter app: flutter run")
        print("2. Open Dashboard: http://localhost:8501")
        print("3. Monitor API: http://127.0.0.1:8000/docs (auto-generated docs)")
    else:
        print("\n⚠️  Some tests failed. Check the errors above.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nTest cancelled by user")
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
