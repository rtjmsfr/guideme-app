import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../place/place_model.dart';
import '../main.dart';
import 'viewPlace_screen.dart'; // تأكد أن المتغير `places` موجود هنا

class FavoritePlacesScreen extends StatefulWidget {
  const FavoritePlacesScreen({super.key});

  @override
  State<FavoritePlacesScreen> createState() => _FavoritePlacesScreenState();
}

class _FavoritePlacesScreenState extends State<FavoritePlacesScreen> {
  List<Place> favoritePlaces = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final liked = <Place>[];

    for (var place in places) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('places')
            .doc(place.id)
            .collection('likes')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          liked.add(place);
        }
      } catch (e) {
        debugPrint('Error checking like for place ${place.id}: $e');
      }
    }

    setState(() {
      favoritePlaces = liked;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Favorite Places'.tr(), style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff196D1F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoritePlaces.isEmpty
          ?  Center(child: Text('No favorite places yet'.tr()))
          : ListView.builder(
        itemCount: favoritePlaces.length,
        itemBuilder: (context, index) {
          final place = favoritePlaces[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  place.imageUrls.isNotEmpty ? place.imageUrls.first : 'https://via.placeholder.com/100',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(place.name),
              subtitle: Text(
                place.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;

                  await FirebaseFirestore.instance
                      .collection('places')
                      .doc(place.id)
                      .collection('likes')
                      .doc(currentUser!.uid)
                      .delete();

                  setState(() => favoritePlaces.removeAt(index));
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ViewPlaceScreen(place: place)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
