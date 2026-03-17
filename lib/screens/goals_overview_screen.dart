import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/responsive.dart';
import '../services/goal_service.dart';
import '../models/goal_models.dart';
import 'package:intl/intl.dart';


import '../widgets/create_goal_dialog.dart';

class GoalsOverviewScreen extends StatefulWidget {
  final Function(Goal) onGoalTap;

  const GoalsOverviewScreen({super.key, required this.onGoalTap});

  @override
  State<GoalsOverviewScreen> createState() => _GoalsOverviewScreenState();
}

class _GoalsOverviewScreenState extends State<GoalsOverviewScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GoalService(),
      builder: (context, _) {
        final allGoals = GoalService().goals;
        final filteredGoals = allGoals.where((g) => 
          g.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.description.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        return Column(
          children: [
            _GoalsHeader(
              searchController: _searchController,
              onNewGoal: () => showCreateGoalDialog(context),
              onSearchChanged: (val) => setState(() => _searchQuery = val),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryStrip(context, allGoals), // Stats are usually global
                      const SizedBox(height: 32),
                      _buildMainContent(context, filteredGoals),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryStrip(BuildContext context, List<Goal> goals) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    // 2A. Tasks in Progress: Count all tasks across all goals where: status = active OR pending (not completed)
    final tasksInProgressCount = goals.fold(0, (sum, g) => sum + g.tasks.where((t) => !t.isCompleted).length);

    // 2B. Total Completed: Count all completed tasks across all goals.
    final totalCompletedCount = goals.fold(0, (sum, g) => sum + g.tasks.where((t) => t.isCompleted).length);
    
    // 2C. Overall Progress: (sum of completed tasks across all goals) Ã· (sum of total tasks across all goals)
    final totalTasksCount = goals.fold(0, (sum, g) => sum + g.tasks.length);
    final overallProgress = totalTasksCount > 0 ? (totalCompletedCount / totalTasksCount) : 0.0;

    final cards = [
      _SummaryCard(label: 'Tasks in Progress', value: '$tasksInProgressCount', trend: '+2%', isPositive: true),
      _SummaryCard(label: 'Total Completed', value: '$totalCompletedCount', trend: 'Global', isPositive: true),
      _SummaryCard(label: 'Overall Efficiency', value: '${(overallProgress * 100).toInt()}%', trend: '+5%', isPositive: true),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: c,
        )).toList(),
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        SizedBox(width: isTablet ? 16 : 24),
        Expanded(child: cards[1]),
        SizedBox(width: isTablet ? 16 : 24),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, List<Goal> goals) {
    final bool isDesktop = Responsive.isDesktop(context);

    if (!isDesktop) {
      return Column(
        children: [
          _ActiveGoalsSection(goals: goals, onGoalTap: widget.onGoalTap),
          const SizedBox(height: 32),
          _MilestonesSidebar(goals: goals),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _ActiveGoalsSection(goals: goals, onGoalTap: widget.onGoalTap),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: _MilestonesSidebar(goals: goals),
        ),
      ],
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  final VoidCallback onNewGoal;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  
  const _GoalsHeader({
    required this.onNewGoal,
    this.onSearchChanged,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
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
          const Text(
            'Goals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          const SizedBox(width: 24),
          if (!isMobile)
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search goals...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.slate400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 10),
                    ),
                  ),
                ),
              ),
            ),
          if (isMobile) const Spacer(),
          ElevatedButton.icon(
            onPressed: onNewGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              isMobile ? 'New' : 'New Goal',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            const Icon(Icons.notifications_none, color: AppColors.slate500, size: 24),
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool isPositive;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositive ? const Color(0xFF059669) : const Color(0xFFE11D48),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.slate900)),
        ],
      ),
    );
  }
}

class _ActiveGoalsSection extends StatelessWidget {
  final List<Goal> goals;
  final Function(Goal) onGoalTap;

  const _ActiveGoalsSection({required this.goals, required this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: isMobile ? 1.0 : 1.1, // Adjusted for more vertical space
          ),
          itemCount: activeGoals.length + 1,
          itemBuilder: (context, index) {
            if (index == activeGoals.length) {
              return _AddNewObjectiveCard(
                onTap: () => showCreateGoalDialog(context),
              );
            }
            
            final goal = activeGoals[index];
            return _GoalCard(
              title: goal.title,
              subtitle: goal.description,
              progress: goal.progress,
              tasks: '${goal.completedTasksCount}/${goal.tasks.length} Tasks',
              dueDate: DateFormat('MMM dd').format(goal.dueDate),
              icon: goal.icon,
              onTap: () => onGoalTap(goal),
              imageUrl: goal.imageUrl ?? 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?q=80&w=400&auto=format&fit=crop',
            );
          },
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String tasks;
  final String dueDate;
  final IconData icon;
  final String imageUrl;
  final VoidCallback? onTap;

  const _GoalCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.tasks,
    required this.dueDate,
    required this.icon,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 100, // Reduced from 120
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16), // Reduced from 20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
                  const SizedBox(height: 12), // Reduced from 16
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate600)),
                      Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.slate100,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: AppColors.slate400),
                          const SizedBox(width: 6),
                          Text(tasks, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(dueDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate600)),
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
  }
}

class _AddNewObjectiveCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNewObjectiveCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New Objective',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Set a new dynamic goal',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestonesSidebar extends StatelessWidget {
  final List<Goal> goals;
  const _MilestonesSidebar({required this.goals});

  @override
  Widget build(BuildContext context) {
    // 5. Upcoming Milestones: Display milestones across all goals where milestone.date >= today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final milestoneTasks = <Map<String, dynamic>>[];
    for (var goal in goals) {
      for (var task in goal.tasks) {
        if (task.priority == TaskPriority.milestone && !task.isCompleted && (task.deadline.isAfter(todayStart) || task.deadline.isAtSameMomentAs(todayStart))) {
          milestoneTasks.add({
            'task': task,
            'goalTitle': goal.title,
          });
        }
      }
    }
    
    // Sort by nearest date ascending
    milestoneTasks.sort((a, b) => (a['task'] as GoalTask).deadline.compareTo((b['task'] as GoalTask).deadline));
    final displayMilestones = milestoneTasks.take(3).toList();

    // 6. Daily Focus Section: Dynamic tags based on recent active tasks or high priority
    final allActiveTasks = goals
        .expand((g) => g.tasks)
        .where((t) => !t.isCompleted)
        .toList();
    
    // Sort by priority (high first) then creation date
    allActiveTasks.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    final dynamicTags = <String>{};
    for (var task in allActiveTasks) {
      // Extract hashtags if any
      final hashMatches = RegExp(r'#\w+').allMatches(task.name);
      if (hashMatches.isNotEmpty) {
        for (var m in hashMatches) {
          dynamicTags.add(m.group(0)!);
        }
      } else {
        // Fallback: Create tag from first word
        final words = task.name.split(' ');
        if (words.isNotEmpty) {
          final tag = '#${words[0].replaceAll(RegExp(r'[^\w]'), '')}';
          if (tag.length > 2) dynamicTags.add(tag);
        }
      }
      if (dynamicTags.length >= 4) break;
    }

    // Default tags if none found
    if (dynamicTags.isEmpty) {
      dynamicTags.addAll(['#Focus', '#DeepWork', '#Productivity', '#Goals']);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Milestones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  Icon(Icons.calendar_today, size: 18, color: AppColors.slate400),
                ],
              ),
              const SizedBox(height: 24),
              if (displayMilestones.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No upcoming milestones.', style: TextStyle(color: AppColors.slate400, fontSize: 13))),
                )
              else
                ...displayMilestones.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final m = entry.value;
                  final task = m['task'] as GoalTask;
                  return _MilestoneStep(
                    title: task.name,
                    subtitle: '${m['goalTitle']} â€¢ ${DateFormat('MMM dd').format(task.deadline)}',
                    isActive: idx == 0,
                    isLast: idx == displayMilestones.length - 1,
                  );
                }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.slate200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Timeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily Focus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  Icon(Icons.lightbulb_outline, size: 18, color: AppColors.slate400),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dynamicTags.map((tag) => _Tag(label: tag, isActive: tag == dynamicTags.first)).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '"The secret of getting ahead is getting started."',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.slate500, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MilestoneStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isLast;

  const _MilestoneStep({
    required this.title,
    required this.subtitle,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.slate100,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isActive;

  const _Tag({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.1) : AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
        border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.primary : AppColors.slate500,
        ),
      ),
    );
  }
}
