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
      final uid = user?.uid ?? 'anonymous';

      await FirebaseFirestore.instance.collection('moods').add({
        'uid': uid,
        'mood': moodText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _moodController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood saved successfully 🌱')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save mood: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _moodController,
              decoration: const InputDecoration(
                labelText: 'How are you feeling?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.mood),
              ),
            ),
            const SizedBox(height: 16),

            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveMood,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
              child: const Text('Save Mood'),
            ),

            const SizedBox(height: 30),
            const Text(
              'Your Recent Moods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            /// 🔥 THIS IS THE IMPORTANT FIX
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('moods')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No moods yet.'));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final mood = data['mood'] ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final date =
                          ts?.toDate() ?? DateTime.now();

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.mood),
                          title: Text(mood),
                          subtitle: Text(
                            '${date.day}/${date.month}/${date.year} '
                                '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
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