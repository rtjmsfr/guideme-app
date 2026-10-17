import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xff196D1F),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/home'),
            ),
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/places'),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/guide'),
            ),
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/userHome'),
            ),
            IconButton(
              icon: const Icon(Icons.person_pin, color: Colors.white),
              onPressed:
                  () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Image.asset(
                  'assets/logo.png',
                  width: screenWidth * 0.4,
                  height: screenWidth * 0.4,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  "GuideMe",
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff196D1F),
                  ),
                ),
                const SizedBox(height: 16),

                // جملة ترحيبية
                Text(
                  "Discover new places and connect with qualified guides in Saudi Arabia".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
