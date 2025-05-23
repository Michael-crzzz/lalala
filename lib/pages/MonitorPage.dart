import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  double lpgPpm = 0;
  bool loading = false;

  final String url =
      'https://thingsboard.cloud/api/plugins/telemetry/DEVICE/080fe8f0-37a4-11f0-9778-a73e030dc473/values/timeseries?keys=gas';
  final String username = 'shenelshincampo15@gmail.com'; // <-- Replace
  final String password = 'campo111'; // <-- Replace
  final String deviceName = 'mq2_gas'; // <-- Replace

  String jwtToken =
      'Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJzaGVuZWxzaGluY2FtcG8xNUBnbWFpbC5jb20iLCJ1c2VySWQiOiJiYmQ5Njk3MC0zN2EzLTExZjAtYjljNy1jZjI2MjkzNjlhY2QiLCJzY29wZXMiOlsiVEVOQU5UX0FETUlOIl0sInNlc3Npb25JZCI6IjA0OWNmNDM5LWZmNzktNDBiMS1iYWM4LWM0OTUyYjlhNzY0NiIsImV4cCI6MTc0ODA1MDEwNiwiaXNzIjoidGhpbmdzYm9hcmQuY2xvdWQiLCJpYXQiOjE3NDgwMjEzMDYsImZpcnN0TmFtZSI6IlNoZW5lbCIsImxhc3ROYW1lIjoiQ2FtcG8iLCJlbmFibGVkIjp0cnVlLCJpc1B1YmxpYyI6ZmFsc2UsImlzQmlsbGluZ1NlcnZpY2UiOmZhbHNlLCJwcml2YWN5UG9saWN5QWNjZXB0ZWQiOnRydWUsInRlcm1zT2ZVc2VBY2NlcHRlZCI6dHJ1ZSwidGVuYW50SWQiOiJiYjlhM2Q5MC0zN2EzLTExZjAtYjljNy1jZjI2MjkzNjlhY2QiLCJjdXN0b21lcklkIjoiMTM4MTQwMDAtMWRkMi0xMWIyLTgwODAtODA4MDgwODA4MDgwIn0.aVObGIYss7Kc5r0HG2sjgx2SOg6anjRsFASv-P-pPBEv5HuexGZV6w97OVkzzHr4m1DvUlMVLRDlmA7sLESgCQ';
  String deviceId = '080fe8f0-37a4-11f0-9778-a73e030dc473';

  @override
  void initState() {
    super.initState();
    loginAndFetchData();
  }

  Future<void> loginAndFetchData() async {
    setState(() => loading = true);
    try {
      await loginToThingsBoard();
      await fetchDeviceId();
      await fetchLpgPpm();
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        lpgPpm = 0;
        loading = false;
      });
    }
  }

  Future<void> loginToThingsBoard() async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      jwtToken = data['token'];
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<void> fetchDeviceId() async {
    final url = Uri.parse('$baseUrl/api/tenant/devices?deviceName=$deviceName');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      deviceId = data['id']['id'];
    } else {
      throw Exception('Device not found: ${response.statusCode}');
    }
  }

  Future<void> fetchLpgPpm() async {
    final url = Uri.parse(
      '$baseUrl/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries?keys=gas',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final value = double.tryParse(data['gas']?.first['value'] ?? '') ?? 0;
      setState(() {
        lpgPpm = value;
        loading = false;
      });
    } else {
      throw Exception('Failed to fetch telemetry: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxPpm = 2000;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Page'),
        backgroundColor: Colors.deepPurple,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pushReplacementNamed(context, '/homepage'),
            ),
            ListTile(
              leading: const Icon(Icons.monitor),
              title: const Text('Monitor'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Center(
        child:
            loading
                ? const CircularProgressIndicator()
                : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: lpgPpm),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    double percent = (value / maxPpm).clamp(0.0, 1.0);
                    return Column(
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
                                backgroundColor: Colors.deepPurple.shade100,
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
                                  color: Colors.deepPurple,
                                  size: 48,
                                ),
                                Text(
                                  '${value.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const Text(
                                  'PPM',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'LPG Gas Concentration',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: loginAndFetchData,
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}
