import 'package:flutter/material.dart';
import 'package:gas_app/pages/AboutUs.dart';
import 'package:gas_app/pages/GraphPage.dart';
import 'package:gas_app/pages/ReportPage.dart';
import 'package:firebase_database/firebase_database.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
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
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          double lpgPpm = (data['value'] as num?)?.toDouble() ?? 0.0;
          double maxPpm = 2000;
          double percent = (lpgPpm / maxPpm).clamp(0.0, 1.0);

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
                    percent < 0.5
                        ? 'Safe Level'
                        : percent < 0.8
                            ? 'Caution Level'
                            : 'Danger Level',
                    style: TextStyle(
                      fontSize: 18,
                      color: percent < 0.5
                          ? Colors.green
                          : percent < 0.8
                              ? Colors.orange
                              : Colors.red,
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