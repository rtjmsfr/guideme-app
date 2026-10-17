
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import 'place_model.dart';
import 'viewPlace_screen.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  List<Place> displayedPlaces = [];
  bool showFavoritesOnly = false;
  String? selectedType;
  final List<String> placeTypes = [
    'All',
    'Islands',
    'Hotel',
    'Castles',
    'Mountains',
    'Architectural Buildings',
    'Shopping Malls',
    'Parks',
    'Farms'
  ];
  bool isLoadingFavorites = false;

  bool isGuest = false;

  @override
  void initState() {
    super.initState();

    final randomPlaces = List<Place>.from(places)..shuffle();
    displayedPlaces = randomPlaces;

    final user = FirebaseAuth.instance.currentUser;
    isGuest = user == null || user.isAnonymous;
  }

  void _filterByRatingAndType() {
    setState(() {
      List<Place> filtered = List.from(places);

      if (selectedType != null && selectedType != 'All') {
        filtered =
            filtered.where((place) => place.type == selectedType).toList();
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      } else {
        filtered.shuffle();
      }

      displayedPlaces = filtered;
    });
  }

  void _toggleFavorites() async {
    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب تسجيل الدخول لاستخدام المفضلة'.tr())),
      );
      return;
    }

    setState(() {
      showFavoritesOnly = !showFavoritesOnly;
      isLoadingFavorites = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likedPlaces = <Place>[];

    for (var place in places) {
      final likeDoc = await FirebaseFirestore.instance
          .collection('places')
          .doc(place.id)
          .collection('likes')
          .doc(user.uid)
          .get();

      if (likeDoc.exists) {
        likedPlaces.add(place);
      }
    }

    setState(() {
      displayedPlaces = likedPlaces;
      isLoadingFavorites = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Places'.tr(), style: const TextStyle(fontSize: 20, color: Colors.white)),
        backgroundColor: const Color(0xff196D1F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
        centerTitle: true,
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

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: selectedType ?? 'All',
                    items: placeTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type.tr()));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        _filterByRatingAndType();
                      });
                    },
                  ),
                  IconButton(
                    onPressed: _filterByRatingAndType,
                    icon: const Icon(Icons.filter_alt_outlined),
                    style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () async {
                      final result = await showSearch<List<Place>?>(
                        context: context,
                        delegate: PlaceSearchDelegate(allPlaces: places),
                      );
                      if (result != null) {
                        setState(() {
                          displayedPlaces = result;
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                      color: showFavoritesOnly ? Colors.red : Colors.black,
                    ),
                    onPressed: _toggleFavorites,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoadingFavorites
                  ? const Center(child: CircularProgressIndicator())
                  : displayedPlaces.isEmpty
                  ? Center(
                child: Text('لم يتم العثور على نتائج'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
              )
                  : ListView.builder(
                itemCount: displayedPlaces.length,
                itemBuilder: (context, index) {
                  final place = displayedPlaces[index];
                  final imageUrl = place.imageUrls.isNotEmpty
                      ? place.imageUrls.first
                      : 'https://via.placeholder.com/100x120';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < place.rating.floor() ? Icons.star : Icons.star_border,
                                      color: Colors.orange,
                                      size: 18,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  place.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  place.description,
                                  maxLines: isWide ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ViewPlaceScreen(place: place),
                                        ),
                                      );
                                    },
                                    child: Text('Show more'.tr(), style: const TextStyle(fontSize: 14)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceSearchDelegate extends SearchDelegate<List<Place>?> {
  final List<Place> allPlaces;

  PlaceSearchDelegate({required this.allPlaces});

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) => BackButton(onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    final cleanedQuery = query.trim().toLowerCase();
    final results = allPlaces.where((place) {
      final nameMatch = place.name.toLowerCase().contains(cleanedQuery);
      final descriptionMatch = place.description.toLowerCase().contains(cleanedQuery);
      return nameMatch || descriptionMatch;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text('لم يتم العثور على نتائج'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return ListView(
      children: results.map((place) {
        return ListTile(
          title: Text(place.name),
          subtitle: Text(place.description, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => close(context, [place]),
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final cleanedQuery = query.trim().toLowerCase();
    final results = allPlaces.where((place) => place.name.toLowerCase().contains(cleanedQuery)).toList();

    if (results.isEmpty) {
      return Center(
        child: Text('لم يتم العثور على نتائج'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return ListView(
      children: results.map((place) {
        return ListTile(
          title: Text(place.name),
          onTap: () {
            query = place.name;
            showResults(context);
          },
        );
      }).toList(),
    );
  }
}
