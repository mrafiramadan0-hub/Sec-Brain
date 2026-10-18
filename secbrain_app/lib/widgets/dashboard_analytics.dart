import 'package:flutter/material.dart';

import '../main.dart';

class WeeklyInsightCard extends StatelessWidget {
  const WeeklyInsightCard({
    super.key,
    required this.store,
    required this.onNavigate,
  });

  final BrainStore store;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final completedTasks = store.tasks.where((t) => t.done).length;
    final totalTasks = store.tasks.length;
    final taskProgress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    final overdueTasks = store.tasks
        .where((t) => !t.done && t.due.isBefore(now))
        .toList();

    // Active habits streak stats
    final totalHabits = store.habits.length;
    final avgStreak = totalHabits > 0
        ? (store.habits.fold(0, (sum, h) => sum + h.currentStreak) /
                  totalHabits)
              .toStringAsFixed(1)
        : '0';

    // Savings ratio
    final totalSavingsTarget = store.savingsGoals.fold(
      0.0,
      (sum, g) => sum + g.targetAmount,
    );
    final totalSavingsCurrent = store.savingsGoals.fold(
      0.0,
      (sum, g) => sum + g.currentAmount,
    );
    final savingsProgress = totalSavingsTarget > 0
        ? (totalSavingsCurrent / totalSavingsTarget).clamp(0.0, 1.0)
        : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1F352B).withValues(alpha: 0.8),
                    const Color(0xFF1D2420),
                  ]
                : [greenLight.withValues(alpha: 0.6), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Produktivitas & Aktivitas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : ink,
                        ),
                      ),
                      Text(
                        'Pencapaian dan komitmen minggu ini',
                        style: TextStyle(
                          color: muted.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (overdueTasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: coralLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: coral.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: coral,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${overdueTasks.length} Overdue',
                          style: const TextStyle(
                            color: coral,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final items = [
                  _buildMetricItem(
                    context: context,
                    icon: Icons.task_alt_rounded,
                    color: green,
                    title: 'Penyelesaian Tugas',
                    value: '$completedTasks / $totalTasks tugas',
                    percentage: '${(taskProgress * 100).toInt()}%',
                    progress: taskProgress,
                    onTap: () => onNavigate(1),
                  ),
                  _buildMetricItem(
                    context: context,
                    icon: Icons.track_changes_rounded,
                    color: const Color(0xFF5E8B7E),
                    title: 'Konsistensi Habit',
                    value: 'Rata-rata $avgStreak hari streak',
                    percentage: '$totalHabits habit',
                    progress: (double.tryParse(avgStreak) ?? 0.0) / 7.0,
                    onTap: () => onNavigate(7),
                  ),
                  _buildMetricItem(
                    context: context,
                    icon: Icons.savings_rounded,
                    color: const Color(0xFFD97706),
                    title: 'Target Tabungan',
                    value: money(totalSavingsCurrent),
                    percentage: '${(savingsProgress * 100).toInt()}%',
                    progress: savingsProgress,
                    onTap: () => onNavigate(6),
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: items
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: w,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  children: items
                      .map(
                        (w) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: w,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String percentage,
    required double progress,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedProgress = progress.clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF19201C) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: muted.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }
}
