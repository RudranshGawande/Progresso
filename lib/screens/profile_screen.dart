import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/theme/settings_notifier.dart';
import 'package:progresso/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import 'package:progresso/services/security_service.dart';
import 'package:progresso/models/security_models.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mongo_dart/mongo_dart.dart' show where, modify, ObjectId;
import 'package:progresso/services/mongodb_service.dart';
import 'package:progresso/config/db_collections.dart';

enum ProfileSection {
  personalInfo,
  accountSettings,
  security
}


class _PickerOption {
  final String label;
  final dynamic value;
  final bool isActive;

  _PickerOption({
    required this.label,
    required this.value,
    required this.isActive,
  });
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
    // Initialize controllers with current user data
    final user = AuthService().currentUser;
    _nameCtrl = TextEditingController(text: user?['name'] ?? '');
    _emailCtrl = TextEditingController(text: user?['email'] ?? '');
    _bioCtrl = TextEditingController(text: user?['bio'] ?? '');
    _applyUserData(user);

    // Refresh user data from DB whenever we enter the profile screen
    AuthService().refreshUser();
    
    // Listen for changes in AuthService to update UI in real-time
    AuthService().addListener(_onAuthChanged);
    
    _selectedTheme = settingsNotifier.themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode';
    
    _nameCtrl.addListener(() {
      setState(() {});
    });
    _bioCtrl.addListener(() {
      setState(() {});
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final user = AuthService().currentUser;
    _applyUserData(user);
    setState(() {});
  }

  void _applyUserData(Map<String, dynamic>? user) {
    if (user == null) return;
    
    // Extraction with robust fallbacks
    final String bio = user['profile']?['bio']?.toString() ?? user['bio']?.toString() ?? '';
    final String name = user?['name']?.toString() ?? user['profile']?['name']?.toString() ?? user['auth']?['name']?.toString() ?? '';
    final String email = user['auth']?['email']?.toString() ?? user['email']?.toString() ?? '';

    developer.log('👤 UI: Applying User Data. Name: $name, Email: $email, Bio Length: ${bio.length}');

    // Only update controllers if the values have actually changed to avoid cursor jumps
    if (_nameCtrl.text != name && name.isNotEmpty) {
      _nameCtrl.text = name;
    }
    if (_emailCtrl.text != email && email.isNotEmpty) {
      _emailCtrl.text = email;
    }
    
    // Crucial fix: Only update controller if new bio is non-null and different
    if (_bioCtrl.text != bio) {
      _bioCtrl.text = bio;
    }
    
    _imageUrl = user['profile']?['avatarUrl'] ?? user['imageUrl'];
    _rotation = user['rotation']?.toDouble() ?? 0.0;
    if (user['localImagePath'] != null) {
      _localImageFile = File(user['localImagePath']);
    }
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    // Determine the photo to save to database as base64
    String? base64Avatar;
    if (_localImageFile != null && _localImageFile!.existsSync()) {
      try {
        final bytes = await _localImageFile!.readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);
        if (decoded != null) {
          // Resize for efficiency (e.g. 256x256)
          img.Image resized = img.copyResize(decoded, width: 256, height: 256);
          base64Avatar = base64Encode(img.encodeJpg(resized, quality: 85));
        }
      } catch (e) {
        developer.log('Error processing profile image for upload: $e');
      }
    }

    final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
    if (_selectedTheme == 'Dark Mode') {
      settingsNotifier.setTheme(ThemeMode.dark);
    } else {
      settingsNotifier.setTheme(ThemeMode.light);
    }

    await AuthService().updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      imageUrl: _imageUrl,
      rotation: _rotation,
      localImagePath: _localImageFile?.path,
      avatarBase64: base64Avatar,
    );
    
    // After saving, clear local file buffer to prioritize database-synced image
    setState(() {
      _isEditing = false;
      _localImageFile = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings saved successfully'), backgroundColor: AppColors.indigo600),
      );
    }
  }

  // Generates Gravatar based on email hash or returns custom imageUrl
  ImageProvider _getAvatarProvider(String email) {
    if (_localImageFile != null && _localImageFile!.existsSync()) {
      return FileImage(_localImageFile!);
    }
    
    // Check for base64 image in user profile (Database source)
    final user = context.read<AuthService>().currentUser;
    final base64Image = user?['profile']?['avatarBase64'] ?? user?['avatarBase64'];
    if (base64Image != null && base64Image.toString().isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64Image.toString()));
      } catch (e) {
        developer.log('Error decoding base64 avatar: $e');
      }
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return NetworkImage(_imageUrl!);
    }
    if (email.isEmpty) return const AssetImage('assets/images/avatar.png');
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = md5.convert(bytes);
    // For testing, always use local avatar or handle error
    return const AssetImage('assets/images/avatar.png');
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
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.indigo600 : AppColors.slate600,
                  ),
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
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        
        // Mandatory Logging Requirement
        developer.log('🖼️ UI RENDER: ProfileScreen build cycle. Bio in state: ${user?['profile']?['bio']}');
        
        final String email = user?['email'] ?? user?['auth']?['email'] ?? 'Unknown';
        final String name = user?['name'] ?? user?['profile']?['name'] ?? user?['auth']?['name'] ?? 'User';
        final String bio = user?['profile']?['bio'] ?? user?['bio'] ?? '';
        final settingsNotifier = Provider.of<SettingsNotifier>(context);

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
                _buildProfileSummaryCard(user, name, bio, email),

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
                                    Icon(Icons.logout_rounded, size: 20, color: AppColors.rose600),
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
      },
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
      default:
        return _buildPlaceholderSection('Section', 'This section is currently under development.');
    }
  }

  Widget _buildAccountSettingsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.accountSettings,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate900),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.accountSettingsDesc,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.slate200),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSettingRow(
                Icons.language_rounded, 
                l10n.language, 
                settingsNotifier.locale.languageCode == 'en' ? 'English (US)' : 'Español',
                onTap: () => _showLanguagePicker(),
              ),
              const SizedBox(height: 24),
              _buildSettingRow(
                Icons.public_rounded, 
                l10n.timezone, 
                '(GMT+05:30) India Standard Time',
                onTap: () {},
              ),
              const SizedBox(height: 24),
              _buildSettingRow(
                Icons.calendar_today_rounded, 
                l10n.weekStart, 
                settingsNotifier.firstDayOfWeek == 1 ? l10n.monday : l10n.sunday,
                onTap: () => _showWeekStartPicker(),
              ),
              const SizedBox(height: 32),
              Divider(color: AppColors.slate100),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.deleteAccount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.rose600)),
                        const SizedBox(height: 4),
                        Text(
                          l10n.deleteAccountDesc,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _showDeleteAccountConfirmation(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose600,
                      side: BorderSide(color: AppColors.rose100),
                    ),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountConfirmation() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Explicit colors for a "Bright, Clean" Slate look (even if app is in dark mode if needed)
    // But aligning with "bright mode" request usually means light theme defaults
    final Color titleColor = AppColors.slate900;
    final Color subtitleColor = AppColors.slate700;
    final Color bodyColor = AppColors.slate500;
    final Color dialogBg = Colors.white;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 100), // Narrower width
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.rose500, size: 24),
              const SizedBox(width: 12),
              Text(
                'Delete Account',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, 
                  color: titleColor,
                  fontSize: 18
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you absolutely sure?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, 
                    color: subtitleColor,
                    fontSize: 14
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action is total and irreversible. All your progress, goals, and personal settings will be purged from our servers forever.',
                  style: GoogleFonts.inter(
                    color: bodyColor, 
                    fontSize: 13,
                    height: 1.6
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.slate300 : AppColors.slate500, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deleting account...'),
                    duration: Duration(seconds: 2),
                  ),
                );

                final bool success = await AuthService().deleteAccount();
                
                if (success) {
                  if (mounted) {
                    // Navigate to AuthScreen and clear the entire navigation stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account. Please try again later.'),
                        backgroundColor: AppColors.rose600,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Delete Permanently',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguagePicker() {
    _showModernPicker(
      title: AppLocalizations.of(context)!.language,
      icon: Icons.translate_rounded,
      options: [
        _PickerOption(label: 'English (US)', value: 'en', isActive: settingsNotifier.locale.languageCode == 'en'),
        _PickerOption(label: 'Español', value: 'es', isActive: settingsNotifier.locale.languageCode == 'es'),
      ],
      onSelect: (value) => settingsNotifier.setLocale(Locale(value as String)),
    );
  }

  void _showWeekStartPicker() {
    final l10n = AppLocalizations.of(context)!;
    _showModernPicker(
      title: l10n.weekStart,
      icon: Icons.calendar_month_rounded,
      options: [
        _PickerOption(label: l10n.monday, value: 1, isActive: settingsNotifier.firstDayOfWeek == 1),
        _PickerOption(label: l10n.sunday, value: 7, isActive: settingsNotifier.firstDayOfWeek == 7),
      ],
      onSelect: (value) => settingsNotifier.setFirstDayOfWeek(value as int),
    );
  }

  void _showModernPicker({
    required String title,
    required IconData icon,
    required List<_PickerOption> options,
    required Function(dynamic) onSelect,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 380,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.indigo50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: AppColors.indigo600, size: 24),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.slate100),
                  // Options
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: options.map((opt) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              onSelect(opt.value);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              decoration: BoxDecoration(
                                color: opt.isActive ? AppColors.indigo50.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: opt.isActive ? AppColors.indigo100.withOpacity(0.5) : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      opt.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: opt.isActive ? FontWeight.w600 : FontWeight.w500,
                                        color: opt.isActive ? AppColors.indigo600 : AppColors.slate700,
                                      ),
                                    ),
                                  ),
                                  if (opt.isActive)
                                    Icon(Icons.check_circle_rounded, color: AppColors.indigo600, size: 22)
                                  else
                                    Container(
                                      height: 22,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.slate300, width: 1.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecuritySection() {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final user = AuthService().currentUser;
        final is2faEnabled = AuthService().is2faEnabled;

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
            Divider(height: 1, color: AppColors.slate200),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final lastChanged = user?['lastPasswordChange'];
                      String subtitle = 'Update your account password regularly';
                      if (lastChanged != null) {
                        try {
                          final dt = DateTime.parse(lastChanged);
                          subtitle = 'Last changed: ${DateFormat.yMMMd().format(dt)}';
                        } catch (_) {}
                      }
                      return _buildSecurityOption(
                        Icons.password_rounded,
                        'Change Password',
                        subtitle,
                        'Update',
                        onPressed: _showChangePasswordDialog,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      developer.log('🛡️ 2FA UI State: is2faEnabled=$is2faEnabled');
                      return _buildSecurityOption(
                        Icons.phonelink_lock_rounded,
                        'Two-Factor Authentication',
                        is2faEnabled ? 'Currently enabled for your account' : 'Add an extra layer of security to your account',
                        is2faEnabled ? 'Disable' : 'Setup',
                        onPressed: is2faEnabled ? _confirmDisable2fa : _show2faSetupDialog,
                        buttonColor: is2faEnabled ? AppColors.rose600 : AppColors.indigo600,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSecurityOption(
                    Icons.devices_rounded,
                    'Logged-in Devices',
                    'Manage your active sessions on different devices',
                    'Manage',
                    onPressed: _showDeviceManagementDialog,
                    badge: FutureBuilder<List<UserSession>>(
                      future: SecurityService().getActiveSessions(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.indigo50, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              snapshot.data!.length.toString(),
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.indigo600),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _buildModernDialog(
          icon: Icons.password_rounded,
          title: 'Change Password',
          subtitle: 'Secure your account with a strong password',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernTextField(
                controller: currentPasswordCtrl,
                label: 'Current Password',
                obscureText: true,
                icon: Icons.lock_open_rounded,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: newPasswordCtrl,
                label: 'New Password',
                obscureText: true,
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: confirmPasswordCtrl,
                label: 'Confirm New Password',
                obscureText: true,
                icon: Icons.lock_reset_rounded,
              ),
            ],
          ),
          actions: [
            _buildModernSecondaryButton('Cancel', () => Navigator.pop(context)),
            const SizedBox(width: 12),
            _buildModernPrimaryButton(
              'Update',
              isLoading,
              () async {
                if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                  return;
                }
                setState(() => isLoading = true);
                try {
                  await SecurityService().changePassword(currentPasswordCtrl.text, newPasswordCtrl.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                } finally {
                  setState(() => isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _show2faSetupDialog() async {
    String? secret;
    String? qrData;
    
    try {
      final setupData = await SecurityService().setup2fa();
      secret = setupData['secret'];
      qrData = setupData['qrData'];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting setup: $e')));
      }
      return;
    }

    final otpCtrl = TextEditingController();
    bool step2 = false;
    bool isLoading = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => _buildModernDialog(
          icon: Icons.phonelink_lock_rounded,
          title: 'Setup 2FA',
          subtitle: step2 ? 'Verify your device' : 'Scan the QR code',
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!step2) ...[
                  Text(
                    'Scan this QR code with your Authenticator app (Google Authenticator, Authy, etc.)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate600),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      setStateDialog(() => step2 = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.slate100),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigo500.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Manual Key:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(8)),
                    child: SelectableText(secret!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.indigo600)),
                  ),
                ] else ...[
                  Text(
                    'Enter the 6-digit code from your app to verify the setup.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: _buildModernTextField(
                      controller: otpCtrl,
                      label: '6-Digit Code',
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            _buildModernSecondaryButton('Cancel', () => Navigator.pop(context)),
            const SizedBox(width: 12),
            _buildModernPrimaryButton(
              step2 ? 'Verify & Enable' : 'Next',
              isLoading,
              () async {
                if (!step2) {
                  setStateDialog(() => step2 = true);
                } else {
                  setStateDialog(() => isLoading = true);
                  try {
                    final isValid = await SecurityService().verifySetupStep(otpCtrl.text);
                    if (isValid) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {}); // Force rebuild to update button
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA enabled successfully')));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP code')));
                      }
                      setStateDialog(() => isLoading = false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification error: $e')));
                    }
                    setStateDialog(() => isLoading = false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDisable2fa() {
    final otpCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => _buildModernDialog(
          icon: Icons.no_encryption_gmailerrorred_rounded,
          title: 'Disable 2FA',
          subtitle: 'Verify your identity to disable security',
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the 6-digit code from your authenticator app to disable two-factor authentication.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 240,
                  child: _buildModernTextField(
                    controller: otpCtrl,
                    label: '6-Digit Code',
                    icon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            _buildModernSecondaryButton('Cancel', () => Navigator.pop(context)),
            const SizedBox(width: 12),
            _buildModernPrimaryButton(
              'Disable Now',
              isLoading,
              () async {
                if (otpCtrl.text.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a 6-digit code')));
                  return;
                }
                setStateDialog(() => isLoading = true);
                try {
                  final success = await SecurityService().disable2fa(otpCtrl.text);
                  if (success) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      // UI will auto-update via ListenableBuilder around _buildSecuritySection
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA disabled successfully')));
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code. Please try again.')));
                    }
                    setStateDialog(() => isLoading = false);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                  setStateDialog(() => isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _verifyCurrentPassword(String password) async {
    final user = AuthService().currentUser;
    if (user == null) return false;
    final db = MongoDBService().db;
    if (db == null) return false;
    
    // Hash the password and check DB
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    final collection = db.collection('users');
    final dbUser = await collection.findOne(where.eq('email', user['email']));
    return dbUser != null && dbUser['passwordHash'] == hashedPassword;
  }

  void _showDeviceManagementDialog() async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _buildModernDialog(
          icon: Icons.devices_rounded,
          title: 'Active Sessions',
          subtitle: 'Devices logged into your account',
          content: Container(
            constraints: const BoxConstraints(maxHeight: 450, maxWidth: 500),
            width: double.maxFinite,
            child: FutureBuilder<List<UserSession>>(
              future: SecurityService().getActiveSessions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final sessions = snapshot.data!;
                
                if (sessions.isEmpty) {
                   return Center(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 32),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(Icons.devices_rounded, size: 48, color: AppColors.slate300),
                           const SizedBox(height: 16),
                           Text('No active sessions found', style: GoogleFonts.inter(color: AppColors.slate500)),
                         ],
                       ),
                     ),
                   );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: session.isCurrent ? AppColors.emerald50.withOpacity(0.5) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: session.isCurrent ? Border.all(color: AppColors.emerald200, width: 1.5) : Border.all(color: AppColors.slate100),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: session.isCurrent ? AppColors.emerald100 : AppColors.slate50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      session.deviceType == 'Mobile' ? Icons.smartphone_rounded : Icons.desktop_windows_rounded,
                                      color: session.isCurrent ? AppColors.emerald600 : AppColors.slate500,
                                      size: 20,
                                    ),
                                  ),
                                  if (session.isCurrent)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald500,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    session.deviceName,
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: session.isCurrent ? FontWeight.bold : FontWeight.w500, color: AppColors.slate900),
                                  ),
                                  const SizedBox(width: 8),
                                  // Role Bit / Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.indigo50, 
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.indigo100)
                                    ),
                                    child: Text(
                                      session.deviceType.toUpperCase(),
                                      style: GoogleFonts.inter(color: AppColors.indigo600, fontSize: 8, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (session.isCurrent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.emerald500, borderRadius: BorderRadius.circular(12)),
                                      child: Text('THIS DEVICE', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${session.osInfo} • ${session.ipAddress ?? '127.0.0.1'}',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500),
                                  ),
                                  if (session.isCurrent)
                                    Text(
                                      'Active Now (This Device)',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.emerald600, fontWeight: FontWeight.w600),
                                    )
                                  else
                                    Text(
                                      'Last active: ${DateFormat.yMMMd().add_Hm().format(session.lastActive.toLocal())}',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.logout_rounded, color: session.isCurrent ? AppColors.slate300 : AppColors.rose500, size: 20),
                                onPressed: () async {
                                  if (session.isCurrent) {
                                    final confirm = await _showCurrentDeviceLogoutWarning();
                                    if (confirm != true) return;
                                    
                                    await SecurityService().revokeSession(session.id);
                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                                        (route) => false,
                                      );
                                    }
                                  } else {
                                    await SecurityService().revokeSession(session.id);
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (sessions.length > 1) ...[
                      Divider(height: 1, color: AppColors.slate100),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildModernSecondaryButton(
                            'Log out other devices', 
                            () async {
                              await SecurityService().revokeAllOtherSessions();
                              setState(() {});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out from all other devices')));
                              }
                            },
                          ),
                          const Spacer(),
                          _buildModernSecondaryButton('Close', () => Navigator.pop(context)),
                        ],
                      ),
                    ] else ...[
                       const SizedBox(height: 16),
                       Align(
                         alignment: Alignment.centerRight,
                         child: _buildModernSecondaryButton('Close', () => Navigator.pop(context)),
                       ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers for Security Dialogs ---

  Widget _buildModernDialog({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
    List<Widget>? actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.indigo50, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: AppColors.indigo600, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.slate900)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            content,
            if (actions != null) ...[
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textAlign: textAlign,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.slate900, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.slate400),
            filled: true,
            fillColor: AppColors.slate50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.indigo500, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildModernPrimaryButton(String label, bool isLoading, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo600,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) 
        : Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildModernSecondaryButton(String label, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.slate600,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSettingRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 20, color: AppColors.slate600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
                  Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate900),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption(IconData icon, String title, String subtitle, String action, {VoidCallback? onPressed, bool isEnabled = true, Color? buttonColor, Widget? badge}) {
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
              Row(
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate900)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    badge,
                  ],
                ],
              ),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate500)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor ?? AppColors.indigo600,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(action, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
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
        Divider(height: 1, color: AppColors.slate200),
        
        // Form
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormRow('Full Name', _nameCtrl),
              const SizedBox(height: 24),
              _buildFormRow('Email Address', _emailCtrl, isReadOnly: true),
              const SizedBox(height: 24),
              _buildFormRow('Biography', _bioCtrl, maxLines: 3),
            ],
          ),
        ),
        
        Divider(height: 1, color: AppColors.slate200),
        
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThemeCard('Light Mode', true),
                  const SizedBox(width: 24),
                  _buildThemeCard('Dark Mode', false),
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

        const SizedBox(height: 24),
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
        Divider(height: 1, color: AppColors.slate200),
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

  Widget _buildProfileSummaryCard(Map<String, dynamic>? user, String name, String bio, String email) {
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
                  bio.isNotEmpty ? bio : 'Add a short bio about yourself',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: bio.isNotEmpty ? AppColors.slate500 : AppColors.slate400,
                    fontWeight: bio.isNotEmpty ? FontWeight.w500 : FontWeight.w400,
                    fontStyle: bio.isNotEmpty ? FontStyle.normal : FontStyle.italic,
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
          // Edit Profile / Save Changes Buttons
          _isEditing 
            ? Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isEditing = false);
                    },
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Cancel Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.slate100,
                      foregroundColor: AppColors.slate700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveProfileChanges,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isEditing = true);
                },
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                  foregroundColor: Colors.white,
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
                borderSide: BorderSide(color: AppColors.indigo500, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.slate200),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isReadOnly 
                  ? Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.slate400) 
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
      key: ValueKey(modeName),
      onTap: _isEditing ? () => setState(() => _selectedTheme = modeName) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.indigo500 : AppColors.slate200,
            width: 2,
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
                // Use hardcoded colors for theme previews so they don't flip with the app theme
                color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(height: 8, width: 40, decoration: BoxDecoration(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF475569), borderRadius: BorderRadius.circular(4))),
                   const SizedBox(height: 8),
                   Container(height: 8, width: 60, decoration: BoxDecoration(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF475569), borderRadius: BorderRadius.circular(4))),
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

  Future<bool?> _showCurrentDeviceLogoutWarning() {
    return showDialog<bool>(
      context: context,
      builder: (context) => _buildModernDialog(
        icon: Icons.warning_amber_rounded,
        title: 'Logout Current Device?',
        subtitle: 'You are about to log out from this device.',
        content: Text(
          'You will be redirected to the login screen and need to sign in again to access your account.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate600),
        ),
        actions: [
          _buildModernSecondaryButton('Cancel', () => Navigator.pop(context, false)),
          const SizedBox(width: 12),
          _buildModernPrimaryButton('Yes, Log Out', false, () => Navigator.pop(context, true)),
        ],
      ),
    );
  }
}