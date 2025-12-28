import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final TextEditingController _moodController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveMood() async {
    final moodText = _moodController.text.trim();
    if (moodText.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      await FirebaseFirestore.instance
          .collection('moods')
          .doc(user.uid)
          .collection('entries')
          .add({
        'mood': moodText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _moodController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood saved successfully 🌱'),
          backgroundColor: Color(0xFF4A90E2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save mood: $e'),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        backgroundColor: const Color(0xFF4A90E2), // calm blue
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFEFF6F9), // soft light blue background
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _moodController,
              decoration: InputDecoration(
                labelText: 'How are you feeling?',
                labelStyle: const TextStyle(color: Color(0xFF4A90E2)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.mood, color: Color(0xFF4A90E2)),
              ),
            ),
            const SizedBox(height: 16),

            _isSaving
                ? const CircularProgressIndicator(color: Color(0xFF4A90E2))
                : ElevatedButton(
              onPressed: _saveMood,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save Mood'),
            ),

            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Recent Moods',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F3E3A),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: user == null
                  ? const Center(child: Text('Not logged in'))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('moods')
                    .doc(user.uid)
                    .collection('entries')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A90E2),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No moods yet.'),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final mood = data['mood'] ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final date = ts?.toDate() ?? DateTime.now();

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(
                            Icons.mood,
                            color: Color(0xFF4A90E2),
                          ),
                          title: Text(
                            mood,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${date.day}/${date.month}/${date.year} '
                                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

