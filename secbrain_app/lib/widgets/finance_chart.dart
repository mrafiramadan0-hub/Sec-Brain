import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../main.dart';

enum FinanceTimeRange {
  thisMonth('Bulan Ini'),
  last7Days('7 Hari Terakhir'),
  lastMonth('Bulan Lalu'),
  allTime('Semua Waktu');

  const FinanceTimeRange(this.label);
  final String label;
}

class FinanceCategoryChart extends StatefulWidget {
  const FinanceCategoryChart({super.key, required this.store});
  final BrainStore store;

  @override
  State<FinanceCategoryChart> createState() => _FinanceCategoryChartState();
}

class _FinanceCategoryChartState extends State<FinanceCategoryChart> {
  FinanceTimeRange _selectedRange = FinanceTimeRange.thisMonth;

  final List<Color> _palette = const [
    Color(0xFF365C4C), // primary green
    Color(0xFFDF816B), // coral
    Color(0xFF5D8AA8), // soft blue
    Color(0xFFD4AF37), // warm gold
    Color(0xFF7E57C2), // purple
    Color(0xFF26A69A), // teal
    Color(0xFF8D6E63), // brown
    Color(0xFF78909C), // blue grey
  ];

  @override
  Widget build(BuildContext context) {
    final expenses = widget.store.transactions.where((t) => !t.income).toList();

    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (final tx in expenses) {
      final cat = tx.category.trim().isEmpty ? 'Lainnya' : tx.category.trim();
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + tx.amount;
    }

    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Komposisi Pengeluaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Distribusi alokasi pengeluaran per kategori',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFA0AAA2) : muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: greenLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    money(totalExpense),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Time range chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FinanceTimeRange.values.map((range) {
                  final selected = _selectedRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selected,
                      label: Text(
                        range.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selectedColor: green,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : ink),
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedRange = range);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (sortedCategories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF26322C) : paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF37463E)
                        : const Color(0xFFE6EAE5),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 40, color: muted),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada data pengeluaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tambahkan transaksi pengeluaran baru untuk melihat grafik analisis.',
                      style: TextStyle(fontSize: 11, color: muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              // Donut Chart & Summary
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      categories: sortedCategories,
                      total: totalExpense,
                      colors: _palette,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${sortedCategories.length} Kategori',
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                          const SizedBox(height: 2),
                          const Icon(Icons.insights, size: 20, color: green),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Category progress bars
              ...sortedCategories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final color = _palette[idx % _palette.length];
                final percentage = totalExpense > 0
                    ? (cat.value / totalExpense)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.key,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            money(cat.value),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${(percentage * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.15),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.categories,
    required this.total,
    required this.colors,
  });

  final List<MapEntry<String, double>> categories;
  final double total;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < categories.length; i++) {
      final sweepAngle = (categories[i].value / total) * 2 * math.pi;
      paint.color = colors[i % colors.length];

      // Draw arc with tiny gap if multiple categories
      final gap = categories.length > 1 ? 0.05 : 0.0;
      final adjustedSweep = math.max(0.01, sweepAngle - gap);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + (gap / 2),
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.categories != categories;
  }
}
