import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/models/workspace_models.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;
  final bool isAdmin;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.isAdmin,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late List<Assignment> _assignments;
  final List<String> _activityLog = [
    'Sarah Chen joined the session',
    'James Wilson added "Clean Dataset"',
  ];

  @override
  void initState() {
    super.initState();
    _assignments = List.from(widget.session.assignments);
  }

  void _addAssignment() {
    setState(() {
      final newAsg = Assignment(
        id: DateTime.now().toString(),
        title: 'New Collaborative Task',
        status: AssignmentStatus.todo,
      );
      _assignments.insert(0, newAsg);
      _activityLog.insert(0, 'You added "${newAsg.title}"');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.session.title, style: const TextStyle(color: AppColors.slate900, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Real-time Collaborative Session', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
          ],
        ),
        actions: [
          _AvatarStack(avatars: widget.session.memberAvatars),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Task List
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tasks & Assignments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _addAssignment,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _assignments.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final asg = _assignments[index];
                        return ListTile(
                          leading: Checkbox(
                            value: asg.status == AssignmentStatus.completed,
                            onChanged: (val) {
                              setState(() {
                                _assignments[index] = Assignment(
                                  id: asg.id,
                                  title: asg.title,
                                  status: val! ? AssignmentStatus.completed : AssignmentStatus.todo,
                                  assigneeAvatar: asg.assigneeAvatar,
                                  assigneeName: asg.assigneeName,
                                );
                              });
                            },
                          ),
                          title: Text(asg.title, style: TextStyle(
                            decoration: asg.status == AssignmentStatus.completed ? TextDecoration.lineThrough : null,
                            color: asg.status == AssignmentStatus.completed ? AppColors.slate400 : AppColors.slate900,
                          )),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (asg.assigneeAvatar != null)
                                CircleAvatar(radius: 12, backgroundImage: NetworkImage(asg.assigneeAvatar!)),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.slate300),
                            ],
                          ),
                          onTap: () => _showAssignmentDetail(asg),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Activity Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.slate50,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _activityLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _activityLog[index],
                                  style: const TextStyle(fontSize: 13, color: AppColors.slate600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetail(Assignment asg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(asg.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 32),
              _DetailRow(label: 'Assignee', value: asg.assigneeName ?? 'Unassigned'),
              _DetailRow(label: 'Status', value: asg.status.name),
              _DetailRow(label: 'Due Date', value: 'Mar 25, 2026'),
              const Divider(height: 64),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Provide detailed specs for the upcoming frontend refactor. Focus on mobile responsiveness and accessibility.', 
                style: TextStyle(color: AppColors.slate600, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.slate500))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> avatars;
  const _AvatarStack({required this.avatars});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(avatars.length, (i) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(radius: 14, backgroundImage: NetworkImage(avatars[i])),
        )),
        const CircleAvatar(radius: 14, backgroundColor: AppColors.slate100, child: Icon(Icons.add, size: 14, color: AppColors.slate500)),
      ],
    );
  }
}
