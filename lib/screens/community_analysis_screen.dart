import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/models/workspace_models.dart';

class CommunityAnalysisScreen extends StatelessWidget {
  final Community community;
  final bool isAdmin;

  const CommunityAnalysisScreen({
    super.key,
    required this.community,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Team Productivity Analysis' : 'My Community Contribution',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 32),
          
          if (isAdmin) ...[
            _AnalysisCard(
              title: 'Team Productivity Trends',
              height: 300,
              child: Center(
                child: Text('Contribution Heatmap / Trends Chart Placeholder', 
                  style: TextStyle(color: AppColors.slate400)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AnalysisCard(
                    title: 'Member Contribution Leaderboard',
                    height: 400,
                    child: ListView.builder(
                      itemCount: community.members.length,
                      itemBuilder: (context, index) {
                        final member = community.members[index];
                        return ListTile(
                          leading: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          title: Text(member.name),
                          trailing: Text('${(95 - index * 5)}%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _AnalysisCard(
                    title: 'Session Progress Metrics',
                    height: 400,
                    child: Center(child: Text('Bar Chart Placeholder', style: TextStyle(color: AppColors.slate400))),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Member View
            _AnalysisCard(
              title: 'Individual Performance within Team',
              height: 300,
              child: Center(
                child: Text('Personal Contribution Chart Placeholder', 
                  style: TextStyle(color: AppColors.slate400)),
              ),
            ),
            const SizedBox(height: 24),
            _AnalysisCard(
              title: 'Target vs Actual Contributions',
              height: 300,
              child: Center(
                child: Text('Radar Chart Placeholder', 
                  style: TextStyle(color: AppColors.slate400)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const _AnalysisCard({required this.title, required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900)),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}