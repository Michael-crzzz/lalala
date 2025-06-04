import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gas_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gas_app/services/gas_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ReportPage(),
  ));
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime selectedDate = DateTime.now();
  DatabaseReference database = FirebaseDatabase.instance.ref();

  // Add these fields
  StreamSubscription<DatabaseEvent>? _subscription;
  StreamSubscription<DatabaseEvent>? _latestSubscription;
  final GasService _gasService = GasService();
  StreamSubscription? _gasSubscription;

  Map<String, dynamic> sensorData = {};
  bool isLoading = true;
  String connectionStatus = 'Connecting...';

  Map<String, bool> acknowledgedDates = {};
  Map<String, num> _peakReadings = {};

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadAcknowledgedDates();
    _loadPeakReading(_dateKey(selectedDate)); // Load peak for current date
    _listenToDate(selectedDate);

    // Add this subscription
    _gasSubscription = _gasService.latestReading.listen((data) {
      if (mounted && _dateKey(selectedDate) == _dateKey(DateTime.now())) {
        _updateReadings(
          sensorData['readings'] ?? [],
          data,
          true,
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _latestSubscription?.cancel();
    _gasSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveAcknowledgedDates() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('acknowledgedDates', jsonEncode(acknowledgedDates));
  }

  Future<void> _loadAcknowledgedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('acknowledgedDates');
    if (data != null) {
      setState(() {
        acknowledgedDates = Map<String, bool>.from(jsonDecode(data));
      });
    }
  }

  void _listenToDate(DateTime date) async {
    // Cancel existing subscriptions
    _subscription?.cancel();
    _latestSubscription?.cancel();

    setState(() {
      isLoading = true;
      connectionStatus = 'Connecting...';
    });

    String dateKey = _dateKey(date);
    bool isToday = dateKey == _dateKey(DateTime.now());

    List<dynamic> dailyReadings = [];
    Map<String, dynamic>? latestReading;

    // Listen to daily data
    _subscription = database.child('sensor_data/$dateKey').onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.exists) {
          final dataMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          dailyReadings = dataMap.values.toList();
        } else {
          dailyReadings = [];
        }
        
        // For today, always get the latest reading
        if (isToday) {
          database.child('gas_sensor/latest_reading').get().then((snapshot) {
            if (snapshot.exists) {
              latestReading = Map<String, dynamic>.from(snapshot.value as Map);
            }
            _updateReadings(dailyReadings, latestReading, isToday);
          });
        } else {
          _updateReadings(dailyReadings, null, false);
        }
      },
      onError: (error) {
        setState(() {
          isLoading = false;
          connectionStatus = 'Connection failed';
        });
      },
    );

    // Listen to latest reading for real-time updates
    if (isToday) {
      _gasSubscription = _gasService.latestReading.listen((data) {
        if (mounted) {
          _updateReadings(dailyReadings, data, true);
        }
      });
    }
  }

  void _updateReadings(List<dynamic> dailyReadings, Map<String, dynamic>? latestReading, bool isToday) {
    List<dynamic> finalReadings = List.from(dailyReadings);

    // Add latest reading if it exists and is for today
    if (isToday && latestReading != null) {
      // Remove any older readings from the same minute
      finalReadings = finalReadings.where((reading) {
        if (reading is Map && reading['timestamp'] is String && latestReading['timestamp'] is String) {
          return reading['timestamp'].toString().substring(0, 16) != 
                 latestReading['timestamp'].toString().substring(0, 16);
        }
        return true;
      }).toList();
      
      finalReadings.add(latestReading);
    }

    // Sort by timestamp (latest first)
    finalReadings.sort((a, b) {
      if (a is Map && b is Map) {
        var aTime = a['timestamp'];
        var bTime = b['timestamp'];
        if (aTime is String && bTime is String) {
          return bTime.compareTo(aTime); // Latest first
        }
      }
      return 0;
    });

    setState(() {
      sensorData = {'readings': finalReadings};
      isLoading = false;
      connectionStatus = finalReadings.isEmpty ? 'No data available' : 'Connected';
    });

    // Debug print
    print('Latest readings: ${finalReadings.map((e) => e['value']).toList()}');
  }


  // Update the _getReadingsForDate method
  List<num> _getReadingsForDate() {
    if (sensorData.containsKey('readings')) {
      final readings = sensorData['readings'];
      if (readings is List) {
        final values = readings
            .map((e) {
              if (e is Map && e['value'] != null) {
                print('📊 Reading: value=${e['value']}, timestamp=${e['timestamp']}');
                return e['value'] as num;
              }
              return null;
            })
            .whereType<num>()
            .toList();
        
        // Sort values in descending order (latest first)
        values.sort((a, b) => b.compareTo(a));
        print('📈 Processed readings: $values');
        return values;
      }
    }
    return [];
  }

  Map<String, dynamic> _summarizeReadings(List<num> readings) {
    String dateKey = _dateKey(selectedDate);
    
    if (readings.isEmpty) {
      return {
        'min': 0,
        'max': _peakReadings[dateKey] ?? 0, // Use stored peak or 0
        'avg': 0.0,
        'count': 0,
        'lastReading': 0,
      };
    }

    // Get current highest reading
    num currentMax = readings.reduce((a, b) => a > b ? a : b);
    
    // Update peak if new reading is higher
    if (!_peakReadings.containsKey(dateKey) || currentMax > _peakReadings[dateKey]!) {
      _peakReadings[dateKey] = currentMax;
      _savePeakReading(dateKey, currentMax); // Save to persistent storage
    }

    // Use stored peak value
    num peakReading = _peakReadings[dateKey] ?? currentMax;
    
    return {
      'min': 0,
      'max': peakReading, // Use stored peak
      'avg': readings.reduce((a, b) => a + b) / readings.length,
      'count': readings.length,
      'lastReading': readings.first,
    };
  }

  // Add these methods for persistent storage
  Future<void> _savePeakReading(String dateKey, num value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('peak_$dateKey', value.toDouble());
  }

  Future<void> _loadPeakReading(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final peak = prefs.getDouble('peak_$dateKey');
    if (peak != null) {
      _peakReadings[dateKey] = peak;
    }
  }

  bool isAcknowledged() => acknowledgedDates[_dateKey(selectedDate)] == true;

  void _changeMonth(int offset) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + offset, 1);
    });
    _listenToDate(selectedDate);
  }

  void _changeDay(int day) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month, day);
    });
    _loadPeakReading(_dateKey(selectedDate));
    _listenToDate(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              onPressed: () => _changeMonth(-1),
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
                              onPressed: () => _changeMonth(1),
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
                                onTap: isCurrentMonth ? () => _changeDay(day) : null,
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
                        onPressed: () async {
                          setState(() {
                            acknowledgedDates[_dateKey(selectedDate)] = true;
                          });
                          await _saveAcknowledgedDates();
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
    );
  }

  Widget _buildReportItems() {
    final readings = _getReadingsForDate();
    if (readings.isEmpty) {
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

    final summary = _summarizeReadings(readings);
    final isToday = _dateKey(selectedDate) == _dateKey(DateTime.now());

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(summary),
        const SizedBox(height: 8),
        _buildStatusSection(readings),
        if (isToday && readings.first >= 500 && !isAcknowledged())
          _buildAcknowledgeButton(),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryHeader(summary),
            const Divider(),
            _buildSummaryDetails(summary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(List<num> readings) {
    final latestValue = readings.first;
    final alertColor = latestValue >= 500 ? Colors.red : Colors.green;

    return Column(
      children: [
        _buildStatusItem(
          'Gas Alert Status',
          _getGasAlertStatus(readings),
          Icons.notifications_active,
          alertColor,
        ),
        _buildStatusItem(
          'Sensor Status',
          _getSensorStatus(readings),
          Icons.sensors,
          alertColor,
        ),
        _buildStatusItem(
          'Safety Status',
          _getSafetyStatus(readings),
          Icons.security,
          alertColor,
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: value.contains('DANGER') || value.contains('UNSAFE') || value.contains('Critical Warning')
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgeButton() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Acknowledge Alert'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          setState(() {
            acknowledgedDates[_dateKey(selectedDate)] = true;
          });
          await _saveAcknowledgedDates();
        },
      ),
    );
  }

  Widget _buildSummaryHeader(Map<String, dynamic> summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Gas Readings Summary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
            fontSize: 16,
          ),
        ),
        Text(
          'Total Logs: ${summary['count']}',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.brown,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDetails(Map<String, dynamic> summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Baseline: ${summary['min']} PPM',
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              'Peak: ${summary['max']} PPM',
              style: TextStyle(
                color: summary['max'] >= 500 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Average: ${summary['avg'].toStringAsFixed(1)} PPM',
              style: TextStyle(
                color: summary['avg'] >= 500 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Latest: ${summary['lastReading']} PPM',
              style: TextStyle(
                color: summary['lastReading'] >= 500 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Update the gas alert methods to check latest value first
  String _getGasAlertStatus(List<num> readings) {
    print('🚨 Checking gas alert status');
    if (readings.isEmpty) return 'No Data';
    
    // Get the latest reading (first after sorting)
    final latestValue = readings.first;
    print('📊 Latest value: $latestValue');
    
    // Always show DANGER if value is >= 500, regardless of acknowledgment
    if (latestValue >= 500) {
      print('⚠️ DANGER detected!');
      return 'DANGER - Gas Detected!';
    }
    
    return isAcknowledged() ? 'SAFE - Acknowledged' : 'SAFE - Normal Levels';
  }

  String _getSensorStatus(List<num> readings) {
    if (readings.isEmpty) return 'No Data';
    final latestValue = readings.first;
    return latestValue >= 500 ? 'Active - DANGER' : 'Active';
  }

  String _getSafetyStatus(List<num> readings) {
    if (readings.isEmpty) return 'No Data';
    final latestValue = readings.first;
    return latestValue >= 500 ? 'UNSAFE' : 'SECURE';
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