enum TodoTimeframe {
  today,
  thisWeek,
  thisMonth,
  thisYear;

  String get label {
    switch (this) {
      case TodoTimeframe.today:
        return 'Hari Ini';
      case TodoTimeframe.thisWeek:
        return 'Minggu Ini';
      case TodoTimeframe.thisMonth:
        return 'Bulan Ini';
      case TodoTimeframe.thisYear:
        return 'Tahun Ini';
    }
  }

  String get subtitle {
    switch (this) {
      case TodoTimeframe.today:
        return 'Target & checklist harian';
      case TodoTimeframe.thisWeek:
        return 'Fokus & prioritas pekan ini';
      case TodoTimeframe.thisMonth:
        return 'Pencapaian bulan berjalan';
      case TodoTimeframe.thisYear:
        return 'Resolusi & milestone tahunan';
    }
  }

  String get iconName {
    switch (this) {
      case TodoTimeframe.today:
        return 'today';
      case TodoTimeframe.thisWeek:
        return 'week';
      case TodoTimeframe.thisMonth:
        return 'month';
      case TodoTimeframe.thisYear:
        return 'year';
    }
  }

  static TodoTimeframe fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'today':
      case 'hari ini':
      case 'hariini':
        return TodoTimeframe.today;
      case 'thisweek':
      case 'minggu ini':
      case 'mingguini':
      case 'week':
        return TodoTimeframe.thisWeek;
      case 'thismonth':
      case 'bulan ini':
      case 'bulanini':
      case 'month':
        return TodoTimeframe.thisMonth;
      case 'thisyear':
      case 'tahun ini':
      case 'tahunini':
      case 'year':
        return TodoTimeframe.thisYear;
      default:
        return TodoTimeframe.today;
    }
  }
}

class TodoItem {
  static int _idCounter = 0;

  static String generateUniqueId([String? title]) =>
      '${DateTime.now().microsecondsSinceEpoch}_${(title ?? "").hashCode.abs()}_${++_idCounter}';

  TodoItem({
    required this.title,
    this.timeframe = TodoTimeframe.today,
    this.done = false,
    String? id,
    DateTime? createdAt,
    this.completedAt,
    this.category = 'Umum',
  }) : id = (id != null && id.isNotEmpty) ? id : generateUniqueId(title),
       createdAt = createdAt ?? DateTime.now();

  String id;
  String title;
  bool done;
  TodoTimeframe timeframe;
  DateTime createdAt;
  DateTime? completedAt;
  String category;

  void toggle() {
    done = !done;
    completedAt = done ? DateTime.now() : null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'timeframe': timeframe.name,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'category': category,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    done: json['done'] as bool? ?? false,
    timeframe: TodoTimeframe.fromString(json['timeframe'] as String?),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'] as String)
        : null,
    category: json['category'] as String? ?? 'Umum',
  );
}
