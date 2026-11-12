import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DailyChallenge extends StatelessWidget {
  const DailyChallenge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.doc('challenges/today').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load today’s challenge.'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenge = snapshot.data?.data();
        if (challenge == null) {
          return const Center(child: Text('No challenge is available today.'));
        }

        final title = challenge['title'];
        final prompt = challenge['prompt'];
        if (title is! String ||
            title.trim().isEmpty ||
            prompt is! String ||
            prompt.trim().isEmpty) {
          return const Center(child: Text('Today’s challenge is incomplete.'));
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(prompt),
            ],
          ),
        );
      },
    );
  }
}
