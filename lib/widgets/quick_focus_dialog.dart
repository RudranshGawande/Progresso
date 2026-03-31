import 'package:flutter/material.dart';
import '../models/goal_models.dart';
import '../theme/app_colors.dart';
import '../screens/focus_session_screen.dart';

class QuickFocusDialog extends StatefulWidget {
  final Goal goal;
  final GoalTask task;

  const QuickFocusDialog({
    super.key,
    required this.goal,
    required this.task,
  });

  @override
  State<QuickFocusDialog> createState() => _QuickFocusDialogState();
}

class _QuickFocusDialogState extends State<QuickFocusDialog> {
  String _sessionType = 'Limited'; // 'Limited' or 'Open'
  String _durationPreset = '25m';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SESSION TYPE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSessionTypeSelector(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSessionTypeCard(
                type: 'Limited',
                title: 'Time Limited',
                subtitle: 'Countdown timer start',
                description: 'Focused sprint with a preset goal. Ideal for deep work & Pomodoro.',
                icon: Icons.timer_outlined,
                isSelected: _sessionType == 'Limited',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSessionTypeCard(
                type: 'Open',
                title: 'Open Session',
                subtitle: 'Count up from zero',
                description: 'Enter a flow state without a hard deadline. Track your focus.',
                icon: Icons.all_inclusive,
                isSelected: _sessionType == 'Open',
              ),
            ),
          ],
        ),
        if (_sessionType == 'Limited') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPresetButton('25m'),
              const SizedBox(width: 8),
              _buildPresetButton('45m'),
              const SizedBox(width: 8),
              _buildPresetButton('60m'),
              const SizedBox(width: 8),
              _buildPresetButton('Custom'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSessionTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _sessionType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.slate200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.slate400,
                  ),
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
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.slate600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label) {
    final isSelected = _durationPreset == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _durationPreset = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.slate200,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.slate700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        border: Border(top: BorderSide(color: AppColors.slate100)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: ElevatedButton(
        onPressed: () {
          int initialSeconds = 0;
          if (_sessionType == 'Limited') {
            switch (_durationPreset) {
              case '25m':
                initialSeconds = 25 * 60;
                break;
              case '45m':
                initialSeconds = 45 * 60;
                break;
              case '60m':
                initialSeconds = 60 * 60;
                break;
              case 'Custom':
                initialSeconds = 15 * 60; // Default custom to 15m for demo
                break;
            }
          }

          Navigator.pop(context);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FocusSessionScreen(
                goal: widget.goal,
                task: widget.task,
                targetSeconds: initialSeconds > 0 ? initialSeconds : null,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 20),
            SizedBox(width: 8),
            Text(
              'Start Focus Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}