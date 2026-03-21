import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/session_repository.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session; // The base session document
  final String userId;

  const SessionCard({
    super.key,
    required this.session,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final sessionId = session['sessionId'];

    return FutureBuilder<Map<String, dynamic>>(
      future: SessionRepository().getSessionSummary(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())));
        }

        final summary = snapshot.data!;
        final progress = (summary['progress'] as num).toDouble();
        final recentActivities = summary['recentActivities'] as List;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 8. UI Binding: Title & Description
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  session['title'] ?? 'Untitled Session',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmDelete(context, sessionId),
                                tooltip: 'Delete Session',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session['description'] ?? 'No description provided.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Streak: ${summary['streak']}d',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                // 8. UI Binding: Tasks & Progress
                Row(
                  children: [
                    _buildStatItem('Tasks', '${summary['completedTasks']}/${summary['totalTasks']}'),
                    const SizedBox(width: 24),
                    _buildStatItem('Time', '${summary['timeSpent']}m'),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Progress ${progress.toStringAsFixed(0)}%', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                
                // 8. UI Binding: Recent Activities
                ...recentActivities.map((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(_getActivityIcon(activity['actionType']), size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _getActivityLabel(activity['actionType']),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )).toList(),

                if (recentActivities.isEmpty)
                  const Text('No recent activities', style: TextStyle(fontSize: 12, color: Colors.grey)),

                const SizedBox(height: 16),
                const Text('Daily Effort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                
                // 8. UI Binding: Daily Effort
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: (summary['dailyEffort'] as List).map((val) => Container(
                      width: 30,
                      height: (val as num).toDouble() * 10 + 5,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'task_created': return Icons.add_circle_outline;
      case 'task_completed': return Icons.check_circle_outline;
      case 'session_started': return Icons.play_arrow_outlined;
      default: return Icons.info_outline;
    }
  }

  String _getActivityLabel(String type) {
    if (type.isEmpty) return 'Unknown';
    return type.replaceAll('_', ' ').substring(0, 1).toUpperCase() + type.replaceAll('_', ' ').substring(1);
  }

  Future<void> _confirmDelete(BuildContext context, String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('This will permanently remove this session and all its task data from the database. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SessionRepository().deleteSession(sessionId, userId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted successfully from DB.')),
        );
      }
    }
  }
}
