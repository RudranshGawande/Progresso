import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/models/workspace_models.dart';

class SessionsOverviewScreen extends StatelessWidget {
  final Community community;
  final Function(Session)? onSessionTap;

  const SessionsOverviewScreen({
    super.key,
    required this.community,
    this.onSessionTap,
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
                    'Community Sessions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage projects and team collaborations',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Session'),
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
            ),
            itemCount: community.communitySessions.length,
            itemBuilder: (context, index) {
              final session = community.communitySessions[index];
              return _SessionCard(
                session: session,
                onTap: () => onSessionTap?.call(session),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    int activeAssignments = session.assignments.where((a) => a.status != AssignmentStatus.completed).length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.isArchived ? AppColors.slate100 : AppColors.indigo50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    session.isArchived ? 'ARCHIVED' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: session.isArchived ? AppColors.slate500 : AppColors.indigo600,
                    ),
                  ),
                ),
                Icon(Icons.more_vert, size: 18, color: AppColors.slate400),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              session.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              session.description ?? 'No description provided.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: AppColors.slate500),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_outlined, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      '$activeAssignments assignments',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
                _AvatarStack(avatars: session.memberAvatars),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> avatars;

  const _AvatarStack({required this.avatars});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 24,
      child: Stack(
        children: List.generate(
          avatars.length > 3 ? 3 : avatars.length,
          (index) => Positioned(
            left: index * 16,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 10,
                backgroundImage: NetworkImage(avatars[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}