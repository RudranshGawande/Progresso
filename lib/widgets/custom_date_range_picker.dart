import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:progresso/theme/app_colors.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;

  const CustomDateRangePicker({super.key, this.initialRange});

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _currentMonth;
  String _activeShortcut = 'Custom range';

  final DateTime _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  final List<String> _shortcuts = [
    'Last 7 days',
    'Last 30 days',
    'Latest month',
    'Previous month',
    'Custom range',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
      _endDate = widget.initialRange!.end;
    }
    // Always start on the current month
    _currentMonth = DateTime(_today.year, _today.month);
  }

  void _applyShortcut(String shortcut) {
    setState(() {
      _activeShortcut = shortcut;
      switch (shortcut) {
        case 'Last 7 days':
          _startDate = _today.subtract(const Duration(days: 6));
          _endDate = _today;
          break;
        case 'Last 30 days':
          _startDate = _today.subtract(const Duration(days: 29));
          _endDate = _today;
          break;
        case 'Latest month':
          _startDate = DateTime(_today.year, _today.month, 1);
          _endDate = _today;
          break;
        case 'Previous month':
          _startDate = DateTime(_today.year, _today.month - 1, 1);
          _endDate = DateTime(_today.year, _today.month, 0);
          break;
        case 'Custom range':
          break;
      }
      // Navigate calendar to the start date's month
      if (_startDate != null) {
        _currentMonth = DateTime(_startDate!.year, _startDate!.month);
      }
    });
  }

  void _handleDateTap(DateTime date) {
    // Disallow future dates
    if (date.isAfter(_today)) return;

    setState(() {
      _activeShortcut = 'Custom range';
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start fresh selection
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (date.isBefore(_startDate!)) {
          // Swap: selected before start
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    // Don't allow navigating into the future beyond current month
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (nextMonth.isAfter(_today)) return;
    setState(() {
      _currentMonth = nextMonth;
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    // Reserve space for header (~62), footer (~70), dividers (~4), insets (~64)
    final bodyH = (screenH - 200.0).clamp(180.0, 400.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxWidth: 720),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select date range',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: AppColors.slate400, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.slate100),

            // ── Body ─────────────────────────────────────────────────────
            SizedBox(
              height: bodyH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Sidebar: Quick Select
                  SizedBox(
                    width: 170,
                    child: SingleChildScrollView(child: _buildShortcutsList()),
                  ),
                  VerticalDivider(width: 1, color: AppColors.slate100),
                  // Single Calendar — scrollable so it never overflows
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _buildMonthCalendar(),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.slate100),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDateInputs(),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: _shortcuts.map((shortcut) {
          final isActive = _activeShortcut == shortcut;
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: () => _applyShortcut(shortcut),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withOpacity(0.09) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shortcut,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.slate600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthCalendar() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1=Mon..7=Sun
    final previousMonthDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    // Sunday first: Mon returns 1 → offset 1, Sun returns 7 → offset 0
    final startOffset = firstWeekday % 7;

    final isCurrentMonth = _currentMonth.year == _today.year &&
        _currentMonth.month == _today.month;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month navigation header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: _previousMonth,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.chevron_left, color: AppColors.slate500, size: 20),
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            // Hide right arrow when we're already on the current month
            InkWell(
              onTap: isCurrentMonth ? null : _nextMonth,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right,
                  color: isCurrentMonth ? AppColors.slate200 : AppColors.slate500,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Weekday headers
        Row(
          children: ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'].map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // Days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 0,
            childAspectRatio: 1.5,
          ),
          itemCount: 42, // 6 rows × 7 cols
          itemBuilder: (context, index) {
            DateTime date;
            bool isCurrentMonthDay = true;

            if (index < startOffset) {
              isCurrentMonthDay = false;
              date = DateTime(_currentMonth.year, _currentMonth.month - 1,
                  previousMonthDays - startOffset + index + 1);
            } else if (index >= startOffset + daysInMonth) {
              isCurrentMonthDay = false;
              date = DateTime(_currentMonth.year, _currentMonth.month + 1,
                  index - (startOffset + daysInMonth) + 1);
            } else {
              date = DateTime(
                  _currentMonth.year, _currentMonth.month, index - startOffset + 1);
            }

            final isFuture = date.isAfter(_today);
            final isToday = _isSameDay(date, _today);
            final isStart = _isSameDay(date, _startDate);
            final isEnd = _isSameDay(date, _endDate);
            final isSingleDay = isStart && _endDate == null;

            bool isBetween = false;
            if (_startDate != null && _endDate != null) {
              isBetween = date.isAfter(_startDate!) && date.isBefore(_endDate!);
            }

            // Build decoration
            BoxDecoration decoration = const BoxDecoration();
            Color textColor;
            FontWeight fontWeight = FontWeight.w500;

            if (isFuture || !isCurrentMonthDay) {
              textColor = AppColors.slate300;
            } else {
              textColor = AppColors.slate800;
            }

            if (!isFuture) {
              if (isSingleDay && isStart) {
                decoration = BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                );
                textColor = AppColors.white;
                fontWeight = FontWeight.w700;
              } else if (isStart && isEnd) {
                decoration = BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                );
                textColor = AppColors.white;
                fontWeight = FontWeight.w700;
              } else if (isStart) {
                decoration = BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                );
                textColor = AppColors.white;
                fontWeight = FontWeight.w700;
              } else if (isEnd) {
                decoration = BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
                );
                textColor = AppColors.white;
                fontWeight = FontWeight.w700;
              } else if (isBetween) {
                decoration = BoxDecoration(color: AppColors.primary.withOpacity(0.1));
                fontWeight = FontWeight.w600;
              } else if (isToday) {
                // Subtle ring for today when not selected
                decoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                );
                textColor = AppColors.primary;
                fontWeight = FontWeight.w700;
              }
            }

            return MouseRegion(
              cursor: isFuture ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isFuture ? null : () => _handleDateTap(date),
                child: Container(
                  decoration: decoration,
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: fontWeight,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateInputs() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildDateBox('START DATE', _startDate),
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
          child: Icon(Icons.arrow_forward, color: AppColors.slate300, size: 18),
        ),
        _buildDateBox('END DATE', _endDate),
      ],
    );
  }

  Widget _buildDateBox(String label, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.slate500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.slate200),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(minWidth: 110),
          child: Text(
            date != null ? DateFormat('MMM d, yyyy').format(date) : '—',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: date != null ? AppColors.slate800 : AppColors.slate400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canApply = _startDate != null && _endDate != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            foregroundColor: AppColors.slate600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: canApply
              ? () => Navigator.of(context)
                  .pop(DateTimeRange(start: _startDate!, end: _endDate!))
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.slate200,
            disabledForegroundColor: AppColors.slate400,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          child: const Text('Apply Range'),
        ),
      ],
    );
  }
}