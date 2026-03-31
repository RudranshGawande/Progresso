import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/services/workspace_service.dart';
import 'package:progresso/models/workspace_models.dart';
import 'package:progresso/widgets/create_community_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class SidebarWidget extends StatelessWidget {
  final String activeItem;
  final Function(String)? onItemTap;

  const SidebarWidget({
    super.key,
    this.activeItem = 'Dashboard',
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final user = AuthService().currentUser;
        final String name = user?['name'] ?? user?['profile']?['name'] ?? user?['auth']?['name'] ?? 'User';
        final String email = user?['email'] ?? user?['auth']?['email'] ?? '';
        final String? avatarBase64 = user?['avatarBase64'];
        final String? imageUrl = user?['imageUrl'];

        ImageProvider avatarImage;
        if (avatarBase64 != null && avatarBase64.isNotEmpty) {
          try {
            avatarImage = MemoryImage(base64Decode(avatarBase64));
          } catch (_) {
            avatarImage = const NetworkImage('https://i.pravatar.cc/150?img=11');
          }
        } else if (imageUrl != null && imageUrl.isNotEmpty) {
          avatarImage = NetworkImage(imageUrl);
        } else {
          avatarImage = const NetworkImage('https://i.pravatar.cc/150?img=11');
        }

        return Container(
          width: isDrawer ? null : 256,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: isDrawer
                ? null
                : Border(right: BorderSide(color: AppColors.slate200)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.bolt, color: AppColors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PROGRESSO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                // Workspace Switcher
                const _WorkspaceSwitcher(),
                // Navigation Items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _NavItem(
                          icon: Icons.grid_view,
                          label: 'Dashboard',
                          isActive: activeItem == 'Dashboard',
                          onTap: () => onItemTap?.call('Dashboard'),
                        ),
                        const SizedBox(height: 4),
                        _NavItem(
                          icon: Icons.assessment,
                          label: 'Analysis',
                          isActive: activeItem == 'Analysis',
                          onTap: () => onItemTap?.call('Analysis'),
                        ),
                        const SizedBox(height: 4),
                        _NavItem(
                          icon: Icons.flag,
                          label: 'Goals',
                          isActive: activeItem == 'Goals',
                          onTap: () => onItemTap?.call('Goals'),
                        ),
                      ],
                    ),
                  ),
                ),
                // User profile section — tappable to open Profile page
                GestureDetector(
                  onTap: () => onItemTap?.call('Profile'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.slate100)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: avatarImage,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate900,
                                ),
                              ),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.settings, size: 18, color: AppColors.slate400),
                      ],
                    ),
                  ),
                ),
                if (isDrawer) const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WorkspaceSwitcher extends StatelessWidget {
  const _WorkspaceSwitcher();

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceService>(
      builder: (context, workspace, _) {
        final activeType = workspace.activeType;
        final communities = workspace.communities;
        final activeCommunity = workspace.activeCommunity;

        String title = activeType == WorkspaceType.personal 
            ? 'Personal Space' 
            : activeCommunity?.name ?? 'Community';
        
        IconData icon = activeType == WorkspaceType.personal 
            ? Icons.person_rounded 
            : Icons.group_rounded;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKSPACE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.slate400,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: activeType == WorkspaceType.personal 
                            ? AppColors.indigo50 
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: activeType == WorkspaceType.personal 
                            ? AppColors.indigo600 
                            : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate800,
                      ),
                    ),
                    children: [
                      // Personal Option
                      _WorkspaceOption(
                        title: 'Personal Space',
                        subtitle: 'Individual goals & tracking',
                        icon: Icons.person_rounded,
                        isActive: activeType == WorkspaceType.personal,
                        onTap: () {
                          workspace.switchWorkspace(WorkspaceType.personal);
                        },
                      ),
                      // Community Options
                      ...communities.map((community) => _WorkspaceOption(
                        title: community.name,
                        subtitle: '${community.members.length} members',
                        icon: Icons.group_rounded,
                        isActive: activeType == WorkspaceType.community && activeCommunity?.id == community.id,
                        onTap: () {
                          workspace.switchWorkspace(WorkspaceType.community, community);
                        },
                        onDelete: () {
                          workspace.deleteCommunity(community.id);
                        },
                      )),
                      const Divider(height: 1, indent: 12, endIndent: 12),
                      // Create New Option
                      _WorkspaceOption(
                        title: 'Create Team',
                        subtitle: 'Invite others to collaborate',
                        icon: Icons.add_circle_outline,
                        color: AppColors.primary,
                        onTap: () {
                          showCreateCommunityDialog(context);
                        },
                      ),
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

class _WorkspaceOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Color? color;

  const _WorkspaceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isActive = false,
    required this.onTap,
    this.onDelete,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, size: 18, color: isActive ? AppColors.primary : (color ?? AppColors.slate400)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? AppColors.primary : AppColors.slate700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: AppColors.slate400),
      ),
      trailing: onDelete != null
          ? PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: AppColors.slate400),
              onSelected: (value) {
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Delete Workspace', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            )
          : isActive 
              ? Icon(Icons.check_circle, size: 14, color: AppColors.primary)
              : null,
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppColors.indigo50
                    : _hovered
                        ? AppColors.slate100
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 22,
                    color: widget.isActive ? AppColors.indigo600 : AppColors.slate500,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isActive ? AppColors.indigo600 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}