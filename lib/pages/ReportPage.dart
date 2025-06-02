import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gas_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ReportPage());
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime selectedDate = DateTime.now();
  DatabaseReference database = FirebaseDatabase.instance.ref();

  // Data variables
  Map<String, dynamic> sensorData = {};
  bool isLoading = true;
  String connectionStatus = 'Connecting...';
  bool alertAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _setupFirebaseListener();
  }

  void _setupFirebaseListener() {
    setState(() {
      isLoading = true;
      connectionStatus = 'Connecting...';
    });
    String dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    database.child('sensor_data/$dateKey').onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final dataMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        final readings = dataMap.values.toList();
        setState(() {
          sensorData = {'readings': readings};
          isLoading = false;
          connectionStatus = 'Connected';
        });
      } else {
        setState(() {
          sensorData = {};
          isLoading = false;
          connectionStatus = 'No data available';
          alertAcknowledged = false; // <-- Reset on no data too
        });
      }
    }).onError((error) {
      setState(() {
        isLoading = false;
        connectionStatus = 'Connection failed';
        alertAcknowledged = false;
      });
    });
  }

  // Get data for selected date
  Map<String, dynamic> _getDataForDate(DateTime date) {
    return sensorData;
  }

  // Get readings list for selected date
  List<num> _getReadingsForDate() {
    if (sensorData.containsKey('readings')) {
      final readings = sensorData['readings'];
      if (readings is List) {
        return readings
            .map((e) => (e is Map && e['value'] != null) ? (e['value'] as num) : null)
            .whereType<num>()
            .toList();
      }
      if (readings is Map) {
        return readings.values
            .map((e) => (e is Map && e['value'] != null) ? (e['value'] as num) : null)
            .whereType<num>()
            .toList();
      }
    }
    return [];
  }

  // Summarize readings
  Map<String, dynamic> _summarizeReadings(List<num> readings) {
    if (readings.isEmpty) return {'min': 0, 'max': 0, 'avg': 0, 'count': 0};
    final min = readings.reduce((a, b) => a < b ? a : b);
    final max = readings.reduce((a, b) => a > b ? a : b);
    final avg = readings.reduce((a, b) => a + b) / readings.length;
    return {'min': min, 'max': max, 'avg': avg, 'count': readings.length};
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'LPG Gas Detector Report',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 129, 97, 75),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLoading ? Icons.sync : Icons.cloud_done,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectionStatus,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 223, 197, 151),
                Color(0xFFFFF8E1),
              ],
            ),
          ),
          child: Column(
            children: [
              // Top Report Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Report Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromARGB(255, 129, 97, 75)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Gas Sensor Report',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 129, 97, 75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Calendar Section
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromARGB(255, 129, 97, 75).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.5),
                      ),
                      child: Column(
                        children: [
                          // Calendar Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month - 1,
                                    );
                                    alertAcknowledged = false; // Reset only on date change
                                  });
                                  _setupFirebaseListener();
                                },
                                icon: const Icon(Icons.chevron_left, color: Color.fromARGB(255, 129, 97, 75)),
                              ),
                              Text(
                                '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 129, 97, 75),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month + 1,
                                    );
                                    alertAcknowledged = false; // Reset only on date change
                                  });
                                  _setupFirebaseListener();
                                },
                                icon: const Icon(Icons.chevron_right, color: Color.fromARGB(255, 129, 97, 75)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Calendar Grid
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1,
                              ),
                              itemCount: 42, // 6 weeks * 7 days
                              itemBuilder: (context, index) {
                                int day = index - _getFirstDayOffset() + 1;
                                bool isCurrentMonth = day > 0 && day <= _getDaysInMonth();
                                bool isSelected = day == selectedDate.day && isCurrentMonth;

                                return GestureDetector(
                                  onTap: isCurrentMonth ? () {
                                    setState(() {
                                      selectedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        day,
                                      );
                                      alertAcknowledged = false; // Reset only on date change
                                    });
                                    _setupFirebaseListener();
                                  } : null,
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color.fromARGB(255, 129, 97, 75)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: const Color.fromARGB(255, 129, 97, 75).withOpacity(0.3),
                                              width: 0.5,
                                            ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isCurrentMonth ? day.toString() : '',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : isCurrentMonth
                                                  ? const Color.fromARGB(255, 129, 97, 75)
                                                  : Colors.grey,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Report Details Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Details - ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 129, 97, 75),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Report Items
                      Expanded(
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color.fromARGB(255, 129, 97, 75),
                                ),
                              )
                            : _buildReportItems(),
                      ),
                      // Acknowledge Alert Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Acknowledge Alert'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              alertAcknowledged = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItems() {
    Map<String, dynamic> dayData = _getDataForDate(selectedDate);
    final readings = _getReadingsForDate();
    final summary = _summarizeReadings(readings);

    if (dayData.isEmpty) {
      return const Center(
        child: Text(
          'No data available for selected date',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 129, 97, 75),
          ),
        ),
      );
    }

    return ListView(
      children: [
        // --- Gas Readings Summary Card ---
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gas Readings Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('Min: ${summary['min']}'),
              Text('Max: ${summary['max']}'),
              Text('Average: ${summary['avg'].toStringAsFixed(2)}'),
              Text('Total Readings: ${summary['count']}'),
            ],
          ),
        ),
        _buildReportItem(
          icon: Icons.notifications_active,
          label: 'Gas Alert Status',
          value: _getGasAlertStatus(readings),
          time: '', // or show last reading time if you want
        ),
        _buildReportItem(
          icon: Icons.sensors,
          label: 'Sensor Status',
          value: 'Active', // or compute if you have logic for this
          time: '',
        ),
        _buildReportItem(
          icon: Icons.security,
          label: 'Safety Status',
          value: _getSafetyStatus(readings),
          time: '',
        ),
        _buildReportItem(
          icon: Icons.warning_amber,
          label: 'Warning Level',
          value: _getWarningLevel(readings),
          time: '',
        ),
      ],
    );
  }

  String _getGasAlertStatus(List<num> readings) {
    if (alertAcknowledged) return 'SAFE - Normal Levels';
    if (readings.any((v) => v > 1000)) return 'CRITICAL - Gas Detected!';
    if (readings.any((v) => v > 500)) return 'WARNING - Elevated Levels';
    if (readings.isNotEmpty) return 'SAFE - Normal Levels';
    return 'No Data';
  }

  String _getSafetyStatus(List<num> readings) {
    if (alertAcknowledged) return 'SECURE';
    if (readings.any((v) => v > 1000)) return 'UNSAFE';
    if (readings.any((v) => v > 500)) return 'CAUTION';
    if (readings.isNotEmpty) return 'SECURE';
    return 'No Data';
  }

  String _getWarningLevel(List<num> readings) {
    if (alertAcknowledged) return 'Normal';
    if (readings.any((v) => v > 1000)) return 'Critical Warning';
    if (readings.any((v) => v > 500)) return 'Elevated Warning';
    if (readings.isNotEmpty) return 'Normal';
    return 'No Data';
  }

  Widget _buildReportItem({
    required IconData icon,
    required String label,
    required String value,
    required String time,
  }) {
    // Determine color based on alert level
    Color alertColor = const Color.fromARGB(255, 129, 97, 75);
    if (value.contains('CRITICAL')) {
      alertColor = Colors.red;
    } else if (value.contains('WARNING') || value.contains('CAUTION')) {
      alertColor = Colors.orange;
    } else if (value.contains('SAFE') || value.contains('SECURE')) {
      alertColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 197, 151).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: alertColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: alertColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: alertColor.withOpacity(0.8),
                    fontWeight: value.contains('CRITICAL') || value.contains('WARNING')
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Time
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: alertColor.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  int _getFirstDayOffset() {
    DateTime firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    return firstDay.weekday % 7;
  }

  int _getDaysInMonth() {
    return DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
  }
}