import 'package:flutter/material.dart';

import '../main.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  final List<String> _weekdays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _today() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  String _weekdayToIndonesian(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    // 1 for Monday, 7 for Sunday
    final firstWeekday = _focusedMonth.weekday; // 1..7

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Selected day commitments
    final selectedWeekdayName = _weekdayToIndonesian(_selectedDate.weekday);
    final daySchedules = store.schedules
        .where((s) => s.day.toLowerCase() == selectedWeekdayName.toLowerCase())
        .toList();
    final dayTasks = store.tasks.where((t) {
      return _isSameDay(t.due, _selectedDate);
    }).toList();
    final dayBills = store.bills
        .where((b) => b.dueDay == _selectedDate.day)
        .toList();

    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 24, hPad, 30),
      children: [
        if (isMobile) ...[
          const Heading(
            kicker: 'AGENDA & KALENDER TERPADU',
            title: 'Kalender Aktivitas',
            subtitle: 'Satu kalender untuk jadwal kuliah, deadline tugas, dan tagihan.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _today,
              icon: const Icon(Icons.today, size: 16),
              label: const Text('Hari Ini'),
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Heading(
                  kicker: 'AGENDA & KALENDER TERPADU',
                  title: 'Kalender Aktivitas',
                  subtitle: 'Satu kalender untuk jadwal kuliah, deadline tugas, dan tagihan.',
                ),
              ),
              OutlinedButton.icon(
                onPressed: _today,
                icon: const Icon(Icons.today, size: 16),
                label: const Text('Hari Ini'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // Calendar Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Month Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Bulan Sebelumnya',
                    ),
                    Text(
                      '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Bulan Berikutnya',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Legend
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendDot(const Color(0xFF365C4C), 'Jadwal Kuliah'),
                      const SizedBox(width: 14),
                      _buildLegendDot(
                        const Color(0xFF5D8AA8),
                        'Deadline Tugas',
                      ),
                      const SizedBox(width: 14),
                      _buildLegendDot(
                        const Color(0xFFDF816B),
                        'Jatuh Tempo Tagihan',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Weekday Headers
                Row(
                  children: _weekdays.map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Days Grid
                _buildDaysGrid(daysInMonth, firstWeekday, today, store, isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Selected Date Agenda Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? store.accentColor.withValues(alpha: 0.2)
                            : store.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_note,
                        color: store.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$selectedWeekdayName, ${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isSameDay(_selectedDate, today)
                                ? 'Hari ini'
                                : '${daySchedules.length + dayTasks.length + dayBills.length} agenda terjadwal',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showTaskDialog(context, store),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add task'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (daySchedules.isEmpty &&
                    dayTasks.isEmpty &&
                    dayBills.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF26322C) : paper,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.bedtime_outlined, size: 36, color: muted),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada agenda khusus pada tanggal ini',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nikmati waktu luang atau tambahkan komitmen baru.',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Class schedules for this day
                  if (daySchedules.isNotEmpty) ...[
                    Text(
                      'JADWAL KULIAH',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: store.accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...daySchedules.map(
                      (schedule) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isDark
                              ? store.accentColor.withValues(alpha: 0.2)
                              : store.accentColor.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.school,
                            color: store.accentColor,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          schedule.courseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${schedule.startTime} - ${schedule.endTime} • ${schedule.room} • ${schedule.lecturer}',
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? store.accentColor.withValues(alpha: 0.2)
                                : store.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${schedule.sks} SKS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: store.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Tasks due on this day
                  if (dayTasks.isNotEmpty) ...[
                    const Text(
                      'DEADLINE TUGAS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D8AA8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...dayTasks.map(
                      (task) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: task.done,
                        activeColor: store.accentColor,
                        onChanged: (_) => store.toggleTask(task),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${task.category} • Prioritas: ${task.priority}',
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Bills due on this date
                  if (dayBills.isNotEmpty) ...[
                    const Text(
                      'TAGIHAN JATUH TEMPO',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: coral,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...dayBills.map(
                      (bill) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: coralLight,
                          child: Icon(
                            Icons.receipt_long,
                            color: coral,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          bill.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          bill.category,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                        trailing: Text(
                          money(bill.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: coral,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysGrid(
    int daysInMonth,
    int firstWeekday,
    DateTime today,
    BrainStore store,
    bool isDark,
  ) {
    final List<Widget> dayWidgets = [];

    // Empty spaces before first day of month (1-based: 1=Mon ... 7=Sun)
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _isSameDay(date, _selectedDate);
      final isCurrentDay = _isSameDay(date, today);

      final weekdayName = _weekdayToIndonesian(date.weekday);
      final scheduleCount = store.schedules
          .where((s) => s.day.toLowerCase() == weekdayName.toLowerCase())
          .length;
      final taskCount = store.tasks
          .where((t) => _isSameDay(t.due, date))
          .length;
      final billCount = store.bills.where((b) => b.dueDay == day).length;
      final totalEvents = scheduleCount + taskCount + billCount;

      Color? cellBg;
      if (isSelected) {
        cellBg = store.accentColor;
      } else if (isCurrentDay) {
        cellBg = store.accentColor.withValues(alpha: 0.14);
      } else if (totalEvents > 0) {
        cellBg = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF0F4F1);
      } else {
        cellBg = Colors.transparent;
      }

      dayWidgets.add(
        InkWell(
          onTap: () => setState(() => _selectedDate = date),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: cellBg,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: store.accentColor, width: 2)
                  : (isCurrentDay
                        ? Border.all(color: store.accentColor, width: 1.5)
                        : (totalEvents > 0
                              ? Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 1,
                                )
                              : null)),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: store.accentColor.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day number & optional event count badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            (isCurrentDay || isSelected || totalEvents > 0)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isCurrentDay
                                  ? store.accentColor
                                  : (isDark ? Colors.white : ink)),
                      ),
                    ),
                    if (totalEvents > 0 && !isSelected) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: store.accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$totalEvents',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : store.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                // Prominent colored event pill bars
                if (totalEvents > 0)
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: [
                      if (scheduleCount > 0)
                        Container(
                          width: isSelected ? 12 : 14,
                          height: 3.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF365C4C),
                          ),
                        ),
                      if (taskCount > 0)
                        Container(
                          width: isSelected ? 12 : 14,
                          height: 3.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF5D8AA8),
                          ),
                        ),
                      if (billCount > 0)
                        Container(
                          width: isSelected ? 12 : 14,
                          height: 3.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFFDF816B),
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(height: 3.5),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.sizeOf(context).width < 600;
        return GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 0.95 : 1.15,
          children: dayWidgets,
        );
      },
    );
  }
}
