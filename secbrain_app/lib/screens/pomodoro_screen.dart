import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';

enum PomodoroMode {
  focus('Fokus', 25 * 60, green, greenLight, Icons.psychology_outlined),
  shortBreak(
    'Istirahat Singkat',
    5 * 60,
    Color(0xFF2E7D32),
    Color(0xFFE8F5E9),
    Icons.coffee_outlined,
  ),
  longBreak(
    'Istirahat Panjang',
    15 * 60,
    Color(0xFF1565C0),
    Color(0xFFE3F2FD),
    Icons.bedtime_outlined,
  );

  const PomodoroMode(
    this.label,
    this.defaultSeconds,
    this.primaryColor,
    this.bgColor,
    this.icon,
  );
  final String label;
  final int defaultSeconds;
  final Color primaryColor;
  final Color bgColor;
  final IconData icon;
}

class PomodoroSession {
  PomodoroSession({
    required this.taskTitle,
    required this.mode,
    required this.durationMinutes,
    required this.completedAt,
  });

  final String taskTitle;
  final PomodoroMode mode;
  final int durationMinutes;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
    'taskTitle': taskTitle,
    'mode': mode.name,
    'durationMinutes': durationMinutes,
    'completedAt': completedAt.toIso8601String(),
  };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) =>
      PomodoroSession(
        taskTitle: json['taskTitle'] as String? ?? 'Fokus Mandiri',
        mode: PomodoroMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => PomodoroMode.focus,
        ),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 25,
        completedAt:
            DateTime.tryParse(json['completedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  PomodoroMode _mode = PomodoroMode.focus;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  String? _selectedTaskTitle;
  final List<PomodoroSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _mode.defaultSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(PomodoroMode mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _remainingSeconds = mode.defaultSeconds;
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _onTimerComplete();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _mode.defaultSeconds;
      _isRunning = false;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _sessions.insert(
        0,
        PomodoroSession(
          taskTitle: _selectedTaskTitle ?? 'Fokus Mandiri',
          mode: _mode,
          durationMinutes: _mode.defaultSeconds ~/ 60,
          completedAt: DateTime.now(),
        ),
      );
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration_rounded, color: _mode.primaryColor),
            const SizedBox(width: 8),
            const Text('Sesi Selesai!'),
          ],
        ),
        content: Text(
          _mode == PomodoroMode.focus
              ? 'Selamat! Sesi fokus Anda selesai. Waktunya istirahat sejenak.'
              : 'Waktu istirahat selesai. Siap kembali fokus?',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (_mode == PomodoroMode.focus) {
                _switchMode(PomodoroMode.shortBreak);
              } else {
                _switchMode(PomodoroMode.focus);
              }
            },
            child: Text(
              _mode == PomodoroMode.focus
                  ? 'Mulai Istirahat'
                  : 'Mulai Fokus Baru',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final activeTasks = store.tasks.where((t) => !t.done).toList();
    final progress = 1.0 - (_remainingSeconds / _mode.defaultSeconds);
    final totalFocusMinutes = _sessions
        .where((s) => s.mode == PomodoroMode.focus)
        .fold(0, (sum, s) => sum + s.durationMinutes);

    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 24, hPad, 30),
      children: [
        const Heading(
          kicker: 'DEEP WORK & PRODUCTIVITY',
          title: 'Focus Timer & Pomodoro',
          subtitle: 'Tingkatkan konsentrasi melalui sesi fokus terstruktur dan istirahat terencana.',
        ),
        // Mode Selector Chips
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: PomodoroMode.values.map((mode) {
                final isSelected = _mode == mode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    avatar: Icon(
                      mode.icon,
                      size: 16,
                      color: isSelected ? mode.primaryColor : muted,
                    ),
                    label: Text(mode.label),
                    selected: isSelected,
                    selectedColor: mode.bgColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? mode.primaryColor : ink,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? mode.primaryColor
                          : muted.withValues(alpha: 0.2),
                    ),
                    onSelected: (val) {
                      if (val) _switchMode(mode);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Main Timer Card
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            child: Column(
              children: [
                // Linked task selector
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: muted.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedTaskTitle,
                      hint: const Row(
                        children: [
                          Icon(Icons.link, size: 16, color: muted),
                          SizedBox(width: 8),
                          Text(
                            'Tautkan ke Task aktif (opsional)',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: muted),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Fokus Mandiri (Tanpa Task)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        ...activeTasks.map(
                          (t) => DropdownMenuItem<String?>(
                            value: t.title,
                            child: Text(
                              t.title,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedTaskTitle = val),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Circular Timer Display
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: _mode.bgColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _mode.primaryColor,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            color: ink,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRunning ? 'SEDANG BERJALAN' : 'BERHENTI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: _isRunning ? _mode.primaryColor : muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                      iconSize: 22,
                      tooltip: 'Reset Timer',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _toggleTimer,
                      style: FilledButton.styleFrom(
                        backgroundColor: _mode.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(
                        _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 24,
                      ),
                      label: Text(
                        _isRunning ? 'JEDA' : 'MULAI FOKUS',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Daily Stats & Completed Sessions
        Row(
          children: [
            Expanded(
              child: Metric(
                'Total Waktu Fokus',
                '$totalFocusMinutes Menit',
                greenLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Metric(
                'Sesi Terselesaikan',
                '${_sessions.length} Sesi',
                blueLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // History List
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Log Sesi Hari Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ),
                    if (_sessions.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _sessions.clear()),
                        child: const Text(
                          'Bersihkan Log',
                          style: TextStyle(color: coral, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 32,
                            color: muted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada sesi fokus hari ini',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._sessions.map(
                    (s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: s.mode.bgColor,
                        child: Icon(
                          s.mode.icon,
                          color: s.mode.primaryColor,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        s.taskTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${s.mode.label} • ${s.durationMinutes} menit • ${s.completedAt.hour.toString().padLeft(2, '0')}:${s.completedAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: green,
                        size: 18,
                      ),
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
