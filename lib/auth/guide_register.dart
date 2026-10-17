import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guideme/welcome/welcome_screen.dart';

class RegisterGuideScreen extends StatefulWidget {
  const RegisterGuideScreen({super.key});
  @override
  State<RegisterGuideScreen> createState() => _RegisterGuideScreenState();
}

class _RegisterGuideScreenState extends State<RegisterGuideScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _languageController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  File? _licenseFile;
  String? _licenseUrl;
  String? _selectedlang;
  Future<void> _pickLicenseFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _licenseFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _registerGuide() async {
    // Basic validation
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى ملء جميع الحقول'.tr())));
      return;
    }

    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('صيغة البريد الإلكتروني غير صحيحة'.tr())),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('كلمة المرور يجب ألا تقل عن 6 أحرف'.tr())),
      );
      return;
    }

    if (int.tryParse(_ageController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('العمر يجب أن يكون رقمًا صحيحًا'.tr())),
      );
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final licenseStatus =
          _licenseFile != null && _licenseFile!.existsSync() ? 'yes' : 'no';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'license': licenseStatus,
            'age': _ageController.text.trim(),
            'bio': _bioController.text.trim(),

            'language': _selectedlang,
            'location': _locationController.text.trim(),
            'type': 'guide',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال طلب التسجيل، في انتظار الموافقة'.tr()),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
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
          errorMessage = 'كلمة المرور ضعيفة جداً.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'إنشاء الحسابات غير مفعل حالياً.';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء التسجيل. حاول مرة أخرى.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع. حاول لاحقاً.'.tr())),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _languageController.dispose();
    _locationController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true, // مهم جداً
              value: value,
              items:
                  options.map((e) {
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: onChanged,
              validator:
                  (val) =>
                      (val == null || val.isEmpty) ? 'Required'.tr() : null,
            ),
          ),
        ],
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
        hintText: obscure ? tr('Enter your password') : tr('Enter value'),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Register as Guide'),
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const FirstPage()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth < 600 ? double.infinity : 500,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(tr('Name')),
                        const SizedBox(height: 6),
                        _buildTextField(_nameController),
                        const SizedBox(height: 16),

                        _buildLabel(tr('Username')),
                        const SizedBox(height: 6),
                        _buildTextField(_usernameController),
                        const SizedBox(height: 16),

                        _buildLabel(tr('Email')),
                        const SizedBox(height: 6),
                        _buildTextField(_emailController),
                        const SizedBox(height: 16),

                        _buildLabel(tr('Password')),
                        const SizedBox(height: 6),
                        _buildTextField(_passwordController, obscure: true),
                        const SizedBox(height: 16),

                        _buildLabel(tr('Age')),
                        const SizedBox(height: 6),
                        _buildTextField(_ageController),
                        const SizedBox(height: 16),
                        _buildLabel(tr('Bio')),
                        const SizedBox(height: 6),
                        _buildTextField(_bioController),
                        const SizedBox(height: 16),

                        _buildLabel(tr('Location')),
                        const SizedBox(height: 6),
                        _buildTextField(_locationController),

                        const SizedBox(height: 16),
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

                        const SizedBox(height: 16),
                        _buildLabel(tr('License')),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickLicenseFile,
                              icon: const Icon(
                                Icons.upload_file,
                                color: Colors.white,
                              ),
                              label: Text(
                                tr('Upload License'),
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff196D1F),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                _licenseFile != null
                                    ? _licenseFile!.path.split('/').last
                                    : tr('No file selected'),
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _registerGuide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff196D1F),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              tr('Request'),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
