class Habit {
  Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.targetDaysPerWeek = 7,
    List<String>? completedDates,
    this.iconName = 'check',
    this.reflectionNotes = const {},
  }) : completedDates = List<String>.from(completedDates ?? []);

  final String id;
  String title;
  String description;
  int targetDaysPerWeek;
  List<String> completedDates; // Format: 'YYYY-MM-DD'
  String iconName;
  Map<String, String> reflectionNotes; // 'YYYY-MM-DD' -> note

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(formatDate(date));
  }

  bool get isCompletedToday {
    return isCompletedOn(DateTime.now());
  }

  void toggleDate(DateTime date) {
    final dateStr = formatDate(date);
    if (completedDates.contains(dateStr)) {
      completedDates.remove(dateStr);
    } else {
      completedDates.add(dateStr);
    }
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if completed today or yesterday
    var checkDate = today;
    if (!isCompletedOn(checkDate)) {
      // If not completed today, maybe completed yesterday
      checkDate = today.subtract(const Duration(days: 1));
      if (!isCompletedOn(checkDate)) {
        return 0;
      }
    }

    int streak = 0;
    while (isCompletedOn(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get weeklyCompletionRate {
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      if (isCompletedOn(d)) count++;
    }
    return (count / 7.0).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'targetDaysPerWeek': targetDaysPerWeek,
    'completedDates': completedDates,
    'iconName': iconName,
    'reflectionNotes': reflectionNotes,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    targetDaysPerWeek: json['targetDaysPerWeek'] as int? ?? 7,
    completedDates:
        (json['completedDates'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    iconName: json['iconName'] as String? ?? 'check',
    reflectionNotes:
        (json['reflectionNotes'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        {},
  );
}
