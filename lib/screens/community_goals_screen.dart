import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/models/workspace_models.dart';

class CommunityGoalsScreen extends StatelessWidget {
  final Community community;

  const CommunityGoalsScreen({
    super.key,
    required this.community,
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
                    'Shared Team Goals',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Collaborative objectives for the whole community',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('New Team Goal'),
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
          
          // Collaborative Progress Goal Cards
          _GoalProgressCard(
            title: 'Q1 Product Launch',
            progress: 0.75,
            contributors: 8,
            deadline: '15 Days left',
          ),
          const SizedBox(height: 24),
          _GoalProgressCard(
            title: 'Team Skill Upskilling - Python',
            progress: 0.40,
            contributors: 12,
            deadline: '45 Days left',
          ),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final int contributors;
  final String deadline;

  const _GoalProgressCard({
    required this.title,
    required this.progress,
    required this.contributors,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(deadline, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: AppColors.slate100,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.group, size: 16, color: AppColors.slate400),
              const SizedBox(width: 8),
              Text('$contributors contributors active', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('View Contribution Breakdown'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}