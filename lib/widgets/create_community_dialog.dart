import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../theme/app_colors.dart';
import '../models/workspace_models.dart';
import '../services/workspace_service.dart';

class InvitedMember {
  final String name;
  final String email;
  final bool isEmployee;
  String role; // 'Admin' or 'Team Member'

  InvitedMember({
    required this.name,
    required this.email,
    required this.isEmployee,
    this.role = 'Team Member',
  });
}

class CreateCommunityDialog extends StatefulWidget {
  const CreateCommunityDialog({super.key});

  @override
  State<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRoleToAdd = 'Team Member';
  String? _emailErrorText;
  String? _nameErrorText;
  
  final List<InvitedMember> _invitedMembers = [];
  bool _isNameNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _isNameNotEmpty = _nameController.text.trim().isNotEmpty;
      });
    });
    _memberNameController.addListener(() {
      if (_nameErrorText != null && _memberNameController.text.isNotEmpty) {
        setState(() {
          _nameErrorText = null;
        });
      }
    });
    _emailController.addListener(() {
      if (_emailErrorText != null && _emailController.text.isNotEmpty) {
        setState(() {
          _emailErrorText = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _memberNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    final email = _emailController.text.trim();
    
    bool hasError = false;
    if (name.isEmpty) {
      setState(() => _nameErrorText = 'Required field.');
      hasError = true;
    }
    if (email.isEmpty) {
      setState(() => _emailErrorText = 'Required field.');
      hasError = true;
    }
    if (hasError) return;
    
    // Simple email validation
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailErrorText = 'Please enter a valid email address.';
      });
      return;
    }
    
    if (_invitedMembers.any((m) => m.email.toLowerCase() == email.toLowerCase())) {
      setState(() {
        _emailErrorText = 'User is already invited.';
      });
      return;
    }

    // Mock logic to check if they are an employee in the system
    // In a real app, this would be an API call
    final isEmployee = email.toLowerCase().endsWith('@progresso.com');
    
    setState(() {
      _invitedMembers.add(InvitedMember(
        name: name,
        email: email,
        isEmployee: isEmployee,
        role: isEmployee ? _selectedRoleToAdd : 'Team Member', // Default to Team Member for external if they somehow get a role
      ));
      _emailController.clear();
      _memberNameController.clear();
      _selectedRoleToAdd = 'Team Member';
      _emailErrorText = null;
      _nameErrorText = null;
    });
  }

  void _removeMember(InvitedMember member) {
    setState(() {
      _invitedMembers.remove(member);
    });
  }

  void _submit() {
    if (!_isNameNotEmpty) return;
    
    final newCommunity = Community(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      members: [
        // Automatically include the creator as the Owner
        CommunityMember(
          id: 'current_user',
          name: 'Alex Rivera',
          email: 'alex@progresso.com',
          avatarUrl: 'https://i.pravatar.cc/150?img=11',
          role: CommunityRole.owner,
        ),
        // Map invited members over
        ..._invitedMembers.map((m) => CommunityMember(
          id: m.email,
          name: m.name,
          email: m.email,
          avatarUrl: 'https://i.pravatar.cc/150?img=${m.email.hashCode % 70}', // Assign a random avatar based on email
          role: m.role == 'Admin' ? CommunityRole.admin : CommunityRole.member,
        )),
      ],
      communitySessions: [],
    );

    // Save it globally
    WorkspaceService().addCommunity(newCommunity);

    // Close Modal
    Navigator.pop(context);
  }

  Widget _buildRoleSelector(String currentValue, ValueChanged<String> onChanged) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48), // Position directly below the container
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: AppColors.slate200.withOpacity(0.5)),
        ),
        color: Colors.white,
        padding: EdgeInsets.zero,
        onSelected: onChanged,
        itemBuilder: (context) => ['Admin', 'Team Member'].map((role) {
          final isSelected = role == currentValue;
          return PopupMenuItem<String>(
            value: role,
            height: 44,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.slate200.withOpacity(0.6) : Colors.transparent,
              ),
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.slate900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate200),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentValue,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
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
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create New Community',
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
                  
                  // --- Body ---
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Community Name field
                        Text(
                          'Community Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          maxLength: 100,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'e.g. Design Team, Engineering',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                            filled: false,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.slate200),
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
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),
                        
                        // Description Field
                        Text(
                          'Description (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descController,
                          maxLength: 300,
                          minLines: 3,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'What is this community for?',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                            filled: false,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.slate200),
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
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Divider(height: 1, color: AppColors.slate100),
                        const SizedBox(height: 24),

                        // Invite Members 
                        Text(
                          'Invite Members',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _memberNameController,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: 'Employee Name',
                                  hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                                  errorText: _nameErrorText,
                                  errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
                                  filled: false,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.slate200),
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
                                ),
                                style: TextStyle(fontSize: 14, color: AppColors.slate900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _addMember(),
                                decoration: InputDecoration(
                                  hintText: 'Email address',
                                  hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                                  errorText: _emailErrorText,
                                  errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
                                  filled: false,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.slate200),
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
                                ),
                                style: TextStyle(fontSize: 14, color: AppColors.slate900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.topCenter,
                                child: _buildRoleSelector(
                                  _selectedRoleToAdd,
                                  (String newValue) {
                                    setState(() {
                                      _selectedRoleToAdd = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.topCenter,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: _addMember,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),

                        // Invited Members List
                        if (_invitedMembers.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Invited Members',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _invitedMembers.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.slate100),
                            itemBuilder: (context, index) {
                              final member = _invitedMembers[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: member.isEmployee ? AppColors.indigo50 : AppColors.slate100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        member.isEmployee ? Icons.person : Icons.person_outline,
                                        color: member.isEmployee ? AppColors.primary : AppColors.slate500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.name,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            member.email,
                                            style: TextStyle(fontSize: 12, color: AppColors.slate500),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: member.isEmployee ? Color(0xFFECFDF5) : AppColors.slate100,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  member.isEmployee ? 'Employee' : 'External',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: member.isEmployee ? Color(0xFF059669) : AppColors.slate500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (member.isEmployee) ...[
                                            const SizedBox(height: 12),
                                            // Role Selector
                                            _buildRoleSelector(
                                              member.role,
                                              (String newValue) {
                                                setState(() {
                                                  member.role = newValue;
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            // Permissions Explainer
                                            Text(
                                              member.role == 'Admin' 
                                                ? '- Can view productivity analytics of all members\n- Can manage members and roles\n- Can access team productivity insights'
                                                : '- Can view only their own productivity data\n- Cannot see analytics of other employees\n- Cannot manage other members',
                                              style: TextStyle(fontSize: 11, color: AppColors.slate500, height: 1.5),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeMember(member),
                                      icon: Icon(Icons.close, size: 20, color: AppColors.slate400),
                                      tooltip: 'Remove',
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ]
                      ],
                    ),
                  ),
                  
                  // --- Footer ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      border: Border(top: BorderSide(color: AppColors.slate200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isNameNotEmpty ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.slate200,
                            disabledForegroundColor: AppColors.slate400,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Create Community',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

void showCreateCommunityDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create New Community',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => const CreateCommunityDialog(),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8 * anim1.value, sigmaY: 8 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ),
      );
    },
  );
}