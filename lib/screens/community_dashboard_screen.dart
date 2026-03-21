import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/models/workspace_models.dart';
import 'package:progresso/services/workspace_service.dart';

class CommunityDashboardScreen extends StatelessWidget {
  final Community community;
  final bool isAdmin;

  const CommunityDashboardScreen({
    super.key,
    required this.community,
    this.isAdmin = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'Team Productivity Overview' : 'Your Contribution',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invite Members'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Stats Row
          Row(
            children: [
              _StatCard(
                title: 'Team Efficiency',
                value: '92%',
                trend: '+4.5%',
                isPositive: true,
              ),
              const SizedBox(width: 24),
              _StatCard(
                title: 'Active Sessions',
                value: community.communitySessions.length.toString(),
                trend: 'Stable',
                isPositive: true,
              ),
              const SizedBox(width: 24),
              _StatCard(
                title: 'Pending Tasks',
                value: _calculatePendingTasks().toString(),
                trend: '-12%',
                isPositive: true,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member Activity
              Expanded(
                flex: 2,
                child: _SectionCard(
                  title: 'Member Activity Summary',
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: community.members.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = community.members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(member.avatarUrl),
                        ),
                        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(member.role.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        trailing: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Session Progress
              Expanded(
                flex: 3,
                child: _SectionCard(
                  title: 'Session Progress Tracking',
                  child: Column(
                    children: community.communitySessions.map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(session.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${_getSessionProgress(session)}%', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _getSessionProgress(session) / 100,
                              backgroundColor: AppColors.slate100,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculatePendingTasks() {
    int count = 0;
    for (var session in community.communitySessions) {
      count += session.assignments.where((a) => a.status != AssignmentStatus.completed).length;
    }
    return count;
  }

  double _getSessionProgress(Session session) {
    if (session.assignments.isEmpty) return 0;
    final completed = session.assignments.where((a) => a.status == AssignmentStatus.completed).length;
    return (completed / session.assignments.length) * 100;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
