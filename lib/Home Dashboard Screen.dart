import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthmobadra/api_service.dart'; // Import the file we just made
import 'package:healthmobadra/main.dart'; // For AppConfig
import 'package:healthmobadra/Heart%20Rate%20Details.dart';
import 'package:healthmobadra/SpO2%20Details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Logic Variables
  final ApiService _apiService = ApiService();
  PatientData? _patientData;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _profileLoading = true;
  String? _errorMessage; // New variable to track errors
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchData();
    // Refresh data every 2 seconds (Real-time)
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop timer when leaving screen
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await _apiService.fetchProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _profileLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
    }
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchData();
      if (mounted) {
        setState(() {
          _isLoading = false; // Always stop loading when done
          if (data != null) {
            _patientData = data;
            _errorMessage = null; // Clear error if successful
          } else if (_patientData == null) {
            // Only show error if we have NO data at all (first load failed)
            _errorMessage = "Could not connect to Hospital API.\nCheck if 'run_all.py' is running.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_patientData == null) {
             _errorMessage = "Connection Error: $e";
          }
        });
      }
    }
  }

  void _handleLogout(BuildContext context) {
    AppConfig.isAuthenticated = false;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        backgroundColor: const Color(0xFF00897b),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. Loading State
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00897b)));
    }

    // 2. Error State (No data loaded yet)
    if (_errorMessage != null && _patientData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchData();
                },
                child: const Text("Retry Connection"),
              )
            ],
          ),
        ),
      );
    }

    // 3. Data State (Dashboard)
    String userName = _userProfile?['user']?['full_name'] ?? 'Patient';
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F2F1), Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- WELCOME HEADER WITH USER NAME ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897b), Color(0xFF004d40)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _patientData!.status == 'CRITICAL'
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Status: ${_patientData!.status}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _patientData!.status == 'CRITICAL'
                            ? Colors.red[300]
                            : Colors.green[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- AI ALERT CARD (if High Risk) ---
            if (_patientData!.riskLevel == "High Risk")
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Alert: High Risk',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Risk detected (${(_patientData!.confidence * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // --- VITALS SECTION TITLE ---
            const Text(
              'Vital Signs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),

            // --- VITALS CARDS GRID ---
            MetricCard(
              title: 'Heart Rate',
              value: '${_patientData!.heartRate}',
              unit: 'bpm',
              icon: Icons.favorite,
              color: _patientData!.heartRate > 100 ? Colors.red : Color(0xFF00897b),
            ),
            MetricCard(
              title: 'Temperature',
              value: '${_patientData!.temperature}',
              unit: '°C',
              icon: Icons.thermostat,
              color: _patientData!.temperature > 37.5 ? Colors.orange : Color(0xFF00897b),
            ),
            MetricCard(
              title: 'Oxygen (SpO2)',
              value: '${_patientData!.spo2}',
              unit: '%',
              icon: Icons.air,
              color: _patientData!.spo2 < 95 ? Colors.blue : Color(0xFF00897b),
            ),
            
            const SizedBox(height: 20),
            const Divider(height: 30, thickness: 1),
            const SizedBox(height: 20),

            // --- AI RISK ASSESSMENT ---
            const Text(
              'Risk Assessment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            MetricCard(
              title: 'AI Prediction',
              value: _patientData!.riskLevel,
              unit: '',
              icon: Icons.analytics,
              color: _patientData!.riskLevel == "High Risk" ? Colors.purple : Colors.green,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.grey[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confidence: ${(_patientData!.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE WIDGET: Beautiful Metric Card ---
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- ICON CIRCLE ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          
          // --- VALUE AND UNIT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- INDICATOR DOT ---
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}