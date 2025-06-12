import 'package:flutter/material.dart';

class Message {
  final String content;
  final bool isMe;
  final String time;
  final bool isRead;

  Message({
    required this.content,
    required this.isMe,
    required this.time,
    this.isRead = false,
  });
}

class PengaturanChatView extends StatefulWidget {
  final String userName;
  const PengaturanChatView({Key? key, required this.userName}) : super(key: key);

  @override
  State<PengaturanChatView> createState() => _PengaturanChatViewState();
}

class _PengaturanChatViewState extends State<PengaturanChatView> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [
    Message(
      content: "Halo min, bagaimana cara melakukan setor sampah?",
      isMe: false,
      time: "Just now",
    ),
    Message(
      content: "Halo Khoerunisa! Lakukan scan sampah terlebih dahulu, kemudian pilih kategori sampah, lalu klik setor sampah di bagian bawah ya.",
      isMe: true,
      time: "2m ago",
      isRead: true,
    ),
    Message(
      content: "Apakah bisa setor langsung ke kantor?",
      isMe: false,
      time: "Just now",
    ),
    Message(
      content: "Bisa ya! silahkan langsung datang ke kantor kami.",
      isMe: true,
      time: "2m ago",
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageItem(message);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.isMe)
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
              Text(
                "• ${message.time}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMe ? const Color(0xFF8EE0DE) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          if (message.isMe && message.isRead)
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 5),
              child: Text(
                "Seen",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a reply...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.gif_box_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}