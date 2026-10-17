import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _languageController;
  late TextEditingController _locationController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _usernameController = TextEditingController(text: widget.userData['username'] ?? '');
    _languageController = TextEditingController(text: widget.userData['language'] ?? '');
    _locationController = TextEditingController(text: widget.userData['location'] ?? '');
    _ageController = TextEditingController(text: widget.userData['age'] ?? '');
    if (widget.userData['type'] == 'guide') {
      _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    }

  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final updateData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'language': _languageController.text.trim(),
        'location': _locationController.text.trim(),
        'age': _ageController.text.trim(),
      };

      if (widget.userData['type'] == 'guide') {
        updateData['bio'] = _bioController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
        title:  Text('Edit profile'.tr(), style:  TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff196D1F),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration:  InputDecoration(labelText: 'Name'.tr()),
                validator: (value) =>
                value == null || value.isEmpty ? 'name required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration:  InputDecoration(labelText: 'User Name'.tr()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _languageController,
                decoration:  InputDecoration(labelText: 'Language'.tr()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration:  InputDecoration(labelText: 'Location'.tr()),
              ),
              const SizedBox(height: 16),
              TextFormField(controller:_ageController, decoration:  InputDecoration(labelText: 'Age'.tr()),
                  validator: (value) {
                if (int.tryParse(value!) == null) return 'ادخل عمرًا صحيحًا';
                return null;
              }),

              if (widget.userData['type'] == 'guide') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio'.tr(),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff196D1F),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveChanges,
                child:  Text('Save Changes'.tr(), style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
