import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/TranslationService.dart';
import '../core/translate_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedLangCode = 'en';
  Map<String, String> languages = {};
  TextEditingController inputController = TextEditingController();
  String fromLang = 'en';
  String toLang = 'ar';
  Map<String, String> serverLanguages = {};

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _loadSavedLanguage();
    _fetchServerLanguages();
  }

  Future<void> _fetchServerLanguages() async {
    final langs = await TranslationService.fetchSupportedLanguages();
    setState(() {
      serverLanguages = langs;
      fromLang = langs.keys.first;
      toLang =
          langs.keys.length > 1 ? langs.keys.elementAt(1) : langs.keys.first;
    });
  }

  Future<void> _loadLanguages() async {
    final String jsonStr = await rootBundle.loadString(
      'assets/langs/langs.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonStr);
    setState(() {
      languages = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    });
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang =
        prefs.getString('selected_language') ?? context.locale.languageCode;
    setState(() {
      selectedLangCode = savedLang;
    });
  }

  Future<void> _onLanguageChanged(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);

    final newLocale = Locale(langCode);
    await context.setLocale(newLocale);

    setState(() {
      selectedLangCode = langCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("email".tr(), style: const TextStyle(color: Colors.green)),
            Container(
              margin: const EdgeInsets.only(bottom: 20, top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(user?.email ?? 'No Email'),
            ),

            DropdownButtonFormField<String>(
              value: selectedLangCode,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items:
                  languages.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _onLanguageChanged(value);
                }
              },
              hint: const Text("language").tr(),
            ),

            const SizedBox(height: 20),
            const Divider(height: 40),
            Text(
              "${'Translation'.tr()}:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: inputController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter...".tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 10),
            BlocBuilder<TranslationCubit, TranslationState>(
              builder: (context, state) {
                if (state is TranslationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TranslationSuccessMultiple) {
                  final original = inputController.text.trim();
                  final translated =
                      state.translations[original] ?? 'not translated';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      translated,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                } else if (state is TranslationError) {
                  return Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Flexible(
                  child: DropdownButtonFormField<String>(
                    value: fromLang,
                    decoration: InputDecoration(
                      labelText: "From".tr(),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        serverLanguages.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => fromLang = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: DropdownButtonFormField<String>(
                    value: toLang,
                    decoration: InputDecoration(
                      labelText: "To".tr(),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        serverLanguages.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => toLang = val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final text = inputController.text.trim();
                if (text.isNotEmpty) {
                  context.read<TranslationCubit>().translateTexts(
                    texts: [text],
                    from: fromLang,
                    to: toLang,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff196D1F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Translate".tr(),
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                // دعم التواصل
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff196D1F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "contact_support".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff196D1F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "logout".tr(),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
