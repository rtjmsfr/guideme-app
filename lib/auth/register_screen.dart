// ✅ RegisterUserScreen with validation added
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guideme/welcome/welcome_screen.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _languageController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedlang;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _languageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': _ageController.text.trim(),
        'language': _selectedlang,
        'location': _locationController.text.trim(),
        'type': 'user',
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح!')),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل.';
          break;
        case 'invalid-email':
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة، اختر كلمة أقوى.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'إنشاء الحسابات غير مفعل.';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء التسجيل. حاول مرة أخرى.';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ غير متوقع. حاول لاحقاً.')),
      );
    }
  }

  Widget _buildTextField(
      TextEditingController controller, {
        bool obscure = false,
        required String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: obscure ? tr('Enter your password') : tr('Enter your value'),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Register'), style: const TextStyle(fontSize: 20, color: Colors.white)),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth < 600 ? double.infinity : 450),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(tr('Name')),
                        const SizedBox(height: 6),
                        _buildTextField(_nameController, validator: (value) {
                          if (value == null || value.isEmpty) return 'ادخل الاسم';
                          return null;
                        }),
                        const SizedBox(height: 10),

                        _buildLabel(tr('Username')),
                        const SizedBox(height: 6),
                        _buildTextField(_usernameController, validator: (value) {
                          if (value == null || value.isEmpty) return 'ادخل اسم المستخدم';
                          return null;
                        }),
                        const SizedBox(height: 10),

                        _buildLabel(tr('Email')),
                        const SizedBox(height: 6),
                        _buildTextField(_emailController, validator: (value) {
                          if (value == null || !value.contains('@')) return 'البريد الإلكتروني غير صالح';
                          return null;
                        }),
                        const SizedBox(height: 10),

                        _buildLabel(tr('Password')),
                        const SizedBox(height: 6),
                        _buildTextField(_passwordController, obscure: true, validator: (value) {
                          if (value == null || value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          return null;
                        }),
                        const SizedBox(height: 10),

                        _buildLabel(tr('Age')),
                        const SizedBox(height: 6),
                        _buildTextField(_ageController, validator: (value) {
                          if (value == null || int.tryParse(value) == null) return 'ادخل عمرًا صحيحًا';
                          return null;
                        }),

                        const SizedBox(height: 10),

                        _buildLabel(tr('Location')),
                        const SizedBox(height: 6),
                        _buildTextField(_locationController, validator: (value) {
                          if (value == null || value.isEmpty) return 'ادخل الموقع';
                          return null;
                        }),
                        const SizedBox(height: 10),

                        _buildDropdown(
                          'Language'.tr(),
                          _selectedlang,
                          [
                            "English",
                            "Arabic",
                            "Français",
                            "Deutsch",
                            "Bengali",
                            "Español",
                            "Hindi",
                            "Bahasa Indonesia",
                            "Italiano",
                            "Türkçe",
                            "Urdu",
                          ],
                              (val) => setState(() => _selectedlang = val),
                        ),
                        const SizedBox(height: 20),

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
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _registerUser();
                              }
                            },
                            child: Text(
                              tr('Create Account'),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/registerGuide'),
                            child: Text(
                              tr('Register as a guide?'),
                              style: TextStyle(
                                color: Colors.red[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildDropdown(String label, String? value, List<String> options, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true, // مهم جداً
              value: value,
              items: options.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: onChanged,
              validator: (val) => (val == null || val.isEmpty) ? 'Required'.tr() : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
    );
  }
}
