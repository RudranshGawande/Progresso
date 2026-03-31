import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/workspace_models.dart';
import '../services/workspace_service.dart';
import 'create_community_dialog.dart';

class WorkspaceSwitcher extends StatefulWidget {
  const WorkspaceSwitcher({super.key});

  @override
  State<WorkspaceSwitcher> createState() => _WorkspaceSwitcherState();
}

class _WorkspaceSwitcherState extends State<WorkspaceSwitcher> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WorkspaceService(),
      builder: (context, _) {
        final service = WorkspaceService();
        final activeType = service.activeType;
        final activeCommunity = service.activeCommunity;
        final communities = service.communities;

        final String activeTitle = activeType == WorkspaceType.personal 
            ? 'Personal Space' 
            : (activeCommunity?.name ?? 'Community');
        
        final IconData activeIcon = activeType == WorkspaceType.personal ? Icons.person : Icons.group;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Main Selector Card ---
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Active Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(activeIcon, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activeTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate900,
                              ),
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                        ],
                      ),
                      
                      // Expanded Options
                      if (_isExpanded) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.slate100),
                        ),
                        // Personal Option
                        _WorkspaceItem(
                          title: 'Personal Space',
                          subtitle: 'Individual goals & tracking',
                          icon: Icons.person,
                          isSelected: activeType == WorkspaceType.personal,
                          onTap: () {
                            service.switchWorkspace(WorkspaceType.personal);
                            setState(() => _isExpanded = false);
                          },
                        ),
                        // Community Options
                        ...communities.map((c) => _WorkspaceItem(
                          title: c.name,
                          subtitle: 'Team collaboration',
                          icon: Icons.group,
                          isSelected: activeType == WorkspaceType.community && activeCommunity?.id == c.id,
                          onTap: () {
                            service.switchWorkspace(WorkspaceType.community, c);
                            setState(() => _isExpanded = false);
                          },
                        )),
                        const SizedBox(height: 8),
                        // Create Team Action
                        _WorkspaceItem(
                          title: 'Create Team',
                          subtitle: 'Invite others to collaborate',
                          icon: Icons.add_circle_outline,
                          iconColor: AppColors.primary,
                          isAction: true,
                          onTap: () {
                            setState(() => _isExpanded = false);
                            showCreateCommunityDialog(context);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkspaceItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final bool isSelected;
  final bool isAction;
  final VoidCallback onTap;

  const _WorkspaceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.isSelected = false,
    this.isAction = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? AppColors.primary : AppColors.slate900;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                size: 20, 
                color: iconColor ?? (isSelected ? AppColors.primary : AppColors.slate400)
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? AppColors.primary.withOpacity(0.7) : AppColors.slate400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}