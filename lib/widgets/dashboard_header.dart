import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/widgets/responsive.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/widgets/focus_session_dialog.dart';
import '../services/workspace_service.dart';
import '../models/workspace_models.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF2F6F6F8),
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
              color: AppColors.slate900,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ListenableBuilder(
              listenable: WorkspaceService(),
              builder: (context, _) {
                final service = WorkspaceService();
                final title = service.activeType == WorkspaceType.personal 
                    ? 'Performance Insights' 
                    : '${service.activeCommunity?.name ?? "Community"} Dashboard';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.activeType == WorkspaceType.personal
                            ? 'Daily productivity overview and 24h metrics analysis.'
                            : 'Team productivity metrics and collaborative goal progress.',
                        style: const TextStyle(fontSize: 14, color: AppColors.slate500),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (!isMobile) ...[
            // Search field
            Container(
              width: 256,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.slate200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, color: AppColors.slate400, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search sessions...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Start New Session Button
          ElevatedButton.icon(
            onPressed: () {
              final goals = GoalService().goals;
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Focus Session',
                barrierColor: Colors.black.withOpacity(0.6),
                pageBuilder: (context, _, __) => FocusSessionDialog(
                  goals: goals,
                ),
                transitionBuilder: (context, anim1, anim2, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: FadeTransition(
                      opacity: anim1,
                      child: child,
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            icon: Icon(Icons.play_circle, size: isMobile ? 18 : 22),
            label: Text(
              isMobile ? 'Start' : 'Start New Session',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
