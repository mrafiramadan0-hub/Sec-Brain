import 'package:flutter/material.dart';

import '../main.dart';

class CategoryColorHelper {
  static Color getCategoryBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
      case 'pekerjaan':
        return blueLight;
      case 'university':
      case 'kuliah':
      case 'akademik':
        return greenLight;
      case 'organization':
      case 'organisasi':
        return amberLight;
      case 'personal':
      case 'pribadi':
        return coralLight;
      default:
        return const Color(0xFFEDE7F6);
    }
  }

  static Color getCategoryTextColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
      case 'pekerjaan':
        return const Color(0xFF1976D2);
      case 'university':
      case 'kuliah':
      case 'akademik':
        return green;
      case 'organization':
      case 'organisasi':
        return const Color(0xFFD97706);
      case 'personal':
      case 'pribadi':
        return coral;
      default:
        return const Color(0xFF7E57C2);
    }
  }
}

class TaskCategoryChip extends StatelessWidget {
  const TaskCategoryChip({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final bg = CategoryColorHelper.getCategoryBgColor(category);
    final text = CategoryColorHelper.getCategoryTextColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: text,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class OverdueBadge extends StatelessWidget {
  const OverdueBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: coral,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
