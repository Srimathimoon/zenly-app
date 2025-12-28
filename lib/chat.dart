import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String openRouterApiKey = "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";

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AdvancedChatScreen(),
  ));
}

class AdvancedChatScreen extends StatefulWidget {
  const AdvancedChatScreen({super.key});

  @override
  State<AdvancedChatScreen> createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends State<AdvancedChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  String _mode = 'idle';
  String _mood = 'neutral';
  bool _isTyping = false;

  late AnimationController _breathingController;

  List<String> _suggestions = ["I'm stressed", "I feel lonely", "I'm okay"];

  @override
  void initState() {
    super.initState();

    _addBotMessage(
      "Hi 🌿 I’m Zenly. I’m here with you. How are you feeling today?",
      system: true,
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _breathingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  // ================= THEME =================

  Color _getThemeColor() {
    switch (_mood) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blueGrey;
      case 'stressed':
        return Colors.blueAccent;
      case 'crisis':
        return Colors.redAccent;
      default:
        return Colors.teal;
    }
  }

  // ================= AI =================

  Future<String> _callOpenRouter(String text) async {
    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $openRouterApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
              "You are Zenly, a calm, empathetic mental health companion. Keep replies short, gentle and human."
            },
            {"role": "user", "content": text}
          ],
          "max_tokens": 120,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"];
      }
      return "I'm here with you 🌿.";
    } catch (_) {
      return "I'm still here 💙. Talk to me.";
    }
  }

  // ================= CORE =================

  void _addBotMessage(String text, {bool system = false}) {
    _messages.add({
      "sender": "bot",
      "text": text,
      "system": system,
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final lower = text.toLowerCase();

    if (lower == "done" || lower == "stop breathing") {
      _stopBreathing();
      return;
    }

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    // 🚨 CRISIS (RULE-BASED LEFT)
    if (lower.contains("die") ||
        lower.contains("kill") ||
        lower.contains("suicide")) {
      setState(() {
        _mode = 'crisis';
        _mood = 'crisis';
        _isTyping = false;
        _breathingController.stop();
        _suggestions = ["I'm scared", "Help me"];
        _addBotMessage(
          "I'm really glad you told me 💔.\nYou matter.\n\n📞 Suicide Helpline India: 9152987821\nPlease reach out now.",
          system: true,
        );
      });
      _scrollToBottom();
      return;
    }

    // 😟 STRESS → BREATHING (RULE-BASED LEFT)
    if (lower.contains("stress") || lower.contains("anxious")) {
      setState(() {
        _mode = 'breathing';
        _mood = 'stressed';
        _isTyping = false;
        _suggestions = ["Done", "Stop breathing"];
        _breathingController.forward();
        _addBotMessage(
          "I hear you 🌿. Let’s slow down together.\nFollow the breathing circle.",
          system: true,
        );
      });
      _scrollToBottom();
      return;
    }

    // MOOD
    if (lower.contains("happy")) _mood = 'happy';
    if (lower.contains("sad") || lower.contains("lonely")) _mood = 'sad';

    final reply = await _callOpenRouter(text);

    setState(() {
      _isTyping = false;
      _addBotMessage(reply);
    });

    _scrollToBottom();
  }

  void _stopBreathing() {
    setState(() {
      _mode = 'idle';
      _breathingController.stop();
      _breathingController.reset();
      _suggestions = ["I'm stressed", "I feel lonely", "I'm okay"];
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeColor();

    return Scaffold(
      backgroundColor: theme.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: theme,
        title: const Text("Zenly AI"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    return _bubble(
                      msg["text"],
                      msg["sender"] == "user",
                      theme,
                      system: msg["system"] == true,
                    );
                  },
                ),
              ),

              if (!_isTyping)
                Wrap(
                  spacing: 8,
                  children: _suggestions
                      .map((s) => ActionChip(
                    label: Text(s),
                    onPressed: () => _sendMessage(s),
                    backgroundColor: theme.withOpacity(0.15),
                  ))
                      .toList(),
                ),

              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: _sendMessage,
                        decoration: const InputDecoration(
                            hintText: "Talk to Zenly..."),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: theme),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_mode == 'breathing') Center(child: _breathingWidget(theme)),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool user, Color theme,
      {bool system = false}) {
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: user
              ? theme
              : system
              ? theme.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: user ? Colors.white : Colors.black87,
            fontStyle: system ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  // 🌈 BREATHING
  Widget _breathingWidget(Color theme) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (_, __) {
        final inhale =
            _breathingController.status == AnimationStatus.forward;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.8 + (_breathingController.value * 0.7),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.withOpacity(0.9),
                      theme.withOpacity(0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 8,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              inhale ? "Breathe in..." : "Breathe out...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme,
              ),
            ),
          ],
        );
      },
    );
  }
}