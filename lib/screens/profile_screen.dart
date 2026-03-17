import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/theme/theme_notifier.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

enum ProfileSection {
  personalInfo,
  accountSettings,
  security,
  workspaces,
  notifications,
  billing,
  activity,
  integrations
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bioCtrl;
  
  bool _isEditing = false;
  String _selectedTheme = 'Light Mode';
  String? _imageUrl;
  double _rotation = 0;
  File? _localImageFile;

  ProfileSection _activeSection = ProfileSection.personalInfo;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _nameCtrl = TextEditingController(text: user?['name'] ?? 'Google User');
    _emailCtrl = TextEditingController(text: user?['email'] ?? 'Unknown');
    _bioCtrl = TextEditingController(text: user?['bio'] ?? 'Product Designer based in San Francisco');
    _imageUrl = user?['imageUrl'];
    _rotation = user?['rotation']?.toDouble() ?? 0.0;
    if (user?['localImagePath'] != null) {
      _localImageFile = File(user!['localImagePath']);
    }
    
    _selectedTheme = themeNotifier.themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode';
    
    _nameCtrl.addListener(() {
      setState(() {});
    });
    _bioCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // Generates Gravatar based on email hash or returns custom imageUrl
  ImageProvider _getAvatarProvider(String email) {
    if (_localImageFile != null && _localImageFile!.existsSync()) {
      return FileImage(_localImageFile!);
    }
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return NetworkImage(_imageUrl!);
    }
    if (email.isEmpty) return const NetworkImage('https://www.gravatar.com/avatar/?d=mp');
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = md5.convert(bytes);
    return NetworkImage('https://www.gravatar.com/avatar/$digest?d=mp&s=200');
  }

  Future<bool> _pickLocalImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _localImageFile = File(result.files.single.path!);
          _imageUrl = null; // Prioritize local image
        });
        return true;
      }
    } catch (e) {
      developer.log('Error picking local image: $e');
    }
    return false;
  }

  void _showAdvancedImageEditor() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return DropTarget(
            onDragDone: (details) {
              if (details.files.isNotEmpty) {
                setDialogState(() {
                  _localImageFile = File(details.files.first.path);
                  _imageUrl = null;
                });
                setState(() {});
              }
            },
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Edit Profile Appearance', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Preview
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.slate200, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Transform.rotate(
                      angle: _rotation * (3.14159 / 180),
                      child: Image(
                        image: _getAvatarProvider(_emailCtrl.text),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          bool success = await _pickLocalImage();
                          if (success) {
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text('Select File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate100,
                          foregroundColor: AppColors.slate700,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () {
                          setDialogState(() => _rotation = (_rotation + 90) % 360);
                          setState(() {});
                        },
                        icon: const Icon(Icons.rotate_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Tip: You can also drag & drop an image here', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate400, fontStyle: FontStyle.italic)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildSidebarItem(IconData icon, String label, ProfileSection section) {
    final bool isActive = _activeSection == section;
    return GestureDetector(
      onTap: () => setState(() {
        _activeSection = section;
        _isEditing = false; // Reset editing state when switching sections
      }),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.indigo50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isActive ? AppColors.indigo600 : AppColors.slate500),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.indigo600 : AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final String email = user?['email'] ?? 'Unknown';
    final String name = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Google User';

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile & Settings',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Profile Summary Card
            _buildProfileSummaryCard(user, name, email),

            const SizedBox(height: 32),

            // Divided Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical Navigation Sidebar
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSidebarItem(Icons.person_outline_rounded, 'Personal Information', ProfileSection.personalInfo),
                      _buildSidebarItem(Icons.settings_outlined, 'Account Settings', ProfileSection.accountSettings),
                      _buildSidebarItem(Icons.lock_outline_rounded, 'Security', ProfileSection.security),
                      _buildSidebarItem(Icons.work_outline_rounded, 'Workspaces & Communities', ProfileSection.workspaces),
                      _buildSidebarItem(Icons.notifications_none_rounded, 'Notifications', ProfileSection.notifications),
                      _buildSidebarItem(Icons.credit_card_rounded, 'Billing / Subscription', ProfileSection.billing),
                      _buildSidebarItem(Icons.history_rounded, 'Activity History', ProfileSection.activity),
                      _buildSidebarItem(Icons.extension_outlined, 'Connected Integrations', ProfileSection.integrations),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () async {
                           await AuthService().logout();
                           if (context.mounted) {
                             Navigator.of(context).pushAndRemoveUntil(
                               MaterialPageRoute(builder: (context) => const AuthScreen()),
                               (Route<dynamic> route) => false
                             );
                           }
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.rose50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.rose100),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded, size: 20, color: AppColors.rose600),
                                const SizedBox(width: 12),
                                Text(
                                  'Log Out',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.rose600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),

                // Main Content Area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: _buildSectionContent(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case ProfileSection.personalInfo:
        return _buildPersonalInformationSection();
      case ProfileSection.accountSettings:
        return _buildAccountSettingsSection();
      case ProfileSection.security:
        return _buildSecuritySection();
      case ProfileSection.workspaces:
        return _buildWorkspacesSection();
      default:
        return _buildPlaceholderSection('Section', 'This section is currently under development.');
    }
  }

  Widget _buildAccountSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Settings',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate900),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account preferences, language, and regional settings.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.slate200),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSettingRow(Icons.language_rounded, 'Language', 'English (US)'),
              const SizedBox(height: 24),
              _buildSettingRow(Icons.public_rounded, 'Timezone', '(GMT-08:00) Pacific Time'),
              const SizedBox(height: 24),
              _buildSettingRow(Icons.calendar_today_rounded, 'Week Start', 'Monday'),
              const SizedBox(height: 32),
              const Divider(color: AppColors.slate100),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delete Account', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.rose600)),
                      const SizedBox(height: 4),
                      Text('Permanently remove your account and all data.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose600,
                      side: const BorderSide(color: AppColors.rose200),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate900),
              ),
              const SizedBox(height: 4),
              Text(
                'Control your password and account access security.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.slate200),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSecurityOption(
                Icons.password_rounded,
                'Change Password',
                'Last changed 3 months ago',
                'Update',
              ),
              const SizedBox(height: 24),
              _buildSecurityOption(
                Icons.phonelink_lock_rounded,
                'Two-Factor Authentication',
                'Add an extra layer of security to your account',
                'Setup',
                isEnabled: false,
              ),
              const SizedBox(height: 24),
              _buildSecurityOption(
                Icons.devices_rounded,
                'Logged-in Devices',
                'Manage your active sessions on different devices',
                'Manage',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workspaces & Communities',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate900),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage the workspaces and communities you belong to.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.slate200),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Workspaces', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate700)),
              const SizedBox(height: 16),
              _buildWorkspaceItem('Personal Workspace', 'Default', true),
              const SizedBox(height: 12),
              _buildWorkspaceItem('Development Team', 'Shared', false),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Communities', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCommunityItem('Flutter Enthusiasts', '2.4k Members'),
              const SizedBox(height: 12),
              _buildCommunityItem('Product Design Hub', '850 Members'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: AppColors.slate600),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate900)),
          ],
        ),
        const Spacer(),
        const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
      ],
    );
  }

  Widget _buildSecurityOption(IconData icon, String title, String subtitle, String action, {bool isEnabled = true}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 24, color: AppColors.slate600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate900)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () {},
          child: Text(action, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildWorkspaceItem(String name, String type, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.indigo50.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrent ? AppColors.indigo200 : AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: isCurrent ? AppColors.indigo600 : AppColors.slate100, borderRadius: BorderRadius.circular(8)),
            child: Icon(isCurrent ? Icons.check : Icons.work_outline, color: isCurrent ? Colors.white : AppColors.slate500, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate900)),
                Text(type, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
              ],
            ),
          ),
          if (!isCurrent)
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: AppColors.slate200),
              ),
              child: const Text('Switch'),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityItem(String name, String members) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.slate100,
            child: Text(name[0], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.slate600)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate900)),
                Text(members, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: AppColors.slate400),
        ],
      ),
    );
  }

  Widget _buildPersonalInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your personal details and how others see you.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.slate200),
        
        // Form
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormRow('Full Name', _nameCtrl),
              const SizedBox(height: 24),
              _buildFormRow('Email Address', _emailCtrl),
              const SizedBox(height: 24),
              _buildFormRow('Biography', _bioCtrl, maxLines: 3),
            ],
          ),
        ),
        
        const Divider(height: 1, color: AppColors.slate200),
        
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme Settings',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Interface Mode',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildThemeCard('Light Mode', true)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildThemeCard('Dark Mode', false)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Select your preferred visual style for the FocusFlow interface.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500),
              ),
            ],
          ),
        ),

        if (_isEditing)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: AppColors.slate200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.slate600,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedTheme == 'Dark Mode') {
                      themeNotifier.setTheme(ThemeMode.dark);
                    } else {
                      themeNotifier.setTheme(ThemeMode.light);
                    }
                    await AuthService().updateProfile(
                      name: _nameCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      bio: _bioCtrl.text.trim(),
                      imageUrl: _imageUrl,
                      rotation: _rotation,
                      localImagePath: _localImageFile?.path,
                    );
                    
                    setState(() => _isEditing = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings saved successfully'), backgroundColor: AppColors.indigo600),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildPlaceholderSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.slate200),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction_rounded, size: 64, color: AppColors.slate300),
                const SizedBox(height: 16),
                Text(
                  'Section Under Construction',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We are working hard to bring you these settings.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard(Map<String, dynamic>? user, String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Camera Icon
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.indigo50, width: 4),
                ),
                clipBehavior: Clip.antiAlias,
                child: Transform.rotate(
                  angle: _rotation * (3.14159 / 180),
                  child: Image(
                    image: _getAvatarProvider(email),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isEditing ? _showAdvancedImageEditor : null,
                  child: MouseRegion(
                    cursor: _isEditing ? SystemMouseCursors.click : SystemMouseCursors.basic,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.indigo600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigo600.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _bioCtrl.text,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildBadge('Pro Plan', AppColors.indigo50, AppColors.indigo600),
                    const SizedBox(width: 10),
                    _buildBadge('Verified', AppColors.slate100, AppColors.slate600),
                  ],
                ),
              ],
            ),
          ),
          // Edit Profile Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit_rounded, size: 20, color: _isEditing ? AppColors.slate600 : Colors.white),
            label: Text(_isEditing ? 'Cancel Edit' : 'Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEditing ? AppColors.slate100 : AppColors.indigo600,
              foregroundColor: _isEditing ? AppColors.slate700 : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildFormRow(String label, TextEditingController controller, {int maxLines = 1, bool isReadOnly = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate700,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: _isEditing && !isReadOnly,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate900),
            decoration: InputDecoration(
              filled: true,
              fillColor: _isEditing ? Colors.white : AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.slate300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.slate300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.indigo500, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.slate200),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isReadOnly 
                  ? const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.slate400) 
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(String modeName, bool isLight) {
    bool isSelected = _selectedTheme == modeName;
    return GestureDetector(
      onTap: _isEditing ? () => setState(() => _selectedTheme = modeName) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.indigo500 : AppColors.slate200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.indigo500.withOpacity(0.1), blurRadius: 8, spreadRadius: 0)]
              : [],
        ),
        child: Column(
          children: [
            // Preview area
            Container(
              height: 140,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLight ? AppColors.slate50 : AppColors.slate800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.slate100),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(height: 8, width: 40, decoration: BoxDecoration(color: isLight ? AppColors.slate200 : AppColors.slate600, borderRadius: BorderRadius.circular(4))),
                   const SizedBox(height: 8),
                   Container(height: 8, width: 60, decoration: BoxDecoration(color: isLight ? AppColors.slate200 : AppColors.slate600, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                modeName.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.indigo600 : AppColors.slate500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
