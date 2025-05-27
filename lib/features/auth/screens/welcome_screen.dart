import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 320,
                height: 320,
                child: Center(
                  child: Image.asset(
                    'assets/AppLogo.png',
                    width: 300,
                    height: 300,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF30B27C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8, // <-- 3D effect
                      shadowColor: const Color(0xFF30B27C).withOpacity(0.4), // <-- Soft #30B27C shadow
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/sign-in');
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0x66007800), // <-- Reduced opacity for #007800 (40% opacity)
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF007800).withOpacity(0.4),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/sign-up');
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF007800),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
