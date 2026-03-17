import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/theme/theme_notifier.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _nameCtrl = TextEditingController(text: user?['name'] ?? 'Google User');
    _emailCtrl = TextEditingController(text: user?['email'] ?? 'Unknown');
    _bioCtrl = TextEditingController(text: user?['bio'] ?? 'Product Designer based in San Francisco');
    _imageUrl = user?['imageUrl'];
    
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
  String _getAvatarUrl(String email) {
    if (_imageUrl != null && _imageUrl!.isNotEmpty) return _imageUrl!;
    if (email.isEmpty) return 'https://www.gravatar.com/avatar/?d=mp';
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = md5.convert(bytes);
    return 'https://www.gravatar.com/avatar/$digest?d=mp&s=200';
  }

  void _showImageUpdateDialog() {
    final TextEditingController urlCtrl = TextEditingController(text: _imageUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Image'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter image URL',
            labelText: 'Image URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _imageUrl = urlCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Set Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive) {
    return Container(
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
                      _buildSidebarItem(Icons.person_outline_rounded, 'Personal Information', true),
                      _buildSidebarItem(Icons.settings_outlined, 'Account Settings', false),
                      _buildSidebarItem(Icons.lock_outline_rounded, 'Security', false),
                      _buildSidebarItem(Icons.work_outline_rounded, 'Workspaces & Communities', false),
                      _buildSidebarItem(Icons.notifications_none_rounded, 'Notifications', false),
                      _buildSidebarItem(Icons.credit_card_rounded, 'Billing / Subscription', false),
                      _buildSidebarItem(Icons.history_rounded, 'Activity History', false),
                      _buildSidebarItem(Icons.extension_outlined, 'Connected Integrations', false),
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

                // Main Content Form
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
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
                    ),
                  ),
                ),
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
                  image: DecorationImage(
                    image: NetworkImage(_getAvatarUrl(email)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isEditing ? _showImageUpdateDialog : null,
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
