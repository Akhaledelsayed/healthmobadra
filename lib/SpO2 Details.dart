import 'package:flutter/material.dart';
import 'package:healthmobadra/api_service.dart';

class SpO2DetailsScreen extends StatefulWidget {
  const SpO2DetailsScreen({super.key});

  @override
  State<SpO2DetailsScreen> createState() => _SpO2DetailsScreenState();
}

class _SpO2DetailsScreenState extends State<SpO2DetailsScreen> {
  final ApiService _api = ApiService();
  List<VitalSign> _vitals = [];
  bool _loading = true;
  String _selectedPeriod = 'Day';
  int _avgSpO2 = 0;
  int _minSpO2 = 0;
  int _maxSpO2 = 0;

  @override
  void initState() {
    super.initState();
    _fetchVitals();
  }

  Future<void> _fetchVitals() async {
    setState(() => _loading = true);
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
    
    final spo2s = _vitals.map((v) => v.spo2).toList();
    _avgSpO2 = (spo2s.reduce((a, b) => a + b) / spo2s.length).toInt();
    _minSpO2 = spo2s.reduce((a, b) => a < b ? a : b);
    _maxSpO2 = spo2s.reduce((a, b) => a > b ? a : b);
  }

  Color _getSpO2Color(int spo2) {
    if (spo2 < 90) return Colors.red;
    if (spo2 < 95) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpO2 (Oxygen Level)'),
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

                    // --- SPO2 STATS CARD ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Oxygen Saturation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Avg SpO2 $_avgSpO2%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getSpO2Color(_avgSpO2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getSpO2Color(_avgSpO2).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _avgSpO2 >= 95
                                  ? 'Healthy'
                                  : _avgSpO2 >= 90
                                      ? 'Acceptable'
                                      : 'Low - Medical Attention Needed',
                              style: TextStyle(
                                color: _getSpO2Color(_avgSpO2),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Min-Max range
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lowest',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_minSpO2%',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Highest',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_maxSpO2%',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- COLOR LEGEND ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SpO2 Ranges',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem('< 70%', Colors.red, 'Critical - Medical Emergency'),
                          const SizedBox(height: 8),
                          _buildLegendItem('70-89%', Colors.orange, 'Low - Seek Medical Help'),
                          const SizedBox(height: 8),
                          _buildLegendItem('≥ 90%', Colors.green, 'Healthy Range'),
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
                            'SpO2 Trend Chart',
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String description) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
