import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QuestCoach extends StatefulWidget {
  const QuestCoach({super.key});

  @override
  State<QuestCoach> createState() => _QuestCoachState();
}

class _QuestCoachState extends State<QuestCoach> {
  bool _loading = false;
  String? _hint;
  String? _error;

  Future<void> _askCoach({bool simulateFailure = false}) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _hint = null;
      _error = null;
    });

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('askQuestCoach')
          .call(<String, dynamic>{
            if (simulateFailure) 'simulateToolFailure': true,
          });

      final data = result.data;
      final hint = data is Map ? data['hint'] : null;

      if (!mounted) return;
      setState(() {
        if (hint is String && hint.trim().isNotEmpty) {
          _hint = hint.trim();
        } else {
          _error = 'The coach returned no hint. Please try again.';
        }
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code == 'unavailable'
            ? 'The coach could not read your quest. Please try again.'
            : 'Could not get a hint. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: _loading ? null : () => _askCoach(),
          child: Text(_loading ? 'Getting a hint…' : 'Ask Quest Coach'),
        ),
        if (kDebugMode)
          TextButton(
            onPressed: _loading ? null : () => _askCoach(simulateFailure: true),
            child: const Text('Simulate coach failure'),
          ),
        if (_hint != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_hint!)),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
