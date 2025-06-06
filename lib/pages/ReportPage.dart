import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:my_gas_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // Streamlined subscriptions
  StreamSubscription<DatabaseEvent>? _dailySubscription;
  StreamSubscription<DatabaseEvent>? _latestSubscription;

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
    _loadPeakReading(_dateKey(selectedDate));
    _listenToDate(selectedDate);
  }

  @override
  void dispose() {
    _dailySubscription?.cancel();
    _latestSubscription?.cancel();
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
    _dailySubscription?.cancel();
    _latestSubscription?.cancel();

    setState(() {
      isLoading = true;
      connectionStatus = 'Connecting...';
      sensorData = {}; // Clear previous data
    });

    String dateKey = _dateKey(date);
    bool isToday = dateKey == _dateKey(DateTime.now());

    // Listen to daily historical data
    _dailySubscription = database.child('sensor_data/$dateKey').onValue.listen(
      (DatabaseEvent event) {
        List<dynamic> dailyReadings = [];
        
        if (event.snapshot.exists) {
          final dataMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          dailyReadings = dataMap.values.toList();
        }
        
        // Sort historical readings by timestamp (latest first)
        dailyReadings.sort((a, b) {
          if (a is Map && b is Map) {
            var aTime = a['timestamp'];
            var bTime = b['timestamp'];
            if (aTime is String && bTime is String) {
              return bTime.compareTo(aTime);
            }
          }
          return 0;
        });

        if (isToday) {
          // For today, merge with latest reading
          _mergeWithLatestReading(dailyReadings);
        } else {
          // For other dates, use only historical data
          _updateSensorData(dailyReadings);
        }
      },
      onError: (error) {
        setState(() {
          isLoading = false;
          connectionStatus = 'Connection failed';
        });
      },
    );

    // For today's date, also listen to latest reading for real-time updates
    if (isToday) {
      _latestSubscription = database.child('gas_sensor/latest_reading').onValue.listen(
        (DatabaseEvent event) {
          if (event.snapshot.exists) {
            final latestReading = Map<String, dynamic>.from(event.snapshot.value as Map);
            
            // Get current daily readings
            List<dynamic> currentReadings = List.from(sensorData['readings'] ?? []);
            
            // Remove any readings from the same minute to avoid duplicates
            if (latestReading['timestamp'] != null) {
              currentReadings = currentReadings.where((reading) {
                if (reading is Map && reading['timestamp'] is String) {
                  // Compare timestamps down to the minute level
                  String latestMinute = latestReading['timestamp'].toString().substring(0, 16);
                  String readingMinute = reading['timestamp'].toString().substring(0, 16);
                  return readingMinute != latestMinute;
                }
                return true;
              }).toList();
            }
            
            // Add latest reading at the beginning (most recent)
            currentReadings.insert(0, latestReading);
            
            _updateSensorData(currentReadings);
          }
        },
        onError: (error) {
          print('Latest reading error: $error');
        },
      );
    }
  }

  void _mergeWithLatestReading(List<dynamic> dailyReadings) async {
    try {
      // Get the latest reading
      final latestSnapshot = await database.child('gas_sensor/latest_reading').get();
      
      if (latestSnapshot.exists) {
        final latestReading = Map<String, dynamic>.from(latestSnapshot.value as Map);
        
        // Remove any readings from the same minute to avoid duplicates
        if (latestReading['timestamp'] != null) {
          dailyReadings = dailyReadings.where((reading) {
            if (reading is Map && reading['timestamp'] is String) {
              String latestMinute = latestReading['timestamp'].toString().substring(0, 16);
              String readingMinute = reading['timestamp'].toString().substring(0, 16);
              return readingMinute != latestMinute;
            }
            return true;
          }).toList();
        }
        
        // Add latest reading at the beginning (most recent)
        dailyReadings.insert(0, latestReading);
      }
      
      _updateSensorData(dailyReadings);
    } catch (error) {
      print('Error merging latest reading: $error');
      _updateSensorData(dailyReadings);
    }
  }

  void _updateSensorData(List<dynamic> readings) {
    if (!mounted) return;
    
    setState(() {
      sensorData = {'readings': readings};
      isLoading = false;
      connectionStatus = readings.isEmpty ? 'No data available' : 'Connected';
    });

    // Debug print
    if (readings.isNotEmpty) {
      print('Updated readings count: ${readings.length}');
      print('Latest reading: ${readings.first['value']} at ${readings.first['timestamp']}');
    }
  }

  List<num> _getReadingsForDate() {
    if (sensorData.containsKey('readings')) {
      final readings = sensorData['readings'];
      if (readings is List) {
        final values = readings
            .map((e) {
              if (e is Map && e['value'] != null) {
                return e['value'] as num;
              }
              return null;
            })
            .whereType<num>()
            .toList();
        
        print('📈 Current readings for summary: $values');
        return values;
      }
    }
    return [];
  }

  Map<String, dynamic> _summarizeReadings(List<num> readings) {
    String dateKey = _dateKey(selectedDate);
    const num BASELINE = 0; // Fixed baseline
    const num THRESHOLD = 500; // Fixed threshold
    
    if (readings.isEmpty) {
      return {
        'min': BASELINE,
        'max': _peakReadings[dateKey] ?? BASELINE,
        'avg': 0.0,
        'count': 0,
        'lastReading': BASELINE,
      };
    }

    // Calculate maximum reading above threshold
    num currentMax = readings.reduce((a, b) => a > b ? a : b);
    
    // Only update peak if current reading is above threshold
    if (currentMax >= THRESHOLD) {
      if (!_peakReadings.containsKey(dateKey) || currentMax > _peakReadings[dateKey]!) {
        _peakReadings[dateKey] = currentMax;
        _savePeakReading(dateKey, currentMax);
      }
    }

    // Calculate average
    var avg = readings.reduce((a, b) => a + b) / readings.length;

    return {
      'min': BASELINE, // Always fixed at 0
      'max': _peakReadings[dateKey] ?? currentMax,
      'avg': avg,
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
    _loadPeakReading(_dateKey(selectedDate));
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
            const Divider(),
            // Add this new section
            _buildReadingLevels(summary),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingLevels(Map<String, dynamic> summary) {
    const threshold = 500.0; // Gas detection threshold
    final baseline = summary['min'];
    final peak = summary['max'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reading Levels (PPM)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLevelIndicator(
                'Baseline',
                baseline.toString(),
                baseline >= threshold ? Colors.red : Colors.green,
                Icons.arrow_downward,
              ),
              _buildLevelIndicator(
                'Threshold',
                '$threshold',
                Colors.orange,
                Icons.warning,
              ),
              _buildLevelIndicator(
                'Peak',
                peak.toString(),
                peak >= threshold ? Colors.red : Colors.green,
                Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelIndicator(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                '$value PPM',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

  String _getGasAlertStatus(List<num> readings) {
    if (readings.isEmpty) return 'No Data';
    
    final latestValue = readings.first;
    
    if (latestValue >= 500) {
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