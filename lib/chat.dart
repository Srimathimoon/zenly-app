import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool isLoading = false;

  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text;

    setState(() {
      messages.add({'text': userText, 'isUser': true});
      _controller.clear();
      isLoading = true;
    });

    // TEMP BOT (replace later with API)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      messages.add({
        'text': "ZenlyBot: I'm here to listen 🌿",
        'isUser': false
      });
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ZenlyBot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg['isUser']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg['isUser']
                          ? Colors.green
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color:
                        msg['isUser'] ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Type your message...",
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: isLoading ? null : sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

