import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/screens/main_shell.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:progresso/services/security_service.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/services/workspace_service.dart';
import 'package:progresso/services/session_manager.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Entry point widget — manages login / sign-up mode
// ─────────────────────────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _showLogin = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    _fadeCtrl.reverse().then((_) {
      setState(() => _showLogin = !_showLogin);
      _fadeCtrl.forward();
    });
  }

  Future<void> _onAuthSuccess() async {
    // Reset all services first so stale state from a previous session
    // (e.g., demo user) does not bleed into the newly logged-in user.
    GoalService().reset();
    SessionManager().reset();
    WorkspaceService().reset();

    // Now re-initialize with the correct user context
    await SessionManager().init();
    await WorkspaceService().init();
    await GoalService().init();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return _WideLayout(
              showLogin: _showLogin,
              fadeAnim: _fadeAnim,
              onSwitch: _switchMode,
              onAuthSuccess: _onAuthSuccess,
            );
          }
          return _NarrowLayout(
            showLogin: _showLogin,
            fadeAnim: _fadeAnim,
            onSwitch: _switchMode,
            onAuthSuccess: _onAuthSuccess,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide (desktop) layout — split panel
// ─────────────────────────────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final bool showLogin;
  final Animation<double> fadeAnim;
  final VoidCallback onSwitch;
  final VoidCallback onAuthSuccess;

  const _WideLayout({
    required this.showLogin,
    required this.fadeAnim,
    required this.onSwitch,
    required this.onAuthSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left branding panel ──────────────────────────────────────────
        Expanded(
          flex: 5,
          child: _BrandingPanel(),
        ),
        // ── Right auth form panel ────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.white,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 56, vertical: 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: FadeTransition(
                      opacity: fadeAnim,
                      child: showLogin
                          ? LoginForm(
                              onSwitch: onSwitch,
                              onAuthSuccess: onAuthSuccess,
                            )
                          : SignUpForm(
                              onSwitch: onSwitch,
                              onAuthSuccess: onAuthSuccess,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Narrow (mobile / tablet) layout — stacked
// ─────────────────────────────────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final bool showLogin;
  final Animation<double> fadeAnim;
  final VoidCallback onSwitch;
  final VoidCallback onAuthSuccess;

  const _NarrowLayout({
    required this.showLogin,
    required this.fadeAnim,
    required this.onSwitch,
    required this.onAuthSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Compact brand header
          _CompactBrandHeader(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: fadeAnim,
              child: showLogin
                  ? LoginForm(
                      onSwitch: onSwitch,
                      onAuthSuccess: onAuthSuccess,
                    )
                  : SignUpForm(
                      onSwitch: onSwitch,
                      onAuthSuccess: onAuthSuccess,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding panel (left side, desktop)
// ─────────────────────────────────────────────────────────────────────────────
class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3730A3), // indigo-800
            Color(0xFF5048E5), // primary
            Color(0xFF6366F1), // indigo-500
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -80,
            left: -80,
            child: _GlowCircle(size: 320, opacity: 0.07),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _GlowCircle(size: 260, opacity: 0.07),
          ),
          Positioned(
            top: 200,
            right: -40,
            child: _GlowCircle(size: 180, opacity: 0.05),
          ),
          // Content — scrollable to prevent overflow on smaller windows
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(56),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 112,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bolt,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'PROGRESSO',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Main content block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero text
                        Text(
                          'Focus.\nTrack.\nAchieve.',
                          style: GoogleFonts.inter(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your personal productivity command center.\nBuild lasting habits, crush your goals, and\nunderstand your focus patterns deeply.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.75),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Feature pills
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: const [
                            _FeaturePill(icon: Icons.track_changes, label: 'Focus Tracking'),
                            _FeaturePill(icon: Icons.flag_outlined, label: 'Goal Management'),
                            _FeaturePill(icon: Icons.bar_chart, label: 'Deep Analytics'),
                            _FeaturePill(icon: Icons.group_outlined, label: 'Community'),
                          ],
                        ),
                        const SizedBox(height: 48),
                        // Testimonial
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote,
                                  color: Colors.white, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Progresso helped me triple my deep work hours in just 3 weeks. The focus analytics are genuinely eye-opening.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.6,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                    child: const Center(
                                      child: Text('AR',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Alex R. · Product Designer',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact brand header (narrow/mobile)
// ─────────────────────────────────────────────────────────────────────────────
class _CompactBrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3730A3), Color(0xFF5048E5), Color(0xFF6366F1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'PROGRESSO',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your productivity command center',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN FORM
// ─────────────────────────────────────────────────────────────────────────────
class LoginForm extends StatefulWidget {
  final VoidCallback onSwitch;
  final VoidCallback onAuthSuccess;

  const LoginForm({
    super.key,
    required this.onSwitch,
    required this.onAuthSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 2FA state
  bool _show2FA = false;
  Map<String, dynamic>? _pendingUser;
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final response = await AuthService().login(
        _emailCtrl.text,
        _passCtrl.text,
      );
      
      if (!mounted) return;

      if (response != null) {
        if (response is Map && response['mfaRequired'] == true) {
          setState(() {
            _show2FA = true;
            _pendingUser = response as Map<String, dynamic>;
            _isLoading = false;
          });
          return;
        }
        widget.onAuthSuccess();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }


  Future<void> _verifyOTP() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final email = _pendingUser?['email'] ?? '';
    final userMap = await AuthService().verifyLogin2fa(email, _otpCtrl.text);
    
    if (userMap != null) {
      widget.onAuthSuccess();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid verification code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_show2FA) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => setState(() => _show2FA = false),
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Text(
            'Two-Factor Verification',
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.slate900),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code from your authenticator app.',
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.slate500),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],
          _AuthTextField(
            controller: _otpCtrl,
            hint: '000000',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.security_rounded,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Verify & Login',
            isLoading: _isLoading,
            onTap: _verifyOTP,
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Text(
            'Welcome back',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue to PROGRESSO',
            style: GoogleFonts.inter(
                fontSize: 15, color: AppColors.slate500),
          ),
          const SizedBox(height: 32),

          // ── Google Sign In ───────────────────────────────────────────────
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Sign-In coming soon!')),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.slate200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.slate200)),
            ],
          ),
          
          const SizedBox(height: 24),

          // ── Error banner ─────────────────────────────────────────────────
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],

          // ── Email ────────────────────────────────────────────────────────
          _AuthLabel('Email address'),
          const SizedBox(height: 6),
          _AuthTextField(
            controller: _emailCtrl,
            hint: 'you@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Password ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AuthLabel('Password'),
              TextButton(
                onPressed: () {
                  // TODO: forgot password flow
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.indigo600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _AuthTextField(
            controller: _passCtrl,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.slate400,
              ),
              onPressed: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Submit ───────────────────────────────────────────────────────
          _PrimaryButton(
            label: 'Sign In',
            isLoading: _isLoading,
            onTap: _submit,
          ),
          const SizedBox(height: 24),

          // ── Switch ───────────────────────────────────────────────────────
          _SwitchLink(
            question: "Don't have an account?",
            action: 'Sign up',
            onTap: widget.onSwitch,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGN-UP FORM
// ─────────────────────────────────────────────────────────────────────────────
class SignUpForm extends StatefulWidget {
  final VoidCallback onSwitch;
  final VoidCallback onAuthSuccess;

  const SignUpForm({
    super.key,
    required this.onSwitch,
    required this.onAuthSuccess,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().register(
        _nameCtrl.text,
        _emailCtrl.text,
        _passCtrl.text,
      );
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to login screen
      widget.onSwitch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Text(
            'Create account',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your productivity journey today',
            style: GoogleFonts.inter(
                fontSize: 15, color: AppColors.slate500),
          ),
          const SizedBox(height: 32),

          // ── Google Sign Up ───────────────────────────────────────────────
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Sign-In coming soon!')),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign up with Google',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.slate200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.slate200)),
            ],
          ),
          
          const SizedBox(height: 24),

          // ── Error banner ─────────────────────────────────────────────────
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],

          // ── Full Name ────────────────────────────────────────────────────
          _AuthLabel('Full Name'),
          const SizedBox(height: 6),
          _AuthTextField(
            controller: _nameCtrl,
            hint: 'Jane Smith',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Full name is required';
              if (v.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Email ────────────────────────────────────────────────────────
          _AuthLabel('Email address'),
          const SizedBox(height: 6),
          _AuthTextField(
            controller: _emailCtrl,
            hint: 'you@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Password ─────────────────────────────────────────────────────
          _AuthLabel('Password'),
          const SizedBox(height: 6),
          _AuthTextField(
            controller: _passCtrl,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePass,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.slate400,
              ),
              onPressed: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Confirm Password ─────────────────────────────────────────────
          _AuthLabel('Confirm Password'),
          const SizedBox(height: 6),
          _AuthTextField(
            controller: _confirmCtrl,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.slate400,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Submit ───────────────────────────────────────────────────────
          _PrimaryButton(
            label: 'Create Account',
            isLoading: _isLoading,
            onTap: _submit,
          ),
          const SizedBox(height: 24),

          // ── Switch ───────────────────────────────────────────────────────
          _SwitchLink(
            question: 'Already have an account?',
            action: 'Log in',
            onTap: widget.onSwitch,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small components
// ─────────────────────────────────────────────────────────────────────────────

// Label
class _AuthLabel extends StatelessWidget {
  final String text;
  const _AuthLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.slate700,
      ),
    );
  }
}

// Text field
class _AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
   final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextAlign textAlign;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textAlign = TextAlign.start,
  });

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        textAlign: widget.textAlign,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.slate900,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 14, color: AppColors.slate400),
          prefixIcon: Icon(
            widget.prefixIcon,
            size: 18,
            color: _focused ? AppColors.indigo500 : AppColors.slate400,
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: _focused ? AppColors.indigo50 : AppColors.slate50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.slate200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.indigo500, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.rose500, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.rose500, width: 2),
          ),
          errorStyle: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.rose600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


// Error banner
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.rose50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.rose100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.rose500, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.rose600, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Primary CTA button
class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: _hovered
                ? [const Color(0xFF3730A3), const Color(0xFF5048E5)]
                : [const Color(0xFF5048E5), const Color(0xFF6366F1)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: _hovered ? 0.3 : 0.18),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Switch link (log in / sign up)
class _SwitchLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const _SwitchLink({
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.slate500),
          children: [
            TextSpan(text: '$question '),
            WidgetSpan(
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
