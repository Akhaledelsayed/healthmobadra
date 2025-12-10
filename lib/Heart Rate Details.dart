import 'package:flutter/material.dart';
import 'package:healthmobadra/api_service.dart';

class HeartRateDetailsScreen extends StatefulWidget {
  const HeartRateDetailsScreen({super.key});

  @override
  State<HeartRateDetailsScreen> createState() => _HeartRateDetailsScreenState();
}

class _HeartRateDetailsScreenState extends State<HeartRateDetailsScreen> {
  final ApiService _api = ApiService();
  List<VitalSign> _vitals = [];
  bool _loading = true;
  String _selectedPeriod = 'Day';
  int _avgHeartRate = 0;
  int _minHeartRate = 0;
  int _maxHeartRate = 0;

  @override
  void initState() {
    super.initState();
    _fetchVitals();
  }

  Future<void> _fetchVitals() async {
    setState(() => _loading = true);
    // Get patient ID from profile
    final profile = await _api.fetchProfile();
    if (profile != null) {
      final patientId = profile['user']['patient_id'] ?? 'P001';
      final vitals = await _api.fetchVitalsHistory(patientId, limit: 100);
      
      if (vitals.isNotEmpty) {
        setState(() {
          _vitals = vitals;
          _calculateStats();
          _loading = false;
        });
      }
    }
    setState(() => _loading = false);
  }

  void _calculateStats() {
    if (_vitals.isEmpty) return;
    
    final rates = _vitals.map((v) => v.heartRate).toList();
    _avgHeartRate = (rates.reduce((a, b) => a + b) / rates.length).toInt();
    _minHeartRate = rates.reduce((a, b) => a < b ? a : b);
    _maxHeartRate = rates.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate'),
        backgroundColor: const Color(0xFF00897b),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0F2F1), Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TIME PERIOD SELECTOR ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Day', 'Week', 'Month', 'Year'].map((period) {
                          bool isSelected = _selectedPeriod == period;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedPeriod = period);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00897b)
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  period,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- STATS CARDS ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF7043).withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Heart Rate Range',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_minHeartRate - $_maxHeartRate',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF7043),
                                    ),
                                  ),
                                  Text(
                                    'Heart rate range',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$_avgHeartRate',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00897b),
                                    ),
                                  ),
                                  Text(
                                    'Average',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: _minHeartRate,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7043),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: _avgHeartRate - _minHeartRate,
                                  child: Container(
                                    color: const Color(0xFFFFA726),
                                  ),
                                ),
                                Expanded(
                                  flex: _maxHeartRate - _avgHeartRate,
                                  child: Container(
                                    color: const Color(0xFF00897b),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- CHART PLACEHOLDER ---
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Heart Rate Chart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_vitals.length} measurements available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- INSIGHTS ---
                    const Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004d40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red[600], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resting Heart Rate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your average resting heart rate is $_avgHeartRate bpm.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
