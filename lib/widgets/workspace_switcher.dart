import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/workspace_models.dart';
import '../services/workspace_service.dart';
import 'create_community_dialog.dart';

class WorkspaceSwitcher extends StatelessWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WorkspaceService(),
      builder: (context, _) {
        final service = WorkspaceService();
        final activeType = service.activeType;
        final activeCommunity = service.activeCommunity;
        final communities = service.communities;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.slate50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Personal Workspace Option
              _WorkspaceItem(
                title: 'Personal Workspace',
                icon: Icons.person,
                isSelected: activeType == WorkspaceType.personal,
                onTap: () => service.switchWorkspace(WorkspaceType.personal),
              ),
              if (communities.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('COMMUNITIES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 1)),
                    ],
                  ),
                ),
                ...communities.map((community) => _WorkspaceItem(
                  title: community.name,
                  icon: Icons.group,
                  isSelected: activeType == WorkspaceType.community && activeCommunity?.id == community.id,
                  onTap: () => service.switchWorkspace(WorkspaceType.community, community),
                )),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Divider(height: 1, color: AppColors.slate200),
              ),
              // Create Community Button
              TextButton.icon(
                onPressed: () => _showCreateCommunityModal(context),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Create Community', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        );

      },
    );
  }

  void _showCreateCommunityModal(BuildContext context) {
    showCreateCommunityDialog(context);
  }
}

class _WorkspaceItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkspaceItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigo50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.indigo600 : AppColors.slate500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.indigo600 : AppColors.slate600,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check, size: 16, color: AppColors.indigo600),
          ],
        ),
      ),
    );
  }
}
