import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Graph',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 129, 97, 75),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _LiveBarChart(path: 'gas_stats/daily', title: 'Daily'),
            _LiveBarChart(path: 'gas_stats/weekly', title: 'Weekly'),
            _LiveBarChart(path: 'gas_stats/monthly', title: 'Monthly'),
          ],
        ),
      ),
    );
  }
}

class _LiveBarChart extends StatelessWidget {
  final String path;
  final String title;
  static const double threshold = 2000.0;

  const _LiveBarChart({required this.path, required this.title});

  List<double> _parseList(dynamic value) {
    if (value is List) {
      return value.map((e) => (e as num?)?.toDouble() ?? 0.0).toList();
    }
    return [];
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
                    alignment: BarChartAlignment.spaceAround,
                    maxY: threshold,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 100,
                          getTitlesWidget: (value, meta) {
                            if (value % 100 == 0 && value <= threshold) {
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
                            final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[value.toInt() % labels.length],
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
                    barGroups: List.generate(
                      data.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i],
                            color: Colors.brown,
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: threshold,
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