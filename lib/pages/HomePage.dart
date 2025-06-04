// ignore: file_names
import 'package:flutter/material.dart';
import 'package:gas_app/components/button.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const Homepage());

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color.fromARGB(255, 223, 197, 151),
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
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(50.0),
              child: Image.asset(
                'lib/images/lel.png',
                fit: BoxFit.contain,
                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                  print('Error loading image: $exception'); // Debug message
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              'Welcome to Deciphers App',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 42,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Welcome to Deciphers App, where you can monitor your kitchen whether it has a gas leak or not.',
              style: TextStyle(color: Color.fromARGB(255, 7, 1, 8), height: 2),
            ),
            const SizedBox(height: 25),
            MyButton(
              text: "Get Started",
              onTap: () {
                Navigator.pushNamed(context, '/monitorpage');
              },
            ),
          ],
        ),
      ),
    );
  }
}
