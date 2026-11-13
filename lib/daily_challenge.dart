import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import 'quest_coach.dart';

class DailyChallenge extends StatefulWidget {
  const DailyChallenge({super.key, required this.uid});

  final String uid;

  @override
  State<DailyChallenge> createState() => _DailyChallengeState();
}

class _DailyChallengeState extends State<DailyChallenge> {
  late final _challenge = FirebaseFirestore.instance
      .doc('challenges/today')
      .snapshots();

  late final _progress = FirebaseFirestore.instance
      .doc('users/${widget.uid}/progress/today')
      .snapshots();

  bool _submitting = false;
  bool _completionConfirmed = false;
  String? _error;

  Future<void> _completeChallenge() async {
    if (_submitting || _completionConfirmed) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await FirebaseFunctions.instance.httpsCallable('completeToday').call({
        'challengeId': 'today',
      });

      if (!mounted) return;
      setState(() => _completionConfirmed = true);
    } on FirebaseFunctionsException {
      if (!mounted) return;
      setState(() {
        _error = 'Could not confirm completion. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _challenge,
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
              const SizedBox(height: 24),
              const QuestCoach(),
              const SizedBox(height: 24),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _progress,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Could not load your quest progress.');
                  }

                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final progress = snapshot.data?.data();
                  if (progress != null && progress['completed'] == true) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Challenge complete!'),
                        Text('Points earned: ${progress['points']}'),
                        Text('Badge: ${progress['badgeId']}'),
                      ],
                    );
                  }

                  if (_completionConfirmed) {
                    return const Text('Challenge complete. Loading reward…');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilledButton(
                        onPressed: _submitting ? null : _completeChallenge,
                        child: Text(
                          _submitting ? 'Completing…' : 'Complete challenge',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
