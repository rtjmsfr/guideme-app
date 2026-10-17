import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  Future<void> _navigateBasedOnUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userType = userData['type'];
        final userStatus = userData['status'];

        if (userType == 'guide') {
          if (userStatus == 'approved') {
            Navigator.pushNamed(context, '/ProfileGuideScreen');
          } else {

            await FirebaseAuth.instance.signOut();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لم يتم الموافقة على حسابك بعد')),
            );
            Navigator.pushNamed(context, '/login');
          }
        } else {
          Navigator.pushNamed(context, '/home');
        }
      } else {
        Navigator.pushNamed(context, '/home');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Future.microtask(() => _navigateBasedOnUser(context));

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
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
                Text(
                  "Discover new places and connect with qualified guides in Saudi Arabia".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff196D1F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('Login'.tr(), style: const TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff196D1F),
                      side: const BorderSide(color: Color(0xff196D1F)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                    child: Text('Register'.tr(), style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final userCredential = await FirebaseAuth.instance.signInAnonymously();
                    if (userCredential.user != null) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  child: Text(
                    'Continue as Guest'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff196D1F),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
