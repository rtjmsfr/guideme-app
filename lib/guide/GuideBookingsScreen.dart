import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guideme/chat.dart';

class GuideBookingsScreen extends StatefulWidget {
  const GuideBookingsScreen({super.key});

  @override
  State<GuideBookingsScreen> createState() => _GuideBookingsScreenState();
}

class _GuideBookingsScreenState extends State<GuideBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('bookings')
            .orderBy('timestamp', descending: true)
            .get();

    setState(() {
      _bookings =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();
    });
  }

  Future<void> _updateBookingStatus(int index, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final booking = _bookings[index];
    final docId = booking['docId'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookings')
        .doc(docId)
        .update({'status': newStatus});

    setState(() {
      _bookings[index]['status'] = newStatus;
    });

    /*ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking marked as $newStatus'),
      ),
    );*/

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          "Your Bookings".tr(),
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xff196D1F),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة اللي قبلها
        ),        centerTitle: true,
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

      body:
          _bookings.isEmpty
              ?  Center(child: Text("No bookings found.".tr()))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  final status = booking['status'] ?? 'pending';
                  final timestamp = booking['timestamp'] as Timestamp?;
                  final date = timestamp?.toDate();
                  final scheduledAt = booking['scheduledDateTime'] != null
                      ? (booking['scheduledDateTime'] as Timestamp).toDate()
                      : null;

                  final isActionTaken =
                      status == 'accepted' || status == 'rejected';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('${"From".tr()}: ${booking['userName'] ?? 'Unknown'.tr()}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (scheduledAt != null)
                            Text(
                              '${"Scheduled".tr()}: ${scheduledAt.toLocal().toString().replaceFirst('.000', '')}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),

                          if (date != null)
                            Text(
                              '${"Date".tr()}: ${date.toLocal().toString().split(' ')[0]}',
                            ),
                          Text('${"Status".tr()}: $status'),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: isActionTaken ? null : () => _updateBookingStatus(index, 'accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Accept'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: isActionTaken ? null : () => _updateBookingStatus(index, 'rejected'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Reject'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                              const SizedBox(width: 20),
                              if (status == 'accepted') ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final userId = booking['userId'];
                                    final guideId = FirebaseAuth.instance.currentUser!.uid;

                                    final chatId = userId.hashCode <= guideId.hashCode
                                        ? '${userId}_$guideId'
                                        : '${guideId}_$userId';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          receiverId: userId,
                                          receiverName: booking['userName'] ?? 'Guide',
                                        ),
                                      ),
                                    );

                                  },
                                  icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                                  label: Text(
                                    'Message User'.tr(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff196D1F),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                            ],
                          ),

                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
