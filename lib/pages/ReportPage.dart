import 'package:flutter/material.dart';

void main() => runApp(const ReportPage());

class ReportPage extends StatelessWidget{
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 129, 97, 75),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 223, 197, 151), // Beige
              Color(0xFFFFF8E1), // Light beige (a very light beige)
            ],
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Report functionality is under development.',
              style: TextStyle(fontSize: 18, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}