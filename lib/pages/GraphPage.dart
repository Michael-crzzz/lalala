import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  int _selectedIndex = 0;

  static const List<String> _paths = [
    'gas_stats/daily',
    'gas_stats/weekly',
    'gas_stats/monthly',
  ];

  static const List<String> _titles = [
    'Daily',
    'Weekly',
    'Monthly',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_titles[_selectedIndex]} Gas History',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 129, 97, 75),
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
        child: _LiveBarChart(
          path: _paths[_selectedIndex],
          title: _titles[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Daily'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_view_week), label: 'Weekly'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Monthly'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _LiveBarChart extends StatelessWidget {
  final String path;
  final String title;
  // Change threshold to 500 for normal view
  static const double baseThreshold = 500.0;

  // Add method to calculate dynamic max Y
  double _calculateMaxY(List<double> data) {
    double maxValue = data.reduce((a, b) => a > b ? a : b);
    if (maxValue <= baseThreshold) {
      return baseThreshold;
    }
    // Round up to nearest 500
    return ((maxValue / 500).ceil() * 500).toDouble();
  }

  const _LiveBarChart({required this.path, required this.title});

  List<double> _parseList(dynamic value) {
    if (value is List) {
      return value.map((e) => (e as num?)?.toDouble() ?? 0.0).toList();
    }
    return [];
  }

  List<String> _getLabels(int length) {
    if (title == 'Daily') {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else if (title == 'Weekly') {
      return List.generate(length, (i) => 'W${i + 1}');
    } else if (title == 'Monthly') {
      return [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ].sublist(0, length);
    }
    return List.generate(length, (i) => (i + 1).toString());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref(path).onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('No data available'));
        }
        final data = _parseList(snapshot.data!.snapshot.value);
        if (data.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final labels = _getLabels(data.length);
        final dynamicMaxY = _calculateMaxY(data);

        return Center(
          child: AspectRatio(
            aspectRatio: 0.6,
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: BarChart(
                  BarChartData(
                    // Update maxY to use dynamic scaling
                    maxY: dynamicMaxY,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      enabled: true,  // Enable touch for value display
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.brown.withOpacity(0.8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.round()} PPM',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: dynamicMaxY / 5,  // Dynamic interval
                          getTitlesWidget: (value, meta) {
                            if (value % (dynamicMaxY / 5) == 0) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            final label = (index >= 0 && index < labels.length) ? labels[index] : '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    // Update background bars to use dynamic maxY
                    barGroups: List.generate(
                      data.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i],
                            color: data[i] > baseThreshold 
                                ? Colors.red 
                                : Colors.brown,  // Color changes for high values
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: dynamicMaxY,
                              color: Colors.brown.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}