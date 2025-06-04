import 'package:flutter/material.dart';
import 'package:gas_app/components/button.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 106, 39, 117),
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 25),
            _menuBox(
              title: 'Graph Page',
              fontSize: 28,
              buttonText: 'Graph',
              onTap: () {},
            ),
            const SizedBox(height: 40),
            _menuBox(
              title: 'Monitoring Page',
              fontSize: 28,
              buttonText: 'Monitor',
              onTap: () {},
            ),
            const SizedBox(height: 40),
            _menuBox(
              title: 'Report Generation Page',
              fontSize: 24,
              buttonText: 'Show Report',
              onTap: () {},
            ),
            const SizedBox(height: 40),
            _menuBox(
              title: 'About Us',
              fontSize: 28,
              buttonText: 'Learn More',
              onTap: () {},
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _menuBox({
    required String title,
    required double fontSize,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(185, 161, 82, 173),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: fontSize,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                MyButton(text: buttonText, onTap: onTap),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Image.asset('lib/images/bar-chart.png', height: 60),
        ],
      ),
    );
  }
}
