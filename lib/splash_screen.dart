import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Delay for 2-3 seconds before routing to home
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/'); // Navigate to your home route
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB91C5C), // pink background
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circle container
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white, // background color of circle
              ),
            ),

            // Logo on top
            Image.asset('assets/images/logo_pink.png', width: 120, height: 120),
          ],
        ),
      ),
    );
  }
}
