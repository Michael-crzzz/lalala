import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/button.dart';
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
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 168, 63, 184),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graph Page',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 34,
                        color: Colors.white,
                      ),
                    ),
                    MyButton(text: 'Graph', onTap: () {}),
                  ],
                ),
                Image.asset('lib/images/bar-chart.png', height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
