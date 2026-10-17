import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guideme/welcome/home_screen.dart';

import '../welcome/welcome_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = credential.user!.uid;
      print('✅ Logged in UID: $uid');

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final userType = data?['type'];
        final userStatus = data?['status'] ?? 'approved';

        if (userType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('نوع الحساب غير محدد. يرجى إعادة التسجيل.'.tr()),
            ),
          );
          return;
        }

        if (userType == 'guide' && userStatus != 'approved') {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('لم يتم الموافقة على حسابك بعد'.tr())),
          );
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login successful'.tr())));

        if (userType == 'guide') {
          Navigator.pushNamed(context, '/homeGuide');
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found in Firestore'.tr())),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'البريد الإلكتروني غير مسجل.';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة.';
          break;
        case 'invalid-email':
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب.';
          break;
        default:
          errorMessage = 'فشل تسجيل الدخول. حاول مرة أخرى.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع. حاول لاحقًا.'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login'.tr(),
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xff196D1F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const FirstPage()),
              (route) => false,
            );
          }, // ✅ يرجع للصفحة اللي قبلها
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const BottomAppBar(color: Color(0xff196D1F)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            child: Center(
              child: Container(
                width: screenWidth < 500 ? double.infinity : 400,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Image.asset(
                      'assets/logo.png',
                      width: screenWidth * 0.4,
                      height: screenWidth * 0.4,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Email'.tr(), Alignment.centerLeft),
                    const SizedBox(height: 5),
                    _buildTextField(_emailController),
                    const SizedBox(height: 15),
                    _buildLabel('Password'.tr(), Alignment.centerLeft),
                    const SizedBox(height: 5),
                    _buildTextField(_passwordController, obscure: true),
                    const SizedBox(height: 25),
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
                        onPressed: _signIn,
                        child: Text(
                          'Sign In'.tr(),
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgotPassword');
                      },
                      child: Text(
                        'Forgot password?'.tr(),
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: 'Enter your ${obscure ? "password" : "email"}',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }
}
