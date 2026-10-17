import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'viewGuide.dart';

//سويت كومنت لكل شي يخص الفلتره بالرخصه لان مدري ليش ستل فيه...
// License filter disabled — all registered guides are already verified,
// so filtering by license contradicts GuideMe's core feature.
class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  List<Map<String, dynamic>> guides = [];
  bool isLoading = true;
  //bool filterByLicense = false;
  String? selectedLanguage;
  double? selectedRating;

  final List<String> languages = ['All', 'English', 'Arabic', 'French'];
  final List<double> ratings = [5, 4, 3, 2];

  @override
  void initState() {
    super.initState();
    fetchGuides();
  }

  Future<void> fetchGuides() async {
    final guideSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'guide')
            .get();

    setState(() {
      guides =
          guideSnapshot.docs
              .where(
                (doc) =>
                    !doc.data().containsKey('status') ||
                    doc['status'] == 'approved',
              )
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              })
              .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guides'.tr(), style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff196D1F),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
      ),
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
              onPressed: () => Navigator.pushNamed(context, '/places'),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/guide'),
            ),
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/userHome'),
            ),
            IconButton(
              icon: const Icon(Icons.person_pin, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) {
                                String? tempSelectedLanguage =
                                    selectedLanguage ?? 'All';
                                double? tempSelectedRating = selectedRating;

                                return StatefulBuilder(
                                  builder: (context, setModalState) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Filter Guides".tr(),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          DropdownButtonFormField<String>(
                                            value: tempSelectedLanguage,
                                            decoration: InputDecoration(
                                              labelText: "Language".tr(),
                                            ),
                                            items:
                                                languages.map((lang) {
                                                  return DropdownMenuItem(
                                                    value: lang,
                                                    child: Text(lang),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              setModalState(
                                                () =>
                                                    tempSelectedLanguage =
                                                        value,
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 16),

                                          DropdownButtonFormField<double>(
                                            value: tempSelectedRating,
                                            decoration: InputDecoration(
                                              labelText: "Minimum Rating".tr(),
                                            ),
                                            items:
                                                ratings.map((r) {
                                                  return DropdownMenuItem(
                                                    value: r,
                                                    child: Text('$r+'),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              setModalState(
                                                () =>
                                                    tempSelectedRating = value,
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                selectedLanguage =
                                                    tempSelectedLanguage;
                                                selectedRating =
                                                    tempSelectedRating;
                                              });
                                              Navigator.pop(
                                                context,
                                              ); // Close sheet
                                            },
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              "Apply Filter".tr(),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xff196D1F,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.black),
                          onPressed: () async {
                            final result =
                                await showSearch<Map<String, dynamic>?>(
                                  context: context,
                                  delegate: GuideSearchDelegate(
                                    allGuides: guides,
                                  ),
                                );
                            if (result != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ViewGuideScreen(guide: result),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final filteredGuides =
                            guides.where((g) {
                              //final hasLicense = !filterByLicense || (g['license'] != null && g['license'].toString().isNotEmpty);
                              final matchesLang =
                                  selectedLanguage == null ||
                                  selectedLanguage == 'All' ||
                                  (g['language']
                                          ?.toString()
                                          .toLowerCase()
                                          .contains(
                                            selectedLanguage!.toLowerCase(),
                                          ) ??
                                      false);
                              final matchesRating =
                                  selectedRating == null ||
                                  (g['averageRating'] != null &&
                                      (g['averageRating'] as num) >=
                                          selectedRating!);
                              return /*hasLicense && */ matchesLang &&
                                  matchesRating;
                            }).toList();

                        return ListView.builder(
                          itemCount: filteredGuides.length,
                          itemBuilder: (context, index) {
                            final guide = filteredGuides[index];
                            return Card(
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            guide['name'] ?? 'No Name',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${'Email'.tr()}: ${guide['email'] ?? 'N/A'}',
                                          ),
                                          Text(
                                            '${'Username'.tr()}: ${guide['username'] ?? 'N/A'}',
                                          ),
                                          if (guide.containsKey('language'))
                                            Text(
                                              '${'Language'.tr()}: ${guide['language']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (guide.containsKey(
                                            'averageRating',
                                          ))
                                            Text(
                                              '${'Rating'.tr()}: ${guide['averageRating'].toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => ViewGuideScreen(
                                                        guide: guide,
                                                      ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xff196D1F,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Show more'.tr(),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class GuideSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> allGuides;

  GuideSearchDelegate({required this.allGuides});

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    final results =
        allGuides
            .where(
              (g) => (g['name'] ?? '').toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
    if (results.isEmpty) {
      return const Center(child: Text('No results found'));
    }
    return ListView(
      children:
          results.map((guide) {
            return ListTile(
              title: Text(guide['name'] ?? 'Unknown'),
              onTap: () => close(context, guide),
            );
          }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        allGuides
            .where(
              (g) => (g['name'] ?? '').toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
    return ListView(
      children:
          suggestions.map((guide) {
            return ListTile(
              title: Text(guide['name'] ?? 'Unknown'),
              onTap: () {
                query = guide['name'];
                showResults(context);
              },
            );
          }).toList(),
    );
  }
}
