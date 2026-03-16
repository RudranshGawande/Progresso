import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/widgets/workspace_switcher.dart';



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
            // Workspace Switcher
            const WorkspaceSwitcher(),
            // Navigation
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    const SizedBox(height: 4),
                    _NavItem(
                      icon: Icons.layers,
                      label: 'Sessions',
                      isActive: activeItem == 'Sessions',
                      onTap: () => onItemTap?.call('Sessions'),
                    ),
                    const SizedBox(height: 4),
                    _NavItem(
                      icon: Icons.check_circle_outline,
                      label: 'Tasks',
                      isActive: activeItem == 'Tasks',
                      onTap: () => onItemTap?.call('Tasks'),
                    ),
                  ],
                ),
              ),
            ),
            // User profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.slate100)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=11',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alex Rivera',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                        Text(
                          'Premium Plan',
                          style: TextStyle(fontSize: 10, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.settings, size: 18, color: AppColors.slate400),
                ],
              ),
            ),
            if (isDrawer) const SizedBox(height: 20), // Extra space for drawer bottom
          ],
        ),
      ),
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
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
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
