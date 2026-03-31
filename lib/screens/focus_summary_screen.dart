import 'package:flutter/material.dart';

import '../models/goal_models.dart';
import '../theme/app_colors.dart';
import '../services/goal_service.dart';

class FocusSummaryScreen extends StatelessWidget {
  final Goal goal;
  final GoalTask task;
  final FocusSession session;

  const FocusSummaryScreen({
    super.key,
    required this.goal,
    required this.task,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background blurred mockup feel
          _buildBackgroundMockup(),
          
          // Main Overlay
          Container(
            color: Colors.black.withOpacity(0.1),
            child: BackdropFilter(
              filter: ColorFilter.mode(Colors.black.withOpacity(0.05), BlendMode.darken),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildSummaryCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundMockup() {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            width: 288,
            height: 288,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            width: 384,
            height: 384,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildMetricsGrid(),
          _buildFocusTrend(),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Session Complete',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: AppColors.slate400)),
              ),
              Text(
                task.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.slate100),
          bottom: BorderSide(color: AppColors.slate100),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildMetricItem('TOTAL DURATION', _formatDuration(session.duration))),
          Container(width: 1, height: 100, color: AppColors.slate100),
          Expanded(child: _buildIntensityMetric()),
          Container(width: 1, height: 100, color: AppColors.slate100),
          Expanded(child: _buildMetricItem('FOCUS SCORE', '${session.focusScore}', suffix: '/100', isPrimary: true)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {String? suffix, bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.slate400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isPrimary ? FontWeight.w900 : FontWeight.bold,
                  color: isPrimary ? AppColors.primary : AppColors.slate900,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityMetric() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'INTENSITY',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.slate400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: session.intensity,
                  strokeWidth: 5,
                  backgroundColor: AppColors.slate50,
                  color: AppColors.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(session.intensity * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTrend() {
    // Generate trend bars. If trendData is empty, use mock/random data for visualization
    List<double> data = session.trendData.isNotEmpty ? session.trendData : [0.4, 0.6, 0.55, 0.85, 0.92, 0.95, 0.88, 0.94, 0.92, 0.7, 0.5, 0.8, 0.96, 0.98, 0.9];
    
    // Ensure at least 15 bars for consistent look
    if (data.length > 15) {
      // Sample 15 points
      data = List.generate(15, (i) => data[(i * data.length / 15).floor()]);
    } else if (data.length < 15 && data.isNotEmpty) {
       // repeat last point
       while(data.length < 15) { data.add(data.last); }
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus Trend',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('FOCUS LEVEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                final val = data[index];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _AnimatedTrendBar(
                      value: val,
                      delayIndex: index,
                      color: AppColors.primary.withOpacity(_getOpacityForVal(val)),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('START', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate400)),
              Text('22M', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate400)),
              Text('FINISH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate400)),
            ],
          ),
        ],
      ),
    );
  }

  double _getOpacityForVal(double val) {
    if (val > 0.9) return 1.0;
    if (val > 0.8) return 0.8;
    if (val > 0.6) return 0.6;
    if (val > 0.4) return 0.4;
    return 0.2;
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.slate50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
               Navigator.pop(context);
            },
            child: Text(
              'Keep Task Active',
              style: TextStyle(color: AppColors.slate600, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
               _archiveTask(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.25),
            ),
            icon: const Text('Complete Task & Archive', style: TextStyle(fontWeight: FontWeight.bold)),
            label: const Icon(Icons.check_circle_outline, size: 16),
          ),
        ],
      ),
    );
  }

  void _archiveTask(BuildContext context) {
    GoalService().toggleTaskCompletion(goal.id, task.id);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task marked as completed'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration d) {
    int mins = d.inMinutes;
    int secs = d.inSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }
}

class _AnimatedTrendBar extends StatefulWidget {
  final double value;
  final int delayIndex;
  final Color color;

  const _AnimatedTrendBar({
    required this.value,
    required this.delayIndex,
    required this.color,
  });

  @override
  State<_AnimatedTrendBar> createState() => _AnimatedTrendBarState();
}

class _AnimatedTrendBarState extends State<_AnimatedTrendBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Stagger the animation start based on index
    Future.delayed(Duration(milliseconds: 50 * widget.delayIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            height: _animation.value * 120,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.primary : widget.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              boxShadow: _isHovered ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4)
              ] : null,
            ),
          );
        },
      ),
    );
  }
}