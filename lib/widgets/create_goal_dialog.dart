import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../theme/app_colors.dart';
import '../models/goal_models.dart';
import '../services/goal_service.dart';

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
    if (t.contains('exam') || t.contains('study')) {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuD9QJ_LVBXza2ziIOuTjHIhBsAb0-GKCtjEvzPsPCTdttR7xoxn5p2PxUXPG5Hcwkd3pSU6-l95dIwsV-nFWQ_Zn21LOu0jiFdCnUIZN4xvAI1jg4KTCOFB8wqCcBomckeuE-tRCPnH6f7rYRU_58NUkKXCgpLrujuyLqBGDt82O3aAZ4tzK-zOA2sJa7fjC-TAGD61Muj4h_gRt7H1sUrBkc_O4_y-rqOZcpZVZt5W998QnletUnN8jXPHM6LrkcVrOlw3FvJYnuwa';
    }
    if (t.contains('design') || t.contains('skill')) {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBarbCp4lSeTjvuTeJKaPDSyR1nHueV9Kf5VCLz2G2QVTSiXw4FgDFOcyqDO2H9efLiYTUy8dhPfV1bbP3NkPXHqqmLqOK6SB29KFn5t1T44JVdHPnw-Xa2UTSOFROCZqO9rk79YV0PtUmzQHGp8iPyJVXUy9wZImN6dI_siZr5RzIVmPlZoM7OoBPYeQkgriOu6UTd88IGDfAxpUNEx6Ly3_m0oinvHFB3fMLDmjgp7smgxemnfA8uj2C_OXLtZ-M2AOIZRCXzAxzG';
    }
    if (t.contains('work') || t.contains('project')) {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuAWpMNj0Ezm1mYtevKRBBKG3uZ39JBbPjpdBKkgrCp0dBxriSct9kjWTm_6YQsDLFwv-j54mJjSsebkMjFD6o638PBfvVM_LWGiS1VB8NrSUhYpowon3F2LttbWpVbhoU86vZB1hDTUOp9-_1eHAGKtGxAs19P6MedZv3N9Zv4WKilG3IlwCZMKoQnVYzSvU4-aAdL6BXVb372ZL3YDAcMdZfjveUXUW2Dc8gb23Z3CIVNDA17lXOerJbr_xKSc5-2QknAwKih2CjsF';
    }
    
    final fallbacks = [
      'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?q=80&w=400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1552664730-d307ca884978?q=80&w=400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1454165833767-027ffea9e787?q=80&w=400&auto=format&fit=crop',
    ];
    return fallbacks[title.length % fallbacks.length];
  }

  void _submit() {
    if (!_isTitleNotEmpty) return;

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
          const SnackBar(
            content: Text('A session with this name already exists.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final newGoal = Goal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description.isNotEmpty ? description : 'No description provided',
        dueDate: DateTime.now().add(const Duration(days: 30)), // Default 30 days
        status: GoalStatus.active,
        icon: _getIconForTitle(title),
        imageUrl: _getImageForTitle(title),
      );

      GoalService().addGoal(newGoal);
      Navigator.pop(context, newGoal); // Return the new goal
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppColors.slate400),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.slate100),
                  
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
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
                            hintStyle: const TextStyle(fontSize: 14, color: AppColors.slate400),
                            filled: true,
                            fillColor: AppColors.slate100.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.slate200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            counterText: '',
                          ),
                          style: const TextStyle(fontSize: 14, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
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
                                style: const TextStyle(fontSize: 10, color: AppColors.slate400),
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
                            hintStyle: const TextStyle(fontSize: 14, color: AppColors.slate400),
                            filled: true,
                            fillColor: AppColors.slate100.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.slate200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            counterText: '',
                          ),
                          style: const TextStyle(
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
                              side: const BorderSide(color: AppColors.slate200),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isTitleNotEmpty ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.slate200,
                              disabledForegroundColor: AppColors.slate400,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
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
