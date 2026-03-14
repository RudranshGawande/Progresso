import 'package:flutter/material.dart';
import '../models/goal_models.dart';
import '../theme/app_colors.dart';

class SessionTypeSelectionDialog extends StatefulWidget {
  final Goal goal;
  final GoalTask task;
  final Function(FocusSessionType type, int? durationSeconds) onSelect;

  const SessionTypeSelectionDialog({
    super.key,
    required this.goal,
    required this.task,
    required this.onSelect,
  });

  @override
  State<SessionTypeSelectionDialog> createState() => _SessionTypeSelectionDialogState();
}

class _SessionTypeSelectionDialogState extends State<SessionTypeSelectionDialog> {
  FocusSessionType _selectedType = FocusSessionType.free;
  int _selectedMinutes = 25;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
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
                  const Text(
                    'CHOOSE SESSION TYPE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTypeCard(
                    type: FocusSessionType.free,
                    title: 'Free Session',
                    description: 'Timer runs without a target limit.',
                    icon: Icons.all_inclusive,
                  ),
                  const SizedBox(height: 16),
                  _buildTypeCard(
                    type: FocusSessionType.timed,
                    title: 'Time-Limited Session',
                    description: 'Set a target duration. Timer still counts up.',
                    icon: Icons.timer_outlined,
                  ),
                  if (_selectedType == FocusSessionType.timed) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'TARGET DURATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPresetButton(25),
                        const SizedBox(width: 8),
                        _buildPresetButton(45),
                        const SizedBox(width: 8),
                        _buildPresetButton(60),
                        const SizedBox(width: 8),
                        _buildPresetButton(90),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required FocusSessionType type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.slate500,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(int minutes) {
    final isSelected = _selectedMinutes == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMinutes = minutes),
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
              '${minutes}m',
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: ElevatedButton(
        onPressed: () {
          widget.onSelect(
            _selectedType,
            _selectedType == FocusSessionType.timed ? _selectedMinutes * 60 : null,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'Start Focus Session',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
