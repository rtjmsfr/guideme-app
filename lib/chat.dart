import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String currentUserId;
  late String chatId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    chatId = _generateChatId(currentUserId, widget.receiverId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff196D1F),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message['text']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xff196D1F)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ حساب chatId مشترك لكل من المرسل والمستقبل (نفس النتيجة للطرفين)
  String _generateChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '$user1\_$user2' : '$user2\_$user1';
  }

  /// ✅ إرسال الرسالة وتخزينها في Firestore
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatId = _generateChatId(currentUserId, widget.receiverId);
    final messageData = {
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // ✨ حفظ الرسالة
    chatDoc.collection('messages').add(messageData);

    // ✨ تحديث بيانات الشات الرئيسي (لازم تكون فيه بيانات)
    chatDoc.set({
      'lastUpdated': FieldValue.serverTimestamp(),
      'participants': [currentUserId, widget.receiverId],
    }, SetOptions(merge: true)); // 🔁 دمج لو موجود
    _messageController.clear();
  }

}
