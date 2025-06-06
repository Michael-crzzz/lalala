import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class GasService {
  static final GasService _instance = GasService._internal();
  factory GasService() => _instance;
  GasService._internal();

  final _database = FirebaseDatabase.instance.ref();
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get latestReading {
    _database.child('gas_sensor/latest_reading').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _controller.add(data);
      }
    });

    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}