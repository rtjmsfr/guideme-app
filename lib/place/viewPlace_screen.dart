import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'place_model.dart';

class ViewPlaceScreen extends StatefulWidget {
  final Place place;

  const ViewPlaceScreen({super.key, required this.place});

  @override
  State<ViewPlaceScreen> createState() => _ViewPlaceScreenState();
}

class _ViewPlaceScreenState extends State<ViewPlaceScreen> {
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  bool isGuest = false;
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _commentController = TextEditingController();
  bool showCommentField = false;
  double? selectedRating;
  @override
  void initState() {
    super.initState();
    isGuest = user == null || user!.isAnonymous;
    fetchLikeStatus();
    loadUserRating();
  }

  Future<void> loadUserRating() async {
    if (user == null) return;

    final ratingDoc =
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.place.id)
            .collection('ratings')
            .doc(user!.uid)
            .get();

    if (ratingDoc.exists) {
      setState(() {
        selectedRating = (ratingDoc.data()?['rating'] ?? 0).toDouble();
      });
    }
  }

  Future<void> updateInteraction({
    required String targetId, // مثلاً place.id أو guide.id
    required bool liked,
    bool commented = false,
    bool isPlace = true, // لو تبغين تفرقي بين مكان ومرشد
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final interactionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(isPlace ? 'places' : 'guides')
        .doc(targetId);

    final doc = await interactionRef.get();

    if (doc.exists) {
      await interactionRef.update({
        'like': liked ? 1 : 0,
        if (commented) 'comment': 1,
      });
    } else {
      await interactionRef.set({
        'uid': user.uid,
        'targetId': targetId,
        'type': isPlace ? 'place' : 'guide',
        'like': liked ? 1 : 0,
        'comment': commented ? 1 : 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> fetchLikeStatus() async {
    if (isGuest) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.place.id)
            .collection('likes')
            .doc(user!.uid)
            .get();

    final likeSnapshot =
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.place.id)
            .collection('likes')
            .get();

    final commentSnapshot =
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.place.id)
            .collection('comments')
            .get();

    setState(() {
      isLiked = doc.exists;
      likeCount = likeSnapshot.docs.length;
      commentCount = commentSnapshot.docs.length;
    });
  }

  Future<void> toggleLike() async {
    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول للتفاعل مع الأماكن')),
      );
      return;
    }

    final likeRef = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.place.id)
        .collection('likes')
        .doc(user!.uid);

    if (isLiked) {
      await likeRef.delete();
      setState(() {
        isLiked = false;
        likeCount--;
      });
      await updateInteraction(
        targetId: widget.place.id,
        liked: false,
        isPlace: true,
      );
      // ✅ سجل عدم الإعجاب
    } else {
      await likeRef.set({
        'uid': user!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        isLiked = true;
        likeCount++;
      });
      await updateInteraction(
        targetId: widget.place.id,
        liked: true,
        isPlace: true,
      );
      // ✅ سجل الإعجاب
    }
  }

  Future<void> submitComment() async {
    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لإضافة تعليق')),
      );
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.place.id)
        .collection('comments')
        .add({
          'uid': user!.uid,
          'username': user!.email ?? 'Unknown',
          'comment': commentText,
          'timestamp': DateTime.now(),
        });

    // ✅ تحديث مكان واحد للتفاعل
    await updateInteraction(
      targetId: widget.place.id,
      liked: isLiked,
      commented: true,
      isPlace: true,
    );

    _commentController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إضافة التعليق')));
  }

  Future<void> submitRating(int rating) async {
    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لتقييم الأماكن')),
      );
      return;
    }

    setState(() {
      selectedRating = rating.toDouble();
    });

    final ratingRef = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.place.id)
        .collection('ratings')
        .doc(user!.uid);

    await ratingRef.set({
      'uid': user!.uid,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final allRatings =
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.place.id)
            .collection('ratings')
            .get();

    double total = 0;
    for (var doc in allRatings.docs) {
      total += (doc.data()['rating'] ?? 0);
    }

    final double average = total / allRatings.docs.length;

    await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.place.id)
        .update({'rating': average});

    setState(() {
      widget.place.rating = average;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل تقييمك')), 
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Place'.tr(),
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xff196D1F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const BottomAppBar(color: Color(0xff196D1F)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.place.imageUrls[0],
                  width: width * 0.9,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.place.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final index = i + 1;
                  return IconButton(
                    onPressed: () => submitRating(index),
                    icon: Icon(
                      index <=
                              (selectedRating ??
                                  0) // ✅ نستخدم selectedRating فقط
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.orange,
                      size: 24,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: toggleLike,
                  ),
                  Text("$likeCount ${'likes'.tr()}"),
                  const SizedBox(width: 30),
                  Icon(Icons.comment_outlined, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text("$commentCount ${'comments'.tr()}"),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${'About'.tr()} ${widget.place.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(widget.place.description),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Comments".tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('places')
                        .doc(widget.place.id)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final comments = snapshot.data?.docs ?? [];

                  return Column(
                    children:
                        comments.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final username = data['username'] ?? 'Anonymous';
                          final comment = data['comment'] ?? '';
                          final timestamp = data['timestamp']?.toDate();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(comment),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      timestamp.toString().split('.')[0],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
              if (!isGuest) ...[
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...'.tr(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff196D1F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 55,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add'.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'سجل الدخول للتفاعل مع هذا المكان'.tr(),
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
