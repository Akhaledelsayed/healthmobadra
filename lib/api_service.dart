import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. CONFIGURATION
class AppConstants {
  // Dynamic URL selection based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000'; // Web browser
    } else {
      return 'http://10.0.2.2:8000';  // Android Emulator
    }
  }
  
  // Timeout for network requests
  static const Duration requestTimeout = Duration(seconds: 10);
}

// 2. DATA MODELS (Matching your Python JSON)
class PatientData {
  final String patientId;
  final String name;
  final int heartRate;
  final double temperature;
  final int spo2;
  final String status;    // NORMAL, CRITICAL
  final String riskLevel; // Low Risk, High Risk
  final double confidence;

  PatientData({
    required this.patientId,
    required this.name,
    required this.heartRate,
    required this.temperature,
    required this.spo2,
    required this.status,
    required this.riskLevel,
    required this.confidence,
  });

  factory PatientData.fromJson(Map<String, dynamic> json) {
    return PatientData(
      patientId: json['patient_id'] ?? 'UNKNOWN',
      name: json['full_name'] ?? 'Unknown',
      heartRate: json['heart_rate_bpm'] ?? 0,
      temperature: (json['temperature_c'] ?? 0).toDouble(),
      spo2: json['spo2_percent'] ?? 0,
      status: json['health_status'] ?? 'NORMAL',
      riskLevel: json['risk_level'] ?? 'Low Risk',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

class VitalSign {
  final int id;
  final String patientId;
  final int heartRate;
  final double temperature;
  final int spo2;
  final String status;
  final String? timestamp;

  VitalSign({
    required this.id,
    required this.patientId,
    required this.heartRate,
    required this.temperature,
    required this.spo2,
    required this.status,
    this.timestamp,
  });

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['id'] ?? 0,
      patientId: json['patient_id'] ?? '',
      heartRate: json['heart_rate_bpm'] ?? 0,
      temperature: (json['temperature_c'] ?? 0).toDouble(),
      spo2: json['spo2_percent'] ?? 0,
      status: json['health_status'] ?? 'NORMAL',
      timestamp: json['timestamp'],
    );
  }
}

class AlertData {
  final int id;
  final String patientId;
  final String fullName;
  final String alertType;
  final String? message;
  final String? timestamp;

  AlertData({
    required this.id,
    required this.patientId,
    required this.fullName,
    required this.alertType,
    this.message,
    this.timestamp,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      id: json['id'] ?? 0,
      patientId: json['patient_id'] ?? '',
      fullName: json['full_name'] ?? 'Unknown',
      alertType: json['alert_type'] ?? 'INFO',
      message: json['message'],
      timestamp: json['timestamp'],
    );
  }
}

class DashboardSummary {
  final int totalPatients;
  final int criticalPatients;
  final int highRiskPatients;
  final String timestamp;

  DashboardSummary({
    required this.totalPatients,
    required this.criticalPatients,
    required this.highRiskPatients,
    required this.timestamp,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalPatients: json['total_patients'] ?? 0,
      criticalPatients: json['critical_patients'] ?? 0,
      highRiskPatients: json['high_risk_patients'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

// 3. API SERVICE
class ApiService {
  static const String _kTokenKey = 'access_token';
  // Health check endpoint
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/'))
          .timeout(AppConstants.requestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      print("Connection check failed: $e");
      return false;
    }
  }

  // ------------------------ Auth ------------------------
  Future<Map<String, dynamic>> register(String username, String password, {String fullName = ''}) async {
    try {
      final response = await http
          .post(Uri.parse('${AppConstants.baseUrl}/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'username': username,
                'password': password,
                'full_name': fullName
              }))
          .timeout(AppConstants.requestTimeout);

      print('REGISTER RESPONSE: Status=${response.statusCode}, Body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final token = data['access_token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kTokenKey, token);
          return {'success': true, 'message': 'Registration successful'};
        }
        return {'success': false, 'message': 'No access token in response'};
      } else {
        // Extract error detail from server response
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final detail = data['detail'] ?? 'Server error';
          print('ERROR DETAIL: $detail');
          return {'success': false, 'message': detail};
        } catch (parseError) {
          print('PARSE ERROR: $parseError, Raw body: ${response.body}');
          return {'success': false, 'message': 'Registration failed: ${response.statusCode}'};
        }
      }
    } catch (e) {
      print('NETWORK ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http
          .post(Uri.parse('${AppConstants.baseUrl}/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'username': username, 'password': password}))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final token = data['access_token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kTokenKey, token);
          return {'success': true, 'message': 'Login successful'};
        }
      } else {
        // Extract error detail from server response
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final detail = data['detail'] ?? 'Login failed';
          return {'success': false, 'message': detail};
        } catch (e) {
          return {'success': false, 'message': 'Login failed: ${response.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
    return {'success': false, 'message': 'Login failed'};
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/users/me'), headers: {'Authorization': 'Bearer $token'})
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Fetch profile failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }

  // Fetch single patient data (for real-time dashboard)
  Future<PatientData?> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/patients'))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return PatientData.fromJson(data[0]);
        }
      } else {
        print('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error connecting to API: $e");
    }
    return null;
  }

  // Fetch all patients
  Future<List<PatientData>> fetchAllPatients() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/patients'))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PatientData.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching patients: $e");
    }
    return [];
  }

  // Fetch specific patient details
  Future<Map<String, dynamic>?> fetchPatientDetail(String patientId) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/patients/$patientId'))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching patient detail: $e");
    }
    return null;
  }

  // Fetch vitals history for charts
  Future<List<VitalSign>> fetchVitalsHistory(
    String patientId, {
    int limit = 20,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(
              '${AppConstants.baseUrl}/vitals/$patientId?limit=$limit'))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => VitalSign.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching vitals history: $e");
    }
    return [];
  }

  // Fetch alerts
  Future<List<AlertData>> fetchAlerts({int limit = 20}) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/alerts?limit=$limit'))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AlertData.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching alerts: $e");
    }
    return [];
  }

  // Fetch patient-specific alerts
  Future<List<AlertData>> fetchPatientAlerts(
    String patientId, {
    int limit = 10,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(
              '${AppConstants.baseUrl}/alerts/$patientId?limit=$limit'))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AlertData.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching patient alerts: $e");
    }
    return [];
  }

  // Fetch dashboard summary
  Future<DashboardSummary?> fetchDashboardSummary() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/dashboard/summary'))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return DashboardSummary.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print("Error fetching dashboard summary: $e");
    }
    return null;
  }
}