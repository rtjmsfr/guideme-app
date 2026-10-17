import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guideme/profile/edit_profile.dart';
import '../chat.dart';
import '../profile/setting.dart';

class ProfileGuideScreen extends StatelessWidget {
  const ProfileGuideScreen({super.key});
  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<Map<String, dynamic>>> fetchCommentsAboutMe() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
    if (!userDoc.exists) return [];

    final commentsSnapshot =
        await userDoc.reference.collection('comments').get();

    final commentsAboutMe =
        commentsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'text': data['text'] ?? '',
            'userId': data['userId'] ?? '',
            'timestamp': data['timestamp'],
          };
        }).toList();

    return commentsAboutMe;
  }

  Future<List<Map<String, dynamic>>> _getUserChats() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final userId = currentUser.uid;

    final chatSnapshot =
        await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: userId)
            .get();

    final guides = <Map<String, dynamic>>[];

    for (var doc in chatSnapshot.docs) {
      final participants = doc['participants'] as List<dynamic>;

      final otherUserId =
          participants.first == userId ? participants.last : participants.first;

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();
      if (userDoc.exists) {
        final guideData = userDoc.data()!;
        guideData['id'] = userDoc.id;
        guides.add(guideData);
      }
    }

    return guides;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff196D1F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MyProfile'.tr(), style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xff196D1F),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/homeGuide'),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/GuideBookingsScreen');
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_pin, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/ProfileGuideScreen');
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("No user data found".tr()));
          }

          final userData = snapshot.data!;
          final name = userData['name'] ?? 'Unknown';
          final email =
              userData['email'] ??
              FirebaseAuth.instance.currentUser!.email ??
              'No Email';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, color: Colors.black),
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
                Text(
                  name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(email, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchCommentsAboutMe(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const CircularProgressIndicator();
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return Text("no comments".tr());
                    return _buildCommentsBox(snapshot.data!);
                  },
                ),

                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getUserChats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text("No chats found".tr());
                    }

                    final chats = snapshot.data!;

                    return _buildChatBox(chats);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentsBox(List<Map<String, dynamic>> comments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Comments".tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white70,
          ),
          child:
              comments.isEmpty
                  ? Center(child: Text('No Comments found'.tr()))
                  : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        title: Text(comment['text']),
                        subtitle: Text(
                          'From : ${comment['userId']}',
                        ), // يمكنك لاحقًا تحويل userId إلى اسم
                        trailing: Text(
                          comment['timestamp'] != null
                              ? (comment['timestamp'] as Timestamp)
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0]
                              : '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
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
        Text("your chat".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 220,
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
                title: Text(guide['name'] ?? 'Unknown'),
                subtitle: Text('@${guide['username'] ?? ''}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
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
