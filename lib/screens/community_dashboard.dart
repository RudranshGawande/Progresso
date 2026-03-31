import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../models/workspace_models.dart';
import '../widgets/responsive.dart';
import '../widgets/focus_intensity.dart';
import '../widgets/weekly_chart.dart';

class CommunityDashboard extends StatelessWidget {
  final Community community;

  const CommunityDashboard({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCards(context),
            const SizedBox(height: 24),
            const _FocusIntensityCard(),
            const SizedBox(height: 24),
            const _WorkloadCard(),
            const SizedBox(height: 24),
            _MemberActivityCard(community: community),
            const SizedBox(height: 24),
            _ActiveSessionsCard(community: community),
            const SizedBox(height: 24),
            const _CommunityGoalsCard(),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stat cards ──────────────────────────────────
        _buildStatCards(context),

        const SizedBox(height: 32),

        // ── Main Layout (Two Column) ──────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Wider - flex 2)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const _FocusIntensityCard(),
                  const SizedBox(height: 32),
                  _MemberActivityCard(community: community),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Column (Narrower - flex 1)
            Expanded(
              child: Column(
                children: [
                  const _WorkloadCard(),
                  const SizedBox(height: 32),
                  _ActiveSessionsCard(community: community),
                  const SizedBox(height: 32),
                  const _CommunityGoalsCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    final cards = [
      StatCard(
        icon: Icons.timer_outlined,
        iconColor: AppColors.primary,
        iconBgColor: Color(0xFFEEF2FF),
        trend: '+14%',
        trendColor: AppColors.emerald500,
        trendIcon: Icons.trending_up,
        metric: 'Total Team Focus Hours',
        value: '1,240h',
      ),
      StatCard(
        icon: Icons.group_outlined,
        iconColor: Color(0xFF6366F1),
        iconBgColor: Color(0xFFEEF2FF),
        trend: 'Static',
        trendColor: AppColors.slate400,
        metric: 'Active Members',
        value: '${community.members.length}',
      ),
      StatCard(
        icon: Icons.layers_outlined,
        iconColor: Colors.orange,
        iconBgColor: Color(0xFFFFF7ED),
        trend: '+8%',
        trendColor: AppColors.emerald500,
        trendIcon: Icons.trending_up,
        metric: 'Total Sessions',
        value: '45',
      ),
      StatCard(
        icon: Icons.emoji_events_outlined,
        iconColor: AppColors.emerald500,
        iconBgColor: Color(0xFFECFDF5),
        trend: 'Peak',
        trendColor: AppColors.emerald500,
        metric: 'Productivity Score',
        value: '88/100',
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: c,
        )).toList(),
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

}

class _FocusIntensityCard extends StatelessWidget {
  const _FocusIntensityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Focus Intensity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                  Text(
                    'Daily productivity peaks (last 7 days)',
                    style: TextStyle(fontSize: 14, color: AppColors.slate500),
                  ),
                ],
              ),
              Icon(Icons.more_horiz, color: AppColors.slate400),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _TeamIntensityPainter(),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, Color(0xFF818CF8)],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Actual Data',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var day in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'])
                Text(day, style: TextStyle(fontSize: 12, color: AppColors.slate400, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamIntensityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = AppColors.slate100
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const int gridRows = 4;
    for (int i = 0; i <= gridRows; i++) {
        final y = size.height * (i / gridRows);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.65),
      Offset(size.width * 0.3, size.height * 0.4),
      Offset(size.width * 0.45, size.height * 0.8),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.75, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      Offset(size.width, size.height * 0.3),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    // Area paint
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();
    canvas.drawPath(areaPath, areaPaint);

    // Stroke paint with gradient
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary, Color(0xFF818CF8), Color(0xFFC084FC)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Draw peak markers
    final markerFillPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final markerBorderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 1; i < points.length - 1; i++) {
      // Only draw on significant peaks
      if (points[i].dy < points[i-1].dy && points[i].dy < points[i+1].dy) {
        canvas.drawCircle(points[i], 5, markerFillPaint);
        canvas.drawCircle(points[i], 5, markerBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WorkloadCard extends StatelessWidget {
  const _WorkloadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workload',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          Text(
            'Weekly Distribution',
            style: TextStyle(fontSize: 14, color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildHorizontalBar('ALEX', 0.85),
              const SizedBox(height: 16),
              _buildHorizontalBar('RAHUL', 0.70),
              const SizedBox(height: 16),
              _buildHorizontalBar('SARA', 0.92),
              const SizedBox(height: 16),
              _buildHorizontalBar('JOHN', 0.45),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBar(String label, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate400)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate500)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberActivityCard extends StatelessWidget {
  final Community community;
  const _MemberActivityCard({required this.community});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Member Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              Text(
                'View All',
                style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityHeader(),
          const SizedBox(height: 16),
          for (var i = 0; i < community.members.length && i < 3; i++) ...[
            _buildMemberRow(community.members[i], i),
            if (i < 2) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('TEAM MEMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.8))),
          Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.8))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.8))),
          Expanded(flex: 2, child: Text("TODAY'S HOURS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.8))),
        ],
      ),
    );
  }

  Widget _buildMemberRow(CommunityMember member, int index) {
    // Mock data based on index/member for demo
    final roles = ['ADMIN', 'MEMBER', 'MEMBER'];
    final statuses = ['Active', 'Focused', 'Offline'];
    final statusColors = [AppColors.emerald500, Colors.orange, AppColors.slate400];
    final hours = ['6.5h', '8.2h', '4.0h'];

    final String currentStatus = statuses[index % statuses.length];
    final Color currentStatusColor = statusColors[index % statusColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Team Member
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.slate100, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(member.avatarUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name, 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900)
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email, 
                        style: TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w400)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Role
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roles[index % roles.length] == 'ADMIN' 
                      ? AppColors.indigo50 
                      : AppColors.slate50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: roles[index % roles.length] == 'ADMIN' 
                        ? AppColors.indigo100 
                        : AppColors.slate100
                    ),
                  ),
                  child: Text(
                    roles[index % roles.length],
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w700, 
                      color: roles[index % roles.length] == 'ADMIN' 
                        ? AppColors.primary 
                        : AppColors.slate600,
                      letterSpacing: 0.5
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: currentStatusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentStatus,
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.w600, 
                          color: currentStatusColor
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Today's Hours
          Expanded(
            flex: 2,
            child: Text(
              hours[index % hours.length],
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w800, 
                color: AppColors.slate900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionsCard extends StatelessWidget {
  final Community community;
  const _ActiveSessionsCard({required this.community});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Active Sessions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (community.communitySessions.isEmpty)
             Text('No active sessions', style: TextStyle(color: AppColors.slate400))
          else
            for (var session in community.communitySessions.take(2)) ...[
              _buildSessionItem(session),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _buildSessionItem(Session session) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          const SizedBox(height: 4),
          Text(
            '${session.assignments.where((a) => a.status == AssignmentStatus.inProgress).length + 2} Members active',
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < session.memberAvatars.take(3).length; i++)
                Align(
                  widthFactor: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(session.memberAvatars[i]),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityGoalsCard extends StatelessWidget {
  const _CommunityGoalsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch, size: 24, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Community Goals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildGoalItem('Q3 RESEARCH PAPER', 0.70),
          const SizedBox(height: 20),
          _buildGoalItem('OPEN SOURCE CONTRIBS', 0.49),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Contribute Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}