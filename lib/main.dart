import 'package:flutter/material.dart';
import 'package:my_gas_app/pages/AboutUs.dart'; 
import 'pages/HomePage.dart';
import 'pages/MenuPage.dart';
import 'pages/MonitorPage.dart';
import 'pages/ReportPage.dart';
import 'pages/GraphPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
      
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  runApp(const MyApp());
}

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
