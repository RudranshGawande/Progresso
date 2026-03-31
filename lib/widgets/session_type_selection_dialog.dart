import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/theme/app_colors.dart';

class SessionTypeSelectionDialog extends StatefulWidget {
  final Goal goal;
  final GoalTask task;
  final Function(FocusSessionType type, int durationSeconds) onSelect;

  const SessionTypeSelectionDialog({
    Key? key,
    required this.goal,
    required this.task,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<SessionTypeSelectionDialog> createState() =>
      _SessionTypeSelectionDialogState();
}

class _SessionTypeSelectionDialogState extends State<SessionTypeSelectionDialog>
    with SingleTickerProviderStateMixin {
  FocusSessionType _selectedType = FocusSessionType.timed;
  int _selectedDurationSeconds = 60 * 60;
  bool _isCustomMode = false;
  bool _isManualInput = false;
  
  int _customHours = 0;
  int _customMinutes = 20;
  final TextEditingController _customHoursController = TextEditingController(text: '0');
  final TextEditingController _customMinutesController = TextEditingController(text: '20');

  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  final List<({FocusSessionType type, String label, IconData icon})> _types = [
    (type: FocusSessionType.timed, label: 'Timed', icon: Icons.timer_outlined),
    (type: FocusSessionType.free, label: 'Free Flow', icon: Icons.all_inclusive_rounded),
  ];

  final List<int> _durationSeconds = [
    15 * 60,
    25 * 60,
    45 * 60,
    60 * 60,
    90 * 60,
    120 * 60,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.10),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _isCustomMode ? _buildCustomPickerBody() : _buildMainBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBody() {
    return Column(
      key: const ValueKey('main'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header with gradient accent ───
        _buildHeader(),

        // ─── Body content ───
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Session Type
              _buildSectionLabel('Session Type', Icons.category_rounded),
              const SizedBox(height: 12),
              _buildSessionTypeSelector(),

              // Duration (animated)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _selectedType == FocusSessionType.timed
                    ? _buildDurationSection()
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 28),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomPickerBody() {
    return Column(
      key: const ValueKey('custom'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCustomHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('Set Custom Time', Icons.history_edu_rounded),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (!_isManualInput) {
                          // Switching to manual - sync minutes and hours to controllers
                          _customHoursController.text = _customHours.toString();
                          _customMinutesController.text = _customMinutes.toString();
                        } else {
                          // Switching to wheel - sync back from controllers
                          _customHours = (int.tryParse(_customHoursController.text) ?? 0).clamp(0, 12);
                          _customMinutes = (int.tryParse(_customMinutesController.text) ?? 0).clamp(0, 59);
                        }
                        _isManualInput = !_isManualInput;
                      });
                    },
                    icon: Icon(
                      _isManualInput ? Icons.tune_rounded : Icons.keyboard_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Switch Input Mode',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isManualInput ? _buildManualTimerInput() : _buildWheelTimerInput(),
              ),
              const SizedBox(height: 32),
              _buildCustomActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheelTimerInput() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Selection Indicator
          Positioned(
            left: 12,
            right: 12,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              _buildSizingPicker(
                value: _customHours,
                max: 12,
                label: 'h',
                onChanged: (v) => setState(() => _customHours = v),
              ),
              const SizedBox(width: 40),
              // Minutes
              _buildSizingPicker(
                value: _customMinutes,
                max: 59,
                label: 'm',
                onChanged: (v) => setState(() => _customMinutes = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizingPicker({
    required int value,
    required int max,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 80,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 44,
        diameterRatio: 1.2,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        controller: FixedExtentScrollController(initialItem: value),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: max + 1,
          builder: (context, index) {
            final isSelected = index == value;
            return Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    index.toString().padLeft(1, '0'),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.slate400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary.withOpacity(0.7) : AppColors.slate300,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildManualTimerInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Hours Input
          _buildManualField(_customHoursController, 'hours', 'h'),
          
          // Separator
          Container(
            height: 30,
            width: 1,
            color: AppColors.slate200,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          
          // Minutes Input
          _buildManualField(_customMinutesController, 'minutes', 'm'),
        ],
      ),
    );
  }

  Widget _buildManualField(TextEditingController controller, String hint, String unit) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 45,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.slate400,
              letterSpacing: 0.5,
              textStyle: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.indigo500.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Decorative icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.indigo500],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Session',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 14,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        widget.task.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.indigo500.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.indigo500],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_fix_high_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Timer',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define your focus duration',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.slate400),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate400,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _types.map((entry) {
          final isSelected = entry.type == _selectedType;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = entry.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry.icon,
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.slate400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionLabel('Duration', Icons.schedule_rounded),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: _durationSeconds.map((secs) {
            final isSelected = secs == _selectedDurationSeconds && !_isCustomMode;
            final mins = secs ~/ 60;
            return _buildDurationCard(mins, isSelected, () {
              setState(() {
                _selectedDurationSeconds = secs;
                _isCustomMode = false;
              });
            });
          }).toList(),
        ),
        const SizedBox(height: 10),
        _buildCustomTriggerCard(),
      ],
    );
  }

  Widget _buildDurationCard(int mins, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.emerald500, AppColors.emerald600],
                )
              : null,
          color: isSelected ? null : AppColors.slate50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.emerald500 : AppColors.slate200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.emerald500.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$mins',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.slate700,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'min',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTriggerCard() {
    return GestureDetector(
      onTap: () => setState(() => _isCustomMode = true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20, color: AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              'Custom focus duration',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCustomActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => setState(() => _isCustomMode = false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.slate200),
              ),
            ),
            child: Text(
              'Back',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              int totalSecs;
              if (_isManualInput) {
                final h = int.tryParse(_customHoursController.text) ?? 0;
                final m = int.tryParse(_customMinutesController.text) ?? 0;
                totalSecs = (h * 3600) + (m * 60);
              } else {
                totalSecs = (_customHours * 3600) + (_customMinutes * 60);
              }
              
              if (totalSecs <= 0) totalSecs = 15 * 60; // Min 15 mins default
              widget.onSelect(FocusSessionType.timed, totalSecs);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Set Countdown',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel button
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.slate200),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Confirm button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              final durSecs = _selectedType == FocusSessionType.timed
                  ? _selectedDurationSeconds
                  : 0;
              widget.onSelect(_selectedType, durSecs);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Start Session',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
