import 'package:flutter/material.dart';

import 'account_choice_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Butterfly
              Image.asset(
                'assets/images/butterfly.png',
                width: 135,
                height: 135,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),

              // App name
              const Text(
                'Welcome to brié',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D4A5B),
                ),
              ),

              const SizedBox(height: 14),

              // Main message
              const Text(
                'A little space to breathe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A6070),
                ),
              ),

              const SizedBox(height: 10),

              // Supporting message
              const Text(
                'Slow down & be gentle with yourself.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF9B7886)),
              ),

              const SizedBox(height: 45),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountChoiceScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE62461),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Footer
              const Text(
                'A gentle place made just for you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF9B7886)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
