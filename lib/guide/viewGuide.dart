import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../chat.dart';

class ViewGuideScreen extends StatefulWidget {
  final Map<String, dynamic> guide;

  const ViewGuideScreen({super.key, required this.guide});

  @override
  State<ViewGuideScreen> createState() => _ViewGuideScreenState();
}

class _ViewGuideScreenState extends State<ViewGuideScreen> {
  final TextEditingController _commentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  int _selectedRating = 0;
  bool isGuest = false;
  bool isLiked = false;

  Future<void> updateInteraction({
    required String targetId, // ID المكان أو المرشد
    required bool liked,
    bool commented = false,
    required bool isPlace, // true = مكان، false = مرشد
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

  Future<Map<String, dynamic>?> showDateTimeDialog(BuildContext context) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String getFormattedDateTime() {
              if (selectedDate == null && selectedTime == null)
                return 'Your Booking Date';
              String date =
                  selectedDate != null
                      ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
                      : '...';
              String time =
                  selectedTime != null
                      ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                      : '...';
              return "$date - $time";
            }

            return AlertDialog(
              title: Text("Select Date & Time".tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.date_range,
                      color: Color(0xff196D1F),
                    ),
                    label: Text(
                      "Date".tr(),
                      style: TextStyle(color: Color(0xff196D1F)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.access_time,
                      color: Color(0xff196D1F),
                    ),
                    label: Text(
                      "Time".tr(),
                      style: TextStyle(color: Color(0xff196D1F)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    getFormattedDateTime(),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // إلغاء
                  },
                  child: Text(
                    "Cancel".tr(),
                    style: TextStyle(color: Color(0xff196D1F)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (isGuest) return;
                    if (selectedDate != null && selectedTime != null) {
                      final dateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                      Navigator.pop(context, {'dateTime': dateTime});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('يرجى اختيار التاريخ والوقت'.tr()),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Confirm".tr(),
                    style: TextStyle(color: Color(0xff196D1F)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isGuest = user == null || user!.isAnonymous;
    fetchInitialRating();
  }

  Future<void> fetchInitialRating() async {
    final guideId = widget.guide['id'];
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(guideId)
            .collection('ratings')
            .doc(currentUser.uid)
            .get();

    if (doc.exists && doc.data()?['rating'] != null) {
      setState(() {
        _selectedRating = doc.data()!['rating'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Guide Details'.tr(),
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xff196D1F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomAppBar(color: const Color(0xff196D1F)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 50, // Guide's profile picture
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Guide's information (name, email, language)
                      Row(
                        children: [
                          Text(
                            'User Name'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.guide['username'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Text(
                            'Email'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.guide['email'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Text(
                            'Language'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.guide['language'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (widget.guide['bio'] !=
                              null && //Check if the bio exists.
                          widget.guide['bio'].toString().isNotEmpty) ...[
                        // If it’s not empty (even if it exists).
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bio'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                widget.guide['bio'],
                                style: const TextStyle(fontSize: 11),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Additional content like likes, comments, message button, etc.

            // Likes and Comments Count
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.guide['id'])
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null)
                  return const CircularProgressIndicator();

                final guideData = snapshot.data!.data()!;
                final likesCount = guideData['likesCount'] ?? 0;
                final likedBy = List<String>.from(guideData['likedBy'] ?? []);

                // لا تستخدم isLiked هنا لأنه يجب أن يكون من state
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      isLiked = user != null && likedBy.contains(user!.uid);
                    });
                  }
                });

                return Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        if (isGuest) return;

                        final guideRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.guide['id']);

                        bool newIsLiked = false;

                        await FirebaseFirestore.instance.runTransaction((
                          transaction,
                        ) async {
                          final guideSnapshot = await transaction.get(guideRef);
                          if (!guideSnapshot.exists) return;

                          final guideData =
                              guideSnapshot.data() as Map<String, dynamic>;
                          List<String> currentLikedBy = List<String>.from(
                            guideData['likedBy'] ?? [],
                          );
                          int currentLikesCount = guideData['likesCount'] ?? 0;

                          if (currentLikedBy.contains(user!.uid)) {
                            currentLikedBy.remove(user!.uid);
                            currentLikesCount = (currentLikesCount - 1).clamp(
                              0,
                              currentLikesCount,
                            );
                            newIsLiked = false;
                          } else {
                            currentLikedBy.add(user!.uid);
                            currentLikesCount++;
                            newIsLiked = true;
                          }

                          transaction.update(guideRef, {
                            'likedBy': currentLikedBy,
                            'likesCount': currentLikesCount,
                          });
                        });

                        setState(() {
                          isLiked = newIsLiked;
                        });

                        await updateInteraction(
                          targetId: widget.guide['id'],
                          liked: newIsLiked,
                          isPlace: false,
                        );
                      },
                    ),
                    Text('$likesCount ${'likes'.tr()}'),
                  ],
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.guide['id'])
                      .collection('comments')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const SizedBox();
                if (snapshot.hasError)
                  return Text("Error loading comments".tr());

                final commentCount = snapshot.data?.docs.length ?? 0;
                return Row(
                  children: [
                    const SizedBox(width: 15),
                    const Icon(Icons.comment_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('$commentCount ${'comments'.tr()}'),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // Send Message & Book
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isGuest) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatScreen(
                                receiverId: widget.guide['id'],
                                receiverName: widget.guide['name'] ?? 'Guide',
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: Text(
                      'Send Message'.tr(),
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
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
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (isGuest) return;
                      final result = await showDateTimeDialog(context);
                      if (result == null || result['dateTime'] == null) return;

                      final DateTime selectedDateTime = result['dateTime'];

                      final userDoc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .get();
                      final userName = userDoc.data()?['name'] ?? 'Unknown';

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.guide['id'])
                          .collection('bookings')
                          .add({
                            'userId': user!.uid,
                            'userName': userName,
                            'guideId': widget.guide['id'],
                            'guideName': widget.guide['name'],
                            'timestamp': FieldValue.serverTimestamp(),
                            'status': 'pending',
                            'scheduledDateTime': selectedDateTime,
                          });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم إرسال طلب الحجز'.tr())),
                      );
                    },

                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      'Book Now'.tr(),
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
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
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Latest reviews'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // Reviews Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () async {
                            if (isGuest) return;

                            final rating = index + 1;
                            setState(() => _selectedRating = rating);

                            final guideId = widget.guide['id'];

                            final ratingRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(guideId)
                                .collection('ratings')
                                .doc(user!.uid);

                            await ratingRef.set({
                              'rating': rating,
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                            final ratingsSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(guideId)
                                    .collection('ratings')
                                    .get();

                            final allRatings =
                                ratingsSnapshot.docs
                                    .map((doc) => doc.data()['rating'] ?? 0)
                                    .cast<int>()
                                    .toList();

                            final average =
                                allRatings.isNotEmpty
                                    ? allRatings.reduce((a, b) => a + b) /
                                        allRatings.length
                                    : 0;

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(guideId)
                                .update({'averageRating': average});
                          },
                          child: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            size: 24,
                            color: Colors.orange,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 5),

                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.guide['id'])
                              .collection('comments')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const CircularProgressIndicator();
                        final comments = snapshot.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment =
                                comments[index].data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(comment['text'] ?? ''),
                              subtitle: Text(
                                (comment['timestamp'] as Timestamp?)
                                        ?.toDate()
                                        .toString() ??
                                    '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),

            // Add comment field
            TextField(
              controller: _commentController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Enter your comment here....'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xff196D1F)),
                  onPressed: () async {
                    if (isGuest) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('يجب تسجيل الدخول لإضافة تعليق'.tr()),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final commentText = _commentController.text.trim();
                    if (commentText.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.guide['id'])
                          .collection('comments')
                          .add({
                            'userId': user!.uid,
                            'text': commentText,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      await updateInteraction(
                        targetId: widget.guide['id'],
                        liked: isLiked,
                        commented: true,
                        isPlace: false,
                      );

                      _commentController.clear();
                      FocusScope.of(
                        context,
                      ).unfocus(); // لإغلاق الكيبورد بعد الإرسال
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تمت إضافة التعليق'.tr())),
                      );
                    }
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
