import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../theme/app_colors.dart';
import '../models/goal_models.dart';
import '../models/workspace_models.dart';
import '../services/goal_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/workspace_service.dart';

class CreateGoalDialog extends StatefulWidget {
  final Goal? goalToEdit;
  const CreateGoalDialog({super.key, this.goalToEdit});

  @override
  State<CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _isTitleNotEmpty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goalToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.goalToEdit?.description ?? '');
    _isTitleNotEmpty = _titleController.text.trim().isNotEmpty;
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    setState(() {
      _isTitleNotEmpty = _titleController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('exam') || t.contains('study') || t.contains('learn')) return Icons.school;
    if (t.contains('work') || t.contains('project') || t.contains('business')) return Icons.business_center;
    if (t.contains('design') || t.contains('creative') || t.contains('art')) return Icons.psychology;
    if (t.contains('health') || t.contains('gym') || t.contains('workout')) return Icons.fitness_center;
    return Icons.flag;
  }

  String _getImageForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('exam') || t.contains('study') || t.contains('learn')) {
      return 'assets/images/study.png';
    }
    if (t.contains('design') || t.contains('skill') || t.contains('creative')) {
      return 'assets/images/design.png';
    }
    if (t.contains('work') || t.contains('project') || t.contains('code') || t.contains('dev')) {
      return 'assets/images/coding.png';
    }
    
    return 'assets/images/productivity.png';
  }

  Future<void> _submit() async {
    if (!_isTitleNotEmpty || _isLoading) return;

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();

    if (widget.goalToEdit != null) {
      // Editing existing goal
      final updatedGoal = widget.goalToEdit!.copyWith(
        title: title,
        description: description.isNotEmpty ? description : 'No description provided',
      );
      GoalService().updateGoal(updatedGoal);
      Navigator.pop(context, updatedGoal);
    } else {
      // Creating new goal
      // Check for duplicate names only when creating
      final bool exists = GoalService().goals.any((g) => g.title.toLowerCase() == title.toLowerCase());
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A session with this name already exists.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final activeType = WorkspaceService().activeType;
      final activeCommunityId = WorkspaceService().activeCommunity?.id;
      final tempWorkspaceId = activeType == WorkspaceType.personal ? 'personal' : activeCommunityId ?? 'personal';
      
      final user = AuthService().currentUser;
      final defaultPersonalWs = user?['defaultPersonalWorkspaceId'];
      final apiWorkspaceId = tempWorkspaceId == 'personal' ? (defaultPersonalWs?.toString() ?? '') : tempWorkspaceId;

      String goalId = DateTime.now().millisecondsSinceEpoch.toString();
      final bool isDemo = user?['email'] == 'demo@progressor.com' || user?['email'] == 'demo@gmail.com' || user?['userId'] == 'demo_user_id_123';

      if (apiWorkspaceId.isNotEmpty && !isDemo) {
        final dueDate = DateTime.now().add(const Duration(days: 30));
        final dbId = await ApiService().createGoal(
          workspaceId: apiWorkspaceId,
          name: title,
          description: description.isNotEmpty ? description : 'No description provided',
          dueDate: dueDate,
          iconCode: _getIconForTitle(title).codePoint.toString(),
          imageUrl: _getImageForTitle(title),
        );
        if (dbId != null) {
          goalId = dbId;
        }
      }

      final newGoal = Goal(
        id: goalId,
        workspaceId: tempWorkspaceId,
        title: title,
        description: description.isNotEmpty ? description : 'No description provided',
        dueDate: DateTime.now().add(const Duration(days: 30)), // Default 30 days
        status: GoalStatus.active,
        icon: _getIconForTitle(title),
        imageUrl: _getImageForTitle(title),
      );

      GoalService().addGoal(newGoal);
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, newGoal); // Return the new goal
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isEditing = widget.goalToEdit != null;
    
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset > 0 ? bottomInset : 32,
              top: 32,
              left: 16,
              right: 16,
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 512),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(color: AppColors.slate200),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Session' : 'Create New Session',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppColors.slate400),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.slate100),
                  
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Title',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          maxLength: 100,
                          autofocus: !isEditing,
                          decoration: InputDecoration(
                            hintText: 'e.g., Deep Work on Design System',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                            filled: true,
                            fillColor: AppColors.slate100.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.slate200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            counterText: '',
                          ),
                          style: TextStyle(fontSize: 14, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate700,
                              ),
                            ),
                            ListenableBuilder(
                              listenable: _descriptionController,
                              builder: (context, _) => Text(
                                '${_descriptionController.text.length}/300 characters',
                                style: TextStyle(fontSize: 10, color: AppColors.slate400),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLength: 300,
                          minLines: 3,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'What do you want to achieve in this session?',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                            filled: true,
                            fillColor: AppColors.slate100.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.slate200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            counterText: '',
                          ),
                          style: TextStyle(
                            fontSize: 14, 
                            color: AppColors.slate900,
                            height: 1.5, // Better line spacing for readability
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: AppColors.slate100.withOpacity(0.3),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: AppColors.slate200),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isTitleNotEmpty && !_isLoading ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.slate200,
                              disabledForegroundColor: AppColors.slate400,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                  )
                                : Text(
                                    isEditing ? 'Save Changes' : 'Create Session',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showCreateGoalDialog(BuildContext context) {
  _showGoalDialog(context);
}

void showEditGoalDialog(BuildContext context, Goal goal) {
  _showGoalDialog(context, goal: goal);
}

void _showGoalDialog(BuildContext context, {Goal? goal}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: goal == null ? 'Create Session' : 'Edit Session',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => CreateGoalDialog(goalToEdit: goal),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8 * anim1.value, sigmaY: 8 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(anim1),
            child: child,
          ),
        ),
      );
    },
  );
}