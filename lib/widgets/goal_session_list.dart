import 'package:flutter/material.dart';
import 'package:progresso/services/session_repository.dart';

import 'package:progresso/models/goal_models.dart';

class GoalSessionList extends StatefulWidget {
  final String goalId;
  final String userId;

  const GoalSessionList({super.key, required this.goalId, required this.userId});

  @override
  State<GoalSessionList> createState() => _GoalSessionListState();
}

class _GoalSessionListState extends State<GoalSessionList> {
  // 7. UI Bound to Dynamic Fetching State
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSessions();
  }

  void _refreshSessions() {
    setState(() {
      _sessionsFuture = SessionRepository().fetchSessionsForGoal(widget.goalId, widget.userId);
    });
  }

  Future<void> _createNewSession() async {
    final success = await SessionRepository().createSession(
      goalId: widget.goalId,
      userId: widget.userId,
      session: FocusSession(
        id: 'sess-\${DateTime.now().millisecondsSinceEpoch}',
        duration: const Duration(minutes: 25),
        intensity: 0.8,
        focusScore: 90,
        trendData: [0, 1, 2],
        timestamp: DateTime.now(),
      ),
    );

    if (success) {
      // Re-fetch data rather than relying on cached UI lists
      _refreshSessions(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _createNewSession,
          child: const Text('Start New Session'),
        ),
        const SizedBox(height: 16),
        Expanded(
          // Utilizing FutureBuilder to strictly enforce dynamic fetching
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: \${snapshot.error}'));
              }

              final sessions = snapshot.data ?? [];

              if (sessions.isEmpty) {
                return const Center(child: Text('No sessions logged yet.'));
              }

              return ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return ListTile(
                    leading: const Icon(Icons.timer),
                    title: Text(session['title'] ?? 'Untitled Session'),
                    subtitle: Text(session['description'] ?? ''),
                    trailing: Text('\${session['totalTimeSpent']} mins'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
