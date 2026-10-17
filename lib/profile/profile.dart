import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:guideme/place/place_model.dart';
import 'package:guideme/place/viewPlace_screen.dart';
import 'package:guideme/profile/edit_profile.dart';
import '../chat.dart';
import '../main.dart';
import '../place/fav_places.dart';
import 'setting.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  Future<List<Map<String, dynamic>>> fetchUserBookings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final guidesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('type', isEqualTo: 'guide')
        .get();

    List<Map<String, dynamic>> bookings = [];

    for (var guideDoc in guidesSnapshot.docs) {
      final guideId = guideDoc.id;
      final guideName = guideDoc.data()['name'] ?? 'Unknown'.tr();

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(guideId)
          .collection('bookings')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (var bookingDoc in bookingsSnapshot.docs) {
        final data = bookingDoc.data();
        bookings.add({
          'guideName': guideName,
          'status': data['status'] ?? 'pending',
          'dateTime': data['scheduledDateTime'],
        });
      }
    }

    return bookings;
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<Map<String, dynamic>>> fetchUserComments() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    List<Map<String, dynamic>> userComments = [];

    final placesCollection = await FirebaseFirestore.instance.collection('places').get();

    for (var placeDoc in placesCollection.docs) {
      final placeId = placeDoc.id;
      final placeData = placeDoc.data();
      final placeName = placeData['name'] ?? placeId;

      final commentsSnapshot = await placeDoc.reference.collection('comments').get();

      for (var commentDoc in commentsSnapshot.docs) {
        final data = commentDoc.data();
        if (data['uid'] == currentUser.uid) {
          userComments.add({
            'type': 'place',
            'name': placeName,
            'text': data['comment'],
            'timestamp': data['timestamp'],
          });
        }
      }
    }

    final allGuides = await FirebaseFirestore.instance
        .collection('users')
        .where('type', isEqualTo: 'guide')
        .get();

    for (var guideDoc in allGuides.docs) {
      final guideName = guideDoc.data()['name'] ?? 'Unknown'.tr();

      final commentsSnapshot = await guideDoc.reference.collection('comments').get();

      for (var commentDoc in commentsSnapshot.docs) {
        final data = commentDoc.data();
        if (data['userId'] == currentUser.uid) {
          userComments.add({
            'type': 'guide',
            'name': guideName,
            'text': data['text'],
            'timestamp': data['timestamp'],
          });
        }
      }
    }

    return userComments;
  }

  Future<List<Map<String, dynamic>>> _getUserChats() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final userId = currentUser.uid;

    final chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    final guides = <Map<String, dynamic>>[];

    for (var doc in chatSnapshot.docs) {
      final participants = doc['participants'] as List<dynamic>;
      final otherUserId = participants.first == userId ? participants.last : participants.first;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
      if (userDoc.exists) {
        final guideData = userDoc.data()!;
        guideData['id'] = userDoc.id;
        guides.add(guideData);
      }
    }

    return guides;
  }

  Future<List<Map<String, dynamic>>> fetchSearchData() async {
    final randomPlaces = List<Place>.from(places)..shuffle();

    final placesData = randomPlaces.map((place) {
      return {
        'type': 'place',
        'id': place.id,
        'name': place.name,
        'description': place.description,
      };
    }).toList();

    final guideSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('type', isEqualTo: 'guide')
        .get();

    final guidesData = guideSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'type': 'guide',
        'id': doc.id,
        'name': data['name'] ?? 'Unknown'.tr(),
        'username': data['username'] ?? '',
      };
    }).toList();

    return [...placesData, ...guidesData];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff196D1F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
        title: Text('Profile'.tr(), style: const TextStyle(color: Colors.white)),
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (FirebaseAuth.instance.currentUser == null||!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text('You are browsing as a guest.'.tr(), style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff196D1F)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text('Login to your account'.tr(),style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        //  if (!snapshot.hasData || snapshot.data == null) return Center(child: Text('No user data found'.tr()));

          final userData = snapshot.data!;
          final name = userData['name'] ?? 'Unknown'.tr();
          final email = userData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? 'No Email'.tr();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.black),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: () async {
                        final data = await fetchSearchData();
                        showSearch(context: context, delegate: ProfileSearchDelegate(data: data));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.black),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritePlacesScreen()));
                      },
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    final userData = await _getUserData(); // اجلب البيانات الحالية
                    if (userData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(userData: userData),
                        ),
                      );
                    }
                  },
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 10),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchUserComments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return Text("No comments yet.".tr());
                    return _buildCommentsBox(snapshot.data!);
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getUserChats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return Text("No chats found".tr());
                    return _buildChatBox(snapshot.data!);
                  },
                ),
                const SizedBox(height: 20),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchUserBookings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text("no more any booking ".tr());
                    }
                    return _buildBookingsBox(snapshot.data!);
                  },
                ),

              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildBookingsBox(List<Map<String, dynamic>> bookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Booking".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white70,
          ),
          child: ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(booking['guideName']),
                subtitle: Text('Statues: ${booking['status']}'),
                trailing: Text(
                  booking['dateTime'] != null
                      ? (booking['dateTime'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                      : '',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsBox(List<Map<String, dynamic>> comments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Comments".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white70,
          ),
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return ListTile(
                title: Text(comment['text']),
                subtitle: Text(comment['type'] == 'guide'
                    ? '${"Guide".tr()}: ${comment['name']}'
                    : '${"Place".tr()}: ${comment['name']}'),
                trailing: Text(
                  comment['timestamp'] != null
                      ? (comment['timestamp'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                      : '',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatBox(List<Map<String, dynamic>> chats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Chats".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white70,
          ),
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final guide = chats[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(guide['name'] ?? 'Unknown'.tr()),
                subtitle: Text('@${guide['username'] ?? ''}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        receiverId: guide['id'],
                        receiverName: guide['name'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProfileSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> data;

  ProfileSearchDelegate({required this.data});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return BackButton(onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    final lowerQuery = query.toLowerCase().trim();
    final filtered = data.where((item) {
      return item['name'].toString().toLowerCase().contains(lowerQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text('No results found'.tr()));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isPlace = item['type'] == 'place';

        return ListTile(
          leading: Icon(isPlace ? Icons.location_on : Icons.person),
          title: Text(item['name']),
          subtitle: Text(isPlace ? item['description'] : '@${item['username']}'),
          onTap: () {
            close(context, null);
            if (isPlace) {
              final place = places.firstWhere((p) => p.id == item['id']);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ViewPlaceScreen(place: place)));
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    receiverId: item['id'],
                    receiverName: item['name'],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
