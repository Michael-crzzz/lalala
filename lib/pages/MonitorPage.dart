import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:my_gas_app/pages/AboutUs.dart';
import 'package:my_gas_app/pages/GraphPage.dart';
import 'package:my_gas_app/pages/ReportPage.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  static const double DANGER_THRESHOLD = 0.8;
  static const double WARNING_THRESHOLD = 0.5;
  static const double MAX_PPM = 500.0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late final StreamSubscription<DatabaseEvent> _subscription;
  bool _hasShownDangerNotification = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupGasMonitoring();
  }

  void _setupGasMonitoring() {
    _subscription = FirebaseDatabase.instance
        .ref('gas_sensor/latest_reading')
        .onValue
        .listen(_handleGasReading);
  }

  void _handleGasReading(DatabaseEvent event) {
    if (!mounted || event.snapshot.value == null) return;

    final data = event.snapshot.value as Map<dynamic, dynamic>;
    final double lpgPpm = (data['value'] as num?)?.toDouble() ?? 0.0;
    final double percent = (lpgPpm / MAX_PPM).clamp(0.0, 1.0);

    if (percent >= DANGER_THRESHOLD && !_hasShownDangerNotification) {
      _showDangerNotification();
      _hasShownDangerNotification = true;
    } else if (percent < DANGER_THRESHOLD) {
      _hasShownDangerNotification = false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showDangerNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gas_danger_channel',
      'Gas Danger Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Dangerous Gas Level!',
      'Gas concentration has reached dangerous levels. Please take immediate action!',
      platformChannelSpecifics,
    );
  }

  Color _getStatusColor(double percent) {
    if (percent < WARNING_THRESHOLD) return Colors.green;
    if (percent < DANGER_THRESHOLD) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(double percent) {
    if (percent < WARNING_THRESHOLD) return 'Safe Level';
    if (percent < DANGER_THRESHOLD) return 'Caution Level';
    return 'Danger Level';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gas Monitor',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 129, 97, 75),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outlined),
            tooltip: 'About Us',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutUs()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('gas_sensor/latest_reading')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red)),
            );
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          double lpgPpm = (data['value'] as num?)?.toDouble() ?? 0.0;
          double percent = (lpgPpm / MAX_PPM).clamp(0.0, 1.0);

          return Container(
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 18,
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percent < 0.5
                                ? Colors.green
                                : percent < 0.8
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_gas_station,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 48,
                          ),
                          Text(
                            lpgPpm.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          const Text(
                            'PPM',
                            style: TextStyle(
                              fontSize: 24,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'LPG Gas Concentration',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusText(percent),
                    style: TextStyle(
                      fontSize: 18,
                      color: _getStatusColor(percent),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.show_chart),
                        label: const Text('Graph'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 129, 97, 75),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const GraphPage()),
                          );
                        },
                      ),
                      const SizedBox(width: 50),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.description),
                        label: const Text('Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 129, 97, 75),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ReportPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}