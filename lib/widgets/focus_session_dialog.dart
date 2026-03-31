import 'package:flutter/material.dart';
import '../models/goal_models.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../screens/focus_session_screen.dart';

class FocusSessionDialog extends StatefulWidget {
  final List<Goal> goals;
  final Goal? initialGoal;
  final GoalTask? initialTask;

  const FocusSessionDialog({
    super.key,
    required this.goals,
    this.initialGoal,
    this.initialTask,
  });

  @override
  State<FocusSessionDialog> createState() => _FocusSessionDialogState();
}

class _FocusSessionDialogState extends State<FocusSessionDialog> {
  late Goal? _selectedGoal;
  GoalTask? _selectedTask;
  String _sessionType = 'Limited'; // 'Limited' or 'Open'
  String _durationPreset = '25m';

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal ?? (widget.goals.isNotEmpty ? widget.goals.first : null);
    if (widget.initialTask != null) {
      _selectedTask = widget.initialTask;
    } else if (_selectedGoal != null && _selectedGoal!.tasks.isNotEmpty) {
      // Pick first non-completed task if available, else first task
      _selectedTask = _selectedGoal!.tasks.firstWhere(
        (t) => !t.isCompleted,
        orElse: () => _selectedGoal!.tasks.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('SELECT GOAL'),
                    const SizedBox(height: 12),
                    _buildGoalSelector(),
                    const SizedBox(height: 32),
                    _buildSectionLabel('SELECT TASK TO FOCUS ON', actionLabel: 'View all tasks'),
                    const SizedBox(height: 12),
                    _buildTaskList(),
                    const SizedBox(height: 32),
                    _buildSectionLabel('SESSION TYPE'),
                    const SizedBox(height: 12),
                    _buildSessionTypeSelector(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Focus Session',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure your productivity sprint',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.slate400),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, {String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.slate700,
            letterSpacing: 0.5,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGoalSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: DropdownButtonFormField<Goal>(
        value: _selectedGoal,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: AppColors.slate400, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Search active goals (e.g. Exam Prep)',
          hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14),
        ),
        icon: Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.unfold_more, color: AppColors.slate400, size: 20),
        ),
        isExpanded: true,
        items: widget.goals.map((goal) {
          return DropdownMenuItem<Goal>(
            value: goal,
            child: Text(
              goal.title,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.slate900,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (goal) {
          if (goal != null) {
            setState(() {
              _selectedGoal = goal;
              if (goal.tasks.isNotEmpty) {
                _selectedTask = goal.tasks.firstWhere(
                  (t) => !t.isCompleted,
                  orElse: () => goal.tasks.first,
                );
              } else {
                _selectedTask = null;
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildTaskList() {
    if (_selectedGoal == null || _selectedGoal!.tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Center(
          child: Text(
            'No tasks found for this goal',
            style: TextStyle(color: AppColors.slate400, fontSize: 14),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _selectedGoal!.tasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = _selectedGoal!.tasks[index];
          final isSelected = _selectedTask?.id == task.id;

          return InkWell(
            onTap: () => setState(() => _selectedTask = task),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.slate200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.slate300,
                        width: 2,
                      ),
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.slate900 : AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildPriorityBadge(task.priority),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today, size: 12, color: AppColors.slate400),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd').format(task.deadline),
                              style: TextStyle(fontSize: 12, color: AppColors.slate400),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color bg;
    Color fg;
    String label;

    switch (priority) {
      case TaskPriority.high:
        bg = AppColors.primary.withOpacity(0.1);
        fg = AppColors.primary;
        label = 'High Priority';
        break;
      case TaskPriority.medium:
        bg = AppColors.slate100;
        fg = AppColors.slate500;
        label = 'Medium';
        break;
      case TaskPriority.low:
        bg = AppColors.slate100;
        fg = AppColors.slate500;
        label = 'Low';
        break;
      case TaskPriority.milestone:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade700;
        label = 'Milestone';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_selectedGoal == null || _selectedTask == null) return;

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
                goal: _selectedGoal!,
                task: _selectedTask!,
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