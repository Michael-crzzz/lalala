import 'package:flutter/material.dart';
import 'package:gas_app/pages/AboutUs.dart';
import 'pages/HomePage.dart';
import 'pages/MenuPage.dart';
import 'pages/MonitorPage.dart';
import 'pages/ReportPage.dart';
import 'pages/GraphPage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Homepage(),
      routes: {
        '/homepage': (context) => const Homepage(),
        '/menupage': (context) => const MenuPage(),
        '/monitorpage': (context) => const MonitorPage(),
        '/aboutus': (context) => const AboutUs(),
        '/reportpage': (context) => const ReportPage(),
        '/graphpage': (context) => const GraphPage(),
      },
    );
  }
}
