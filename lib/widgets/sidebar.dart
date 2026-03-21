import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/widgets/workspace_switcher.dart';
import 'dart:convert';
import 'dart:io';
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
            ListenableBuilder(
              listenable: AuthService(),
              builder: (context, child) {
                final user = AuthService().currentUser;
                final email = user?['email'] ?? '';
                final name = user?['name'] ?? 'Google User';
                final bio = user?['bio'] ?? 'Product Designer based in San Francisco';
                final rotation = user?['rotation']?.toDouble() ?? 0.0;

                return GestureDetector(
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Transform.rotate(
                                angle: rotation * (3.14159 / 180),
                                child: Image(
                                  image: _getAvatarProvider(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slate900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    bio,
                                    style: const TextStyle(
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
                );
              },
            ),
            if (isDrawer)
              const SizedBox(height: 20), // Extra space for drawer bottom
          ],
        ),
      ),
    );
  }

  ImageProvider _getAvatarProvider() {
    final user = AuthService().currentUser;
    final email = user?['email'] ?? '';
    final imageUrl = user?['imageUrl'];
    final localImagePath = user?['localImagePath'];

    if (localImagePath != null) {
      final file = File(localImagePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    
    if (email.isEmpty) return const NetworkImage('https://www.gravatar.com/avatar/?d=mp');
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = md5.convert(bytes);
    return NetworkImage('https://www.gravatar.com/avatar/$digest?d=mp&s=200');
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
