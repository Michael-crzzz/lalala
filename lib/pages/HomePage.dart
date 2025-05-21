// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/button.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const Homepage());

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 106, 39, 117),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 25),
            Text(
              'DECIPHER',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 34,
                color: Colors.white,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(50.0),
              child: Image.asset('lib/images/chip.png'),
            ),

            Text(
              'Welcome to Deciphers App',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 42,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Welcome to Deciphers App, where you can monitor your kitchen whether it has a gas leak or not.',
              style: TextStyle(color: Colors.grey[100], height: 2),
            ),
            const SizedBox(height: 25),

            MyButton(text: "Get Started"),
          ],
        ),
      ),
    );
  }
}
