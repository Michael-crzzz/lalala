import 'package:flutter/material.dart';

void main() => runApp(const AboutUs());

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildSection(String title, String content, {IconData? icon}) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 2),
                  child: Icon(icon, color: Color.fromARGB(255, 129, 97, 75), size: 28),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(content, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.white,
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
              Color.fromARGB(255, 223, 197, 151),
              Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Logo or Avatar
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color.fromARGB(255, 129, 97, 75),
                child: const Icon(Icons.local_gas_station, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'GasApp',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 129, 97, 75),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            buildSection(
              'Our Mission',
              'To provide quality gas services and ensure safety for every home and business.',
              icon: Icons.flag,
            ),
            buildSection(
              'Our Vision',
              'To be the leading provider of safe and reliable gas solutions in the region.',
              icon: Icons.visibility,
            ),
            buildSection(
              'Contact',
              'Email: info@gasapp.com\nPhone: 123-456-7890\nAddress: 123 Main St, City, Country',
              icon: Icons.contact_mail,
            ),
          ],
        ),
      ),
    );
  }
}