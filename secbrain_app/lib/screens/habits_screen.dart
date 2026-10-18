import 'package:flutter/material.dart';

import '../main.dart';
import '../models/habit.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _reflectionController = TextEditingController();
  final DateTime _reflectionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReflection();
  }

  void _loadReflection() {
    // We will read today's reflection from the first habit or SharedPreferences
    // if available, or initialize empty
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  IconData _getHabitIcon(String iconName) {
    switch (iconName) {
      case 'book':
        return Icons.menu_book;
      case 'water':
        return Icons.water_drop;
      case 'code':
        return Icons.terminal;
      case 'fitness':
        return Icons.fitness_center;
      case 'meditation':
        return Icons.self_improvement;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final completedTodayCount = store.habits
        .where((h) => h.isCompletedToday)
        .length;
    final progress = store.habits.isNotEmpty
        ? completedTodayCount / store.habits.length
        : 0.0;

    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 24, hPad, 30),
      children: [
        if (isMobile) ...[
          const Heading(
            kicker: 'HABITS & REFLEKSI',
            title: 'Habit Tracker',
            subtitle: 'Bangun konsistensi dan pantau refleksi perkembangan diri setiap hari.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: store.accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => showHabitDialog(context, store),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Habit'),
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Heading(
                  kicker: 'HABITS & REFLEKSI',
                  title: 'Habit Tracker',
                  subtitle: 'Bangun konsistensi dan pantau refleksi perkembangan diri setiap hari.',
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: store.accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => showHabitDialog(context, store),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Habit'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // Daily Progress Banner
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progres Kebiasaan Hari Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.habits.isEmpty
                            ? 'Belum ada habit yang terdaftar.'
                            : '$completedTodayCount dari ${store.habits.length} habit selesai hari ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFA0AAA2) : muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          color: store.accentColor,
                          backgroundColor: isDark
                              ? store.accentColor.withValues(alpha: 0.2)
                              : store.accentColor.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? store.accentColor.withValues(alpha: 0.2)
                        : store.accentColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: store.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Habits List
        if (store.habits.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Column(
                children: [
                  const Icon(Icons.track_changes, size: 48, color: muted),
                  const SizedBox(height: 12),
                  const Text(
                    'Mulai Rutinitas Positif Anda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tambahkan kebiasaan kecil yang ingin Anda bangun secara konsisten.',
                    style: TextStyle(fontSize: 12, color: muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: store.accentColor,
                    ),
                    onPressed: () => showHabitDialog(context, store),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Buat Habit Pertama'),
                  ),
                ],
              ),
            ),
          )
        else
          ...store.habits.map((habit) {
            final isDone = habit.isCompletedToday;
            final streak = habit.currentStreak;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Checkbox Circle
                    InkWell(
                      onTap: () {
                        store.toggleHabit(habit, now);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? store.accentColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isDone ? store.accentColor : muted,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isDone
                                ? Icons.check
                                : _getHabitIcon(habit.iconName),
                            color: isDone
                                ? Colors.white
                                : (isDark ? Colors.white70 : muted),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDone ? muted : null,
                            ),
                          ),
                          if (habit.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              habit.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Last 7 days dots
                          Row(
                            children: List.generate(7, (i) {
                              final dayOffset = 6 - i;
                              final checkDay = now.subtract(
                                Duration(days: dayOffset),
                              );
                              final completed = habit.isCompletedOn(checkDay);
                              final isTodayDot = dayOffset == 0;

                              return Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: completed
                                      ? store.accentColor
                                      : (isDark
                                            ? const Color(0xFF26322C)
                                            : const Color(0xFFE2E7E2)),
                                  border: isTodayDot
                                      ? Border.all(
                                          color: store.accentColor,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Streak Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: streak > 0
                            ? coralLight
                            : (isDark ? const Color(0xFF26322C) : paper),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: streak > 0
                              ? coral
                              : (isDark
                                    ? const Color(0xFF37463E)
                                    : const Color(0xFFE0E5E0)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            streak > 0 ? '🔥' : '🌱',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak hari',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: streak > 0 ? coral : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // More options popup
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: muted),
                      onSelected: (val) {
                        if (val == 'edit') {
                          showHabitDialog(context, store, habit: habit);
                        } else if (val == 'delete') {
                          store.deleteHabit(habit);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Habit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: coral,
                              ),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: coral)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
        // Daily Reflection Card
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
                        color: amberLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_stories,
                        color: Color(0xFF9A7B2C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Reflection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Satu hal berharga atau pelajaran terbaik hari ini',
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _reflectionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan evaluasi, rasa syukur, atau ide baru hari ini...',
                    hintStyle: const TextStyle(fontSize: 12, color: muted),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF26322C) : paper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF37463E)
                            : const Color(0xFFE6EAE5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: store.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final text = _reflectionController.text.trim();
                      if (text.isNotEmpty) {
                        // Create a note in Knowledge Base automatically!
                        final dateStr =
                            '${_reflectionDate.day}/${_reflectionDate.month}/${_reflectionDate.year}';
                        store.addNote(
                          Note(
                            'Refleksi Harian ($dateStr)',
                            text,
                            'Jurnal',
                            tags: ['#refleksi', '#harian'],
                          ),
                        );
                        _reflectionController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Refleksi harian tersimpan ke Knowledge Base!',
                            ),
                            backgroundColor: store.accentColor,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Simpan Refleksi'),
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

Future<void> showHabitDialog(
  BuildContext context,
  BrainStore store, {
  Habit? habit,
}) async {
  final isEdit = habit != null;
  final title = TextEditingController(text: habit?.title ?? '');
  final desc = TextEditingController(text: habit?.description ?? '');
  int targetDays = habit?.targetDaysPerWeek ?? 7;
  String selectedIcon = habit?.iconName ?? 'check';

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Habit' : 'Tambah Habit Baru'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kebiasaan',
                      hintText: 'Misal: Membaca 15 Halaman',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: desc,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi / Alasan',
                      hintText: 'Untuk memperluas wawasan',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Ikon:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          ('check', Icons.check_circle_outline),
                          ('book', Icons.menu_book),
                          ('water', Icons.water_drop),
                          ('code', Icons.terminal),
                          ('fitness', Icons.fitness_center),
                          ('meditation', Icons.self_improvement),
                        ].map((entry) {
                          final isSelected = selectedIcon == entry.$1;
                          return ChoiceChip(
                            selected: isSelected,
                            label: Icon(entry.$2, size: 18),
                            selectedColor: store.accentColor.withValues(
                              alpha: 0.2,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => selectedIcon = entry.$1);
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Target Hari / Minggu:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      DropdownButton<int>(
                        value: targetDays,
                        items: [1, 2, 3, 4, 5, 6, 7].map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text('$d hari'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => targetDays = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: store.accentColor),
              onPressed: () {
                final t = title.text.trim();
                if (t.isEmpty) return;

                if (isEdit) {
                  habit.title = t;
                  habit.description = desc.text.trim();
                  habit.targetDaysPerWeek = targetDays;
                  habit.iconName = selectedIcon;
                  store.updateHabit(habit);
                } else {
                  store.addHabit(
                    Habit(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: t,
                      description: desc.text.trim(),
                      targetDaysPerWeek: targetDays,
                      iconName: selectedIcon,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Perbarui' : 'Tambah'),
            ),
          ],
        );
      },
    ),
  );
}
