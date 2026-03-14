import 'dart:async';

import 'package:flutter/material.dart';
import '../models/goal_models.dart';
import '../theme/app_colors.dart';
import 'focus_summary_screen.dart';
import '../services/session_manager.dart';
import '../services/goal_service.dart';

class FocusSessionScreen extends StatefulWidget {
  final Goal goal;
  final GoalTask task;
  final int? targetSeconds; // Null for free session

  const FocusSessionScreen({
    super.key,
    required this.goal,
    required this.task,
    this.targetSeconds,
  });

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> with TickerProviderStateMixin {
  late int _elapsedSeconds;
  late int? _targetSeconds;
  bool _isPaused = false;
  bool _didNotifyTargetReached = false;
  Timer? _timer;

  // Analytics
  int _pauseCount = 0;
  int _totalPausedSeconds = 0;
  DateTime? _pauseStartTime;

  
  double _intensity = 1.0; // 0.0 to 1.0
  final List<double> _trendData = [];
  Timer? _trendTimer;

  @override
  void initState() {
    super.initState();
    final persistentSession = SessionManager().getSessionForTask(widget.task.id);
    
    if (persistentSession != null) {
      _isPaused = persistentSession.status == SessionStatus.paused;
      final elapsed = SessionManager().getElapsedTime(widget.task.id);
      _elapsedSeconds = elapsed.inSeconds;
      _targetSeconds = persistentSession.totalDuration != null 
          ? persistentSession.totalDuration! ~/ 1000 
          : widget.targetSeconds;
      _targetSeconds = persistentSession.totalDuration != null 
          ? persistentSession.totalDuration! ~/ 1000 
          : widget.targetSeconds;
      
      if (_isPaused) {
        _pauseStartTime = persistentSession.pausedAt;
      }
    } else {
      _elapsedSeconds = 0;
      _targetSeconds = widget.targetSeconds;
      SessionManager().startSession(
        widget.task.id, 
        widget.goal.id, 
        totalDuration: widget.targetSeconds != null ? widget.targetSeconds! * 1000 : null,
      );
    }
    
    _startTimer();
    _startTrendCollection();
  }

  void _startTrendCollection() {
    // Collect intensity every 5 seconds for the trend graph
    _trendTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isPaused) {
        _trendData.add(_intensity);
      } else {
        _trendData.add(0.2); // Low intensity when paused
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          
          if (_targetSeconds != null && _elapsedSeconds >= _targetSeconds! && !_didNotifyTargetReached) {
            _didNotifyTargetReached = true;
            _notifyTargetReached();
          }

          _calculateIntensity();
        });
      }
    });
  }

  void _notifyTargetReached() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Target of ${widget.targetSeconds! ~/ 60}m reached!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.emerald600,
      ),
    );
  }

  void _calculateIntensity() {
    final int focusedSeconds = _elapsedSeconds;

    if (focusedSeconds == 0) {
      _intensity = 1.0;
      return;
    }

    // High fidelity intensity logic
    // 1. Percentage of time actually focused (vs paused)
    double timeRatio = focusedSeconds / (focusedSeconds + _totalPausedSeconds);
    
    // 2. Penalty for freqency of interruptions (switching out of flow)
    // Every pause costs 3% of potential intensity
    double interruptionPenalty = _pauseCount * 0.03;
    
    double calculatedIntensity = (timeRatio - interruptionPenalty);

    setState(() {
      _intensity = calculatedIntensity.clamp(0.4, 1.0); // Floor at 40%
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pauseCount++;
        _pauseStartTime = DateTime.now();
        SessionManager().pauseSession(widget.task.id);
      } else {
        if (_pauseStartTime != null) {
          _totalPausedSeconds += DateTime.now().difference(_pauseStartTime!).inSeconds;
          _pauseStartTime = null;
        }
        SessionManager().resumeSession(widget.task.id);
      }
      _calculateIntensity();
    });
  }

  void _stopSession() {
    _timer?.cancel();
    _trendTimer?.cancel();
    _finishSession();
  }

  void _finishSession() {
    final int focusedSeconds = _elapsedSeconds;

    // Calculate final focus score (Intensity * 100 with small penalty for pauses)
    int focusScore = ((_intensity * 100) - (_pauseCount * 2)).toInt();
    focusScore = focusScore.clamp(0, 100);

    // Create session object
    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      duration: Duration(seconds: focusedSeconds),
      intensity: _intensity,
      focusScore: focusScore,
      trendData: _trendData,
      timestamp: DateTime.now(),
    );

    // Persist session to goal
    GoalService().addSessionToTask(widget.goal.id, widget.task.id, session);
    
    // Cleanup active session
    SessionManager().completeSession(widget.task.id);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FocusSummaryScreen(
          goal: widget.goal,
          task: widget.task,
          session: session,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _trendTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _targetSeconds != null 
        ? (_elapsedSeconds / _targetSeconds!).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimerRing(progress),
                      const SizedBox(height: 48),
                      _buildIntensityIndicator(),
                      const SizedBox(height: 32),
                      _buildTaskInfo(),
                      const SizedBox(height: 48),
                      _buildControls(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooterNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerRing(double progress) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          SizedBox(
            width: 300,
            height: 300,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              color: AppColors.slate100,
            ),
          ),
          // Progress Circle
          SizedBox(
            width: 300,
            height: 300,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: progress, end: progress),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  color: _isPaused ? AppColors.emerald600 : AppColors.primary,
                );
              },
            ),
          ),
          // Time Text
          Text(
            _formatTime(_elapsedSeconds),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityIndicator() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(color: _isPaused ? AppColors.slate300 : AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'DEEP WORK INTENSITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_intensity * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _intensity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskInfo() {
    return Column(
      children: [
        Text(
          widget.task.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.slate800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gps_fixed, size: 14, color: AppColors.slate400),
            const SizedBox(width: 8),
            Text(
              widget.goal.title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          label: _isPaused ? 'Resume' : 'Pause',
          icon: _isPaused ? Icons.play_arrow : Icons.pause,
          color: _isPaused ? AppColors.emerald600 : AppColors.primary,
          onPressed: _togglePause,
        ),
        const SizedBox(width: 16),
        _ControlButton(
          label: 'Stop Session',
          icon: Icons.stop_circle_outlined,
          color: Colors.white,
          textColor: AppColors.slate600,
          borderColor: AppColors.slate200,
          onPressed: _stopSession,
        ),
      ],
    );
  }

  Widget _buildFooterNav() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Exit to Dashboard',
            style: TextStyle(
              color: AppColors.slate400,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutline = borderColor != null;

    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOutline ? BorderSide(color: borderColor!) : BorderSide.none,
        ),
        elevation: isOutline ? 0 : 4,
        shadowColor: isOutline ? null : color.withOpacity(0.3),
        minimumSize: const Size(160, 56),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.8, end: 0.0).animate(_controller),
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 2.5).animate(_controller),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
