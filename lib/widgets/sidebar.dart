import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/widgets/workspace_switcher.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
    // If it's a drawer, we don't want the fixed width and right border
    final bool isDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    return Container(
      width: isDrawer ? null : 256,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: AppColors.slate200)),
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
                    child: const Icon(
                      Icons.bolt,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
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
            const WorkspaceSwitcher(),
            // Navigation
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
            // User profile
            GestureDetector(
              onTap: () {
                if (onItemTap != null) {
                  onItemTap!('Profile');
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.indigo50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.indigo100),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.indigo100,
                          backgroundImage: NetworkImage(_getAvatarUrl()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AuthService().currentUser?['name'] ??
                                    'Google User',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Product Designer',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isDrawer)
              const SizedBox(height: 20), // Extra space for drawer bottom
          ],
        ),
      ),
    );
  }

  String _getAvatarUrl() {
    final email = AuthService().currentUser?['email'] ?? '';
    if (email.isEmpty) return 'https://www.gravatar.com/avatar/?d=mp';
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = md5.convert(bytes);
    return 'https://www.gravatar.com/avatar/$digest?d=mp&s=200';
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
                    color: widget.isActive
                        ? AppColors.indigo600
                        : AppColors.slate500,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.isActive
                          ? AppColors.indigo600
                          : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isActive)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
