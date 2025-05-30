import 'package:flutter/material.dart';

void main() => runApp(const AboutUs());

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});
  
  @override
  Widget build(BuildContext context) {
    Widget buildSection(String title, String content) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.white, // Set font color to white
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 129, 97, 75),
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              buildSection('Our Mission', 'To provide quality gas services.'),
              buildSection('Our Vision', 'To be the leading gas provider.'),
              buildSection('Contact', 'Email: info@gasapp.com\nPhone: 123-456-7890'),
            ],
          ),
        ),
      ),
    );
  }
}