import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'models/habit.dart';
import 'models/todo_item.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/todo_screen.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'services/widget_service.dart';
import 'widgets/accent_color_picker.dart';
import 'widgets/backup_dialog.dart';
import 'widgets/cross_link_chip.dart';
import 'widgets/dashboard_analytics.dart';
import 'widgets/finance_chart.dart';
import 'widgets/finance_trend_chart.dart';
import 'widgets/global_search_dialog.dart';
import 'widgets/kanban_board.dart';
import 'widgets/overdue_badge.dart';
import 'widgets/secbrain_logo.dart';

const ink = Color(0xFF202924);
const muted = Color(0xFF7B847E);
const paper = Color(0xFFF7F8F6);
const green = Color(0xFF365C4C);
const greenLight = Color(0xFFE8F0E9);
const coral = Color(0xFFDF816B);
const coralLight = Color(0xFFF9E9E4);
const amberLight = Color(0xFFF7F1DE);
const blueLight = Color(0xFFEAF0F3);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // DefaultFirebaseOptions menyesuaikan konfigurasi per-platform secara otomatis.
    // Jika masih menggunakan placeholder, blok ini tetap aman (ditangkap catch)
    // dan app berjalan dalam mode offline tanpa crash.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase berhasil diinisialisasi.');
  } catch (e) {
    debugPrint('Firebase tidak tersedia (mode offline): $e');
  }

  try {
    await NotificationService.init();
  } catch (e, stackTrace) {
    debugPrint('Notifikasi tidak tersedia: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const SecBrainApp());
}

class Task {
  Task(
    this.title,
    this.category,
    this.priority, {
    String? id,
    this.done = false,
    this.inProgress = false,
    DateTime? due,
    this.recurring = 'None',
    this.urgent = false,
    this.important = true,
  }) : id =
           id ??
           (title.hashCode ^ (due?.millisecondsSinceEpoch ?? 0))
               .abs()
               .toString(),
       due = due ?? DateTime.now().add(const Duration(hours: 2));

  String id;
  String title;
  String category;
  String priority;
  bool done;
  bool inProgress;
  DateTime due;
  String recurring;
  bool urgent;
  bool important;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'priority': priority,
    'done': done,
    'inProgress': inProgress,
    'due': due.toIso8601String(),
    'recurring': recurring,
    'urgent': urgent,
    'important': important,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    json['title'] as String? ?? '',
    json['category'] as String? ?? 'Personal',
    json['priority'] as String? ?? 'Medium',
    id: json['id'] as String?,
    done: json['done'] as bool? ?? false,
    inProgress: json['inProgress'] as bool? ?? false,
    due: DateTime.tryParse(json['due'] as String? ?? ''),
    recurring: json['recurring'] as String? ?? 'None',
    urgent: json['urgent'] as bool? ?? false,
    important: json['important'] as bool? ?? true,
  );
}

class Note {
  Note(
    this.title,
    this.body,
    this.type, {
    String? id,
    List<String>? tags,
    List<String>? linkedTaskTitles,
  }) : id = id ?? (title.hashCode ^ body.hashCode).abs().toString(),
       tags = List<String>.from(tags ?? []),
       linkedTaskTitles = List<String>.from(linkedTaskTitles ?? []);

  String id;
  String title;
  String body;
  String type;
  List<String> tags;
  List<String> linkedTaskTitles;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'tags': tags,
    'linkedTaskTitles': linkedTaskTitles,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    json['title'] as String? ?? '',
    json['body'] as String? ?? '',
    json['type'] as String? ?? 'General',
    id: json['id'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    linkedTaskTitles: (json['linkedTaskTitles'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList(),
  );
}

class TransactionItem {
  TransactionItem(
    this.title,
    this.amount,
    this.category,
    this.income, {
    String? id,
    DateTime? date,
  }) : id =
           id ??
           (title.hashCode ^
                   amount.hashCode ^
                   (date?.millisecondsSinceEpoch ?? 0))
               .abs()
               .toString(),
       date = date ?? DateTime.now();

  String id;
  String title;
  double amount;
  String category;
  bool income;
  DateTime date;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'income': income,
    'date': date.toIso8601String(),
  };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        json['title'] as String? ?? '',
        (json['amount'] as num?)?.toDouble() ?? 0.0,
        json['category'] as String? ?? 'General',
        json['income'] as bool? ?? false,
        id: json['id'] as String?,
        date: DateTime.tryParse(json['date'] as String? ?? ''),
      );
}

class SavingsGoal {
  SavingsGoal(
    this.title,
    this.targetAmount,
    this.currentAmount, {
    String? id,
    this.targetDate = '',
  }) : id = id ?? (title.hashCode ^ targetAmount.hashCode).abs().toString();

  String id;
  String title;
  double targetAmount;
  double currentAmount;
  String targetDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'targetDate': targetDate,
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    json['title'] as String? ?? '',
    (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
    (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
    id: json['id'] as String?,
    targetDate: json['targetDate'] as String? ?? '',
  );
}

class NoteTemplate {
  const NoteTemplate({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    required this.defaultTitle,
    required this.defaultTitleHint,
    required this.bodyContent,
  });

  final String id;
  final String label;
  final IconData icon;
  final String category;
  final String defaultTitle;
  final String defaultTitleHint;
  final String bodyContent;
}

const noteTemplates = <NoteTemplate>[
  NoteTemplate(
    id: 'free',
    label: 'Catatan Bebas',
    icon: Icons.edit_note_outlined,
    category: 'General',
    defaultTitle: '',
    defaultTitleHint: 'Judul catatan bebas...',
    bodyContent: '',
  ),
  NoteTemplate(
    id: 'meeting',
    label: 'Agenda Rapat',
    icon: Icons.groups_outlined,
    category: 'Agenda Rapat',
    defaultTitle: 'Agenda Rapat: ',
    defaultTitleHint: 'Contoh: Agenda Rapat Sprint Weekly',
    bodyContent: '''📅 Tanggal & Waktu: 
📍 Lokasi / Media: Google Meet / Ruang Rapat
👥 Peserta:
- 

🎯 Tujuan Rapat:
- 

📋 Poin Pembahasan:
1. Progress update & evaluasi sprint
2. Hambatan teknis & blockers
3. Rencana alokasi tugas berikutnya

✅ Action Items:
[ ] 
[ ] 

📌 Catatan Tambahan:
- ''',
  ),
  NoteTemplate(
    id: 'client',
    label: 'Notulensi Klien',
    icon: Icons.business_center_outlined,
    category: 'Notulensi Klien',
    defaultTitle: 'Notulensi Klien: ',
    defaultTitleHint: 'Contoh: Notulensi Klien PT Inovasi Maju',
    bodyContent: '''🏢 Klien / Instansi: 
📅 Tanggal: 
👤 PIC Klien: 
👤 Tim Internal: 

📌 Ringkasan Kebutuhan & Ekspektasi:
- 

💡 Kesepakatan & Keputusan Utama:
1. 
2. 

⚠️ Catatan Khusus & Scope Pekerjaan:
- 

🚀 Tindak Lanjut (Next Steps):
[ ] Kirim rangkuman notulensi & penawaran revisi
[ ] Konfirmasi jadwal meeting berikutnya''',
  ),
  NoteTemplate(
    id: 'workshop',
    label: 'Catatan Workshop',
    icon: Icons.school_outlined,
    category: 'Catatan Workshop',
    defaultTitle: 'Catatan Workshop: ',
    defaultTitleHint: 'Contoh: Catatan Workshop Flutter & Clean Architecture',
    bodyContent: '''🎓 Topik Workshop: 
🎙️ Pemateri: 
📅 Tanggal Pelaksanaan: 

🔑 Key Takeaways & Wawasan Penting:
1. 
2. 
3. 

🛠️ Tools & Referensi yang Direkomendasikan:
- 

📝 Rangkuman Materi:
- Konsep Utama: 
- Best Practices: 

💡 Rencana Aksi & Implementasi:
[ ] Eksperimen kode di repository lokal
[ ] Bagikan rangkuman materi kepada tim internal''',
  ),
];

class Memory {
  Memory(
    this.title,
    this.type,
    this.rating,
    this.review,
    this.quote, {
    String? id,
    DateTime? completed,
    this.coverUrl = '',
  }) : id =
           id ??
           (title.hashCode ^ (completed?.millisecondsSinceEpoch ?? 0))
               .abs()
               .toString(),
       completed = completed ?? DateTime.now();

  String id;
  String title;
  String type;
  double rating;
  String review;
  String quote;
  DateTime completed;
  String coverUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'rating': rating,
    'review': review,
    'quote': quote,
    'completed': completed.toIso8601String(),
    'coverUrl': coverUrl,
  };

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
    json['title'] as String? ?? '',
    json['type'] as String? ?? '',
    (json['rating'] as num?)?.toDouble() ?? 0.0,
    json['review'] as String? ?? '',
    json['quote'] as String? ?? '',
    id: json['id'] as String?,
    completed: DateTime.tryParse(json['completed'] as String? ?? ''),
    coverUrl: json['coverUrl'] as String? ?? '',
  );
}

class Bill {
  Bill(
    this.title,
    this.amount,
    this.dueDay,
    this.category, {
    String? id,
    this.recurring = 'Monthly',
  }) : id = id ?? (title.hashCode ^ amount.hashCode).abs().toString();

  String id;
  String title;
  double amount;
  int dueDay;
  String category;
  String recurring;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'dueDay': dueDay,
    'category': category,
    'recurring': recurring,
  };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    json['title'] as String? ?? '',
    (json['amount'] as num?)?.toDouble() ?? 0.0,
    (json['dueDay'] as num?)?.toInt() ?? 1,
    json['category'] as String? ?? 'General',
    id: json['id'] as String?,
    recurring: json['recurring'] as String? ?? 'Monthly',
  );
}

class Investment {
  Investment(
    this.name,
    this.symbol,
    this.units,
    this.averagePrice,
    this.currentPrice, {
    String? id,
  }) : id = id ?? (name.hashCode ^ symbol.hashCode).abs().toString();

  String id;
  String name;
  String symbol;
  double units;
  double averagePrice;
  double currentPrice;
  double get value => units * currentPrice;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'symbol': symbol,
    'units': units,
    'averagePrice': averagePrice,
    'currentPrice': currentPrice,
  };

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
    json['name'] as String? ?? '',
    json['symbol'] as String? ?? '',
    (json['units'] as num?)?.toDouble() ?? 0.0,
    (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
    (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
    id: json['id'] as String?,
  );
}

class CourseSchedule {
  CourseSchedule({
    String? id,
    required this.courseName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.lecturer,
    this.sks = 3,
    this.colorIndex = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  String id;
  String courseName;
  String day;
  String startTime;
  String endTime;
  String room;
  String lecturer;
  int sks;
  int colorIndex;

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseName': courseName,
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'lecturer': lecturer,
    'sks': sks,
    'colorIndex': colorIndex,
  };

  factory CourseSchedule.fromJson(Map<String, dynamic> json) => CourseSchedule(
    id: json['id'] as String?,
    courseName: json['courseName'] as String? ?? '',
    day: json['day'] as String? ?? 'Senin',
    startTime: json['startTime'] as String? ?? '08:00',
    endTime: json['endTime'] as String? ?? '09:40',
    room: json['room'] as String? ?? '',
    lecturer: json['lecturer'] as String? ?? '',
    sks: (json['sks'] as num?)?.toInt() ?? 3,
    colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
  );
}

class BrainStore extends ChangeNotifier {
  BrainStore() {
    load();
  }
  final tasks = <Task>[
    Task(
      'Review proposal - Studio Nara',
      'Work',
      'High',
      done: true,
      urgent: true,
    ),
    Task(
      'Submit research methodology',
      'University',
      'High',
      due: DateTime(2026, 9, 23, 13),
      urgent: true,
    ),
    Task(
      'Team sync & sprint planning',
      'Organization',
      'Medium',
      recurring: 'Weekly',
    ),
    Task('Pick up laundry', 'Personal', 'Low', important: false),
  ];
  final notes = <Note>[
    Note(
      'Client discovery - Karsa Studio',
      'Focus on making the onboarding feel less like a form...',
      'Meeting',
    ),
    Note(
      'Things to explore for thesis',
      'Look into the relationship between ambient...',
      'Idea',
    ),
  ];
  final transactions = <TransactionItem>[];
  final savingsGoals = <SavingsGoal>[];
  final schedules = <CourseSchedule>[];
  final memories = <Memory>[
    Memory(
      'Interstellar',
      'Film',
      5,
      'A quiet, beautiful story about distance and love.',
      'Love is the one thing that transcends time and space.',
    ),
  ];
  final bills = <Bill>[
    Bill('Internet rumah', 350000, 28, 'Utilities'),
    Bill('Spotify Premium', 54990, 12, 'Subscription'),
  ];
  final investments = <Investment>[
    Investment('Reksa Dana Pasar Uang', 'RDPU', 12, 1250000, 1315000),
  ];
  final habits = <Habit>[
    Habit(
      id: 'h1',
      title: 'Membaca Buku / Jurnal',
      description: 'Minimal 15 menit per hari',
      iconName: 'book',
      targetDaysPerWeek: 7,
    ),
    Habit(
      id: 'h2',
      title: 'Minum Air Mineral 2L',
      description: 'Menjaga hidrasi tubuh',
      iconName: 'water',
      targetDaysPerWeek: 7,
    ),
    Habit(
      id: 'h3',
      title: 'Review Catatan & Coding',
      description: 'Konsistensi belajar mandiri',
      iconName: 'code',
      targetDaysPerWeek: 5,
    ),
  ];
  final todos = <TodoItem>[
    TodoItem(
      title: 'Review materi kuliah hari ini',
      timeframe: TodoTimeframe.today,
      category: 'Kuliah',
    ),
    TodoItem(
      title: 'Minum air 2 liter & istirahat cukup',
      timeframe: TodoTimeframe.today,
      done: true,
      category: 'Pribadi',
    ),
    TodoItem(
      title: 'Selesaikan draf laporan mingguan',
      timeframe: TodoTimeframe.thisWeek,
      category: 'Kerja',
    ),
    TodoItem(
      title: 'Backup seluruh file & data penting',
      timeframe: TodoTimeframe.thisWeek,
      category: 'Umum',
    ),
    TodoItem(
      title: 'Baca 1 buku pengembangan diri selesai',
      timeframe: TodoTimeframe.thisMonth,
      category: 'Target',
    ),
    TodoItem(
      title: 'Evaluasi pengeluaran & tabungan bulanan',
      timeframe: TodoTimeframe.thisMonth,
      category: 'Keuangan',
    ),
    TodoItem(
      title: 'Capai target tabungan darurat & investasi',
      timeframe: TodoTimeframe.thisYear,
      category: 'Target',
    ),
    TodoItem(
      title: 'Kuasai Flutter & Dart tingkat lanjut',
      timeframe: TodoTimeframe.thisYear,
      category: 'Skill',
    ),
  ];
  ThemeMode themeMode = ThemeMode.light;
  Color accentColor = green;
  bool lockEnabled = false;
  String pinHash = '';
  bool onboardingCompleted = true;
  String geminiApiKey = '';
  String userName = 'Aditya';
  String userEmail = 'aditya@secbrain.app';
  SharedPreferences? prefs;
  bool ready = false;
  bool isSyncing = false;

  double get totalIncome => transactions
      .where((item) => item.income)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => transactions
      .where((item) => !item.income)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    _loadList('tasks', tasks, (json) => Task.fromJson(json));
    _loadList('notes', notes, (json) => Note.fromJson(json));
    _loadList(
      'transactions',
      transactions,
      (json) => TransactionItem.fromJson(json),
    );
    _loadList(
      'savingsGoals',
      savingsGoals,
      (json) => SavingsGoal.fromJson(json),
    );
    _loadList('schedules', schedules, (json) => CourseSchedule.fromJson(json));
    _loadList('memories', memories, (json) => Memory.fromJson(json));
    _loadList('bills', bills, (json) => Bill.fromJson(json));
    _loadList('investments', investments, (json) => Investment.fromJson(json));
    _loadList('habits', habits, (json) => Habit.fromJson(json));
    _loadList('todos', todos, (json) => TodoItem.fromJson(json));

    // Pastikan seluruh to-do item memiliki ID yang unik (mencegah duplicate key dari data lokal lama)
    final seenTodoIds = <String>{};
    for (final todo in todos) {
      if (todo.id.isEmpty || seenTodoIds.contains(todo.id)) {
        todo.id = TodoItem.generateUniqueId(todo.title);
      }
      seenTodoIds.add(todo.id);
    }

    final themeStr = prefs?.getString('theme_mode');
    if (themeStr == 'dark') themeMode = ThemeMode.dark;
    if (themeStr == 'system') themeMode = ThemeMode.system;
    if (themeStr == 'light') themeMode = ThemeMode.light;

    final accentVal = prefs?.getInt('accent_color');
    if (accentVal != null) accentColor = Color(accentVal);

    lockEnabled = prefs?.getBool('lock_enabled') ?? false;
    pinHash = prefs?.getString('pin_hash') ?? '';
    onboardingCompleted = prefs?.getBool('onboarding_completed') ?? true;

    geminiApiKey = prefs?.getString('gemini_api_key') ?? '';
    userName = prefs?.getString('user_name') ?? 'Aditya';
    userEmail = prefs?.getString('user_email') ?? 'aditya@secbrain.app';

    // Reset default dummy data if persisted from earlier runs
    if (prefs?.getBool('transactions_cleaned_v2') != true) {
      final isDefaultDummy = transactions.any(
        (t) => t.title == 'Monthly allowance' && t.amount == 6800000,
      );
      if (isDefaultDummy) {
        transactions.clear();
        await prefs?.setString('transactions', jsonEncode([]));
      }
      await prefs?.setBool('transactions_cleaned_v2', true);
    }

    // Dengarkan perubahan status login untuk sinkronisasi otomatis
    AuthService.authStateChanges.listen((user) {
      if (user != null) {
        SyncService.fetchAndSyncFromCloud(user.uid, this);
        SyncService.startRealtimeSync(user.uid, this);
      } else {
        SyncService.stopRealtimeSync();
      }
    });

    ready = true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    save();
  }

  void setAccentColor(Color color) {
    accentColor = color;
    save();
  }

  void setLock(bool enabled, String hash) {
    lockEnabled = enabled;
    pinHash = hash;
    save();
  }

  void setOnboardingCompleted(bool completed) {
    onboardingCompleted = completed;
    save();
  }

  void setGeminiApiKey(String key) {
    geminiApiKey = key.trim();
    save();
  }

  void setUserProfile(String name, String email) {
    userName = name.trim();
    userEmail = email.trim();
    save();
  }

  void _loadList<T>(
    String key,
    List<T> target,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = prefs?.getString(key);
    if (raw != null) {
      target
        ..clear()
        ..addAll(
          (jsonDecode(raw) as List).map(
            (item) => fromJson(item as Map<String, dynamic>),
          ),
        );
    }
  }

  /// Menerapkan data dari Cloud Firestore ke state lokal dan cache
  void applyCloudData({
    List<Task>? cloudTasks,
    List<Note>? cloudNotes,
    List<CourseSchedule>? cloudSchedules,
    List<TransactionItem>? cloudTransactions,
    List<Habit>? cloudHabits,
    List<Bill>? cloudBills,
    List<SavingsGoal>? cloudSavingsGoals,
    List<Investment>? cloudInvestments,
    List<Memory>? cloudMemories,
    List<TodoItem>? cloudTodos,
    bool saveToLocal = true,
  }) {
    if (cloudTasks != null) {
      tasks
        ..clear()
        ..addAll(cloudTasks);
    }
    if (cloudNotes != null) {
      notes
        ..clear()
        ..addAll(cloudNotes);
    }
    if (cloudSchedules != null) {
      schedules
        ..clear()
        ..addAll(cloudSchedules);
    }
    if (cloudTransactions != null) {
      transactions
        ..clear()
        ..addAll(cloudTransactions);
    }
    if (cloudHabits != null) {
      habits
        ..clear()
        ..addAll(cloudHabits);
    }
    if (cloudBills != null) {
      bills
        ..clear()
        ..addAll(cloudBills);
    }
    if (cloudSavingsGoals != null) {
      savingsGoals
        ..clear()
        ..addAll(cloudSavingsGoals);
    }
    if (cloudInvestments != null) {
      investments
        ..clear()
        ..addAll(cloudInvestments);
    }
    if (cloudMemories != null) {
      memories
        ..clear()
        ..addAll(cloudMemories);
    }
    if (cloudTodos != null) {
      todos
        ..clear()
        ..addAll(cloudTodos);
    }

    if (saveToLocal) {
      _saveLocalCacheOnly();
      unawaited(WidgetService.syncWidgetData(this));
    }
    notifyListeners();
  }

  /// Menyimpan data langsung ke SharedPreferences cache tanpa memicu upload balik
  Future<void> _saveLocalCacheOnly() async {
    await prefs?.setString(
      'tasks',
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'notes',
      jsonEncode(notes.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'transactions',
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'savingsGoals',
      jsonEncode(savingsGoals.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'schedules',
      jsonEncode(schedules.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'memories',
      jsonEncode(memories.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'bills',
      jsonEncode(bills.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'investments',
      jsonEncode(investments.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'habits',
      jsonEncode(habits.map((item) => item.toJson()).toList()),
    );
    await prefs?.setString(
      'todos',
      jsonEncode(todos.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> save({bool syncToCloud = true}) async {
    await prefs?.setString('theme_mode', themeMode.name);
    await prefs?.setInt('accent_color', accentColor.toARGB32());
    await prefs?.setBool('lock_enabled', lockEnabled);
    await prefs?.setString('pin_hash', pinHash);
    await prefs?.setBool('onboarding_completed', onboardingCompleted);
    await prefs?.setString('gemini_api_key', geminiApiKey);
    await prefs?.setString('user_name', userName);
    await prefs?.setString('user_email', userEmail);

    await _saveLocalCacheOnly();

    // Sinkronisasi data terkini ke Android Home Screen Widget
    unawaited(WidgetService.syncWidgetData(this));

    if (syncToCloud &&
        !isSyncing &&
        AuthService.isLoggedIn &&
        AuthService.currentUser != null) {
      SyncService.uploadLocalToCloud(AuthService.currentUser!.uid, this);
    }
    notifyListeners();
  }

  void addTodo(TodoItem todo) {
    todos.insert(0, todo);
    save();
  }

  void toggleTodo(TodoItem todo) {
    todo.toggle();
    save();
  }

  void updateTodo(
    TodoItem todo, {
    String? title,
    TodoTimeframe? timeframe,
    String? category,
  }) {
    if (title != null) todo.title = title;
    if (timeframe != null) todo.timeframe = timeframe;
    if (category != null) todo.category = category;
    save();
  }

  void deleteTodo(TodoItem todo) {
    todos.remove(todo);
    save();
  }

  void clearCompletedTodos([TodoTimeframe? timeframe]) {
    if (timeframe != null) {
      todos.removeWhere((t) => t.timeframe == timeframe && t.done);
    } else {
      todos.removeWhere((t) => t.done);
    }
    save();
  }

  void toggleTask(Task task) {
    task.done = !task.done;
    save();
  }

  void addTask(Task task) {
    tasks.insert(0, task);
    NotificationService.scheduleTaskReminders(
      taskId: task.title,
      taskTitle: task.title,
      deadline: task.due,
    );
    save();
  }

  void addNote(Note note) {
    notes.insert(0, note);
    save();
  }

  void updateNote(
    Note note,
    String newTitle,
    String newBody, [
    String? newType,
    List<String>? newTags,
    List<String>? newLinkedTasks,
  ]) {
    note.title = newTitle;
    note.body = newBody;
    if (newType != null) note.type = newType;
    if (newTags != null) note.tags = List<String>.from(newTags);
    if (newLinkedTasks != null) {
      note.linkedTaskTitles = List<String>.from(newLinkedTasks);
    }
    save();
  }

  void addHabit(Habit habit) {
    habits.add(habit);
    save();
  }

  void toggleHabit(Habit habit, DateTime date) {
    habit.toggleDate(date);
    save();
  }

  void deleteHabit(Habit habit) {
    habits.remove(habit);
    save();
  }

  void updateHabit(Habit habit) {
    final idx = habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) {
      habits[idx] = habit;
      save();
    }
  }

  void addTransaction(TransactionItem item) {
    transactions.insert(0, item);
    save();
  }

  void addSavingsGoal(SavingsGoal goal) {
    savingsGoals.add(goal);
    save();
  }

  void deleteSavingsGoal(SavingsGoal goal) {
    savingsGoals.remove(goal);
    save();
  }

  void addSchedule(CourseSchedule schedule) {
    schedules.add(schedule);
    NotificationService.scheduleClassReminder(
      courseName: schedule.courseName,
      day: schedule.day,
      startTime: schedule.startTime,
      room: schedule.room,
      lecturer: schedule.lecturer,
    );
    save();
  }

  void deleteSchedule(CourseSchedule schedule) {
    schedules.remove(schedule);
    save();
  }

  void updateSchedule(CourseSchedule schedule, CourseSchedule updated) {
    final idx = schedules.indexOf(schedule);
    if (idx != -1) {
      schedules[idx] = updated;
      save();
    }
  }

  void addMemory(Memory memory) {
    memories.insert(0, memory);
    save();
  }

  void deleteTask(Task task) {
    tasks.remove(task);
    save();
  }

  void deleteNote(Note note) {
    notes.remove(note);
    save();
  }

  void deleteTransaction(TransactionItem item) {
    transactions.remove(item);
    save();
  }

  void deleteMemory(Memory memory) {
    memories.remove(memory);
    save();
  }

  void addBill(Bill bill) {
    bills.add(bill);
    NotificationService.scheduleBillReminder(
      billTitle: bill.title,
      amount: bill.amount,
      dueDay: bill.dueDay,
    );
    save();
  }

  void deleteBill(Bill bill) {
    bills.remove(bill);
    save();
  }

  void addInvestment(Investment item) {
    investments.add(item);
    save();
  }

  void deleteInvestment(Investment item) {
    investments.remove(item);
    save();
  }
}

class StoreScope extends InheritedNotifier<BrainStore> {
  StoreScope({super.key, required super.child, BrainStore? store})
    : super(notifier: store ?? BrainStore());
  static BrainStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

class SecBrainApp extends StatefulWidget {
  const SecBrainApp({super.key});

  @override
  State<SecBrainApp> createState() => _SecBrainAppState();
}

class _SecBrainAppState extends State<SecBrainApp> {
  late final BrainStore _store;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _store = BrainStore();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: _store,
      child: Builder(
        builder: (context) {
          final store = StoreScope.of(context);
          final seed = store.accentColor;

          Widget homeWidget;
          if (!store.onboardingCompleted) {
            homeWidget = OnboardingScreen(
              onFinish: () => store.setOnboardingCompleted(true),
            );
          } else if (store.lockEnabled &&
              !_unlocked &&
              store.pinHash.isNotEmpty) {
            homeWidget = LockScreen(
              savedPinHash: store.pinHash,
              onUnlocked: () => setState(() => _unlocked = true),
            );
          } else {
            homeWidget = const AppShell();
          }

          final isDarkTheme = store.themeMode == ThemeMode.dark;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDarkTheme
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDarkTheme
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SecBrain',
            themeMode: store.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: paper,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              ),
              fontFamily: 'Arial',
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFE6EAE5),
                space: 1,
              ),
              navigationBarTheme: NavigationBarThemeData(
                indicatorColor: seed.withValues(alpha: 0.18),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF141916),
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ),
              fontFamily: 'Arial',
              cardTheme: CardThemeData(
                color: const Color(0xFF1D2420),
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF1D2420),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF26322C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFF26322C),
                space: 1,
              ),
              navigationBarTheme: NavigationBarThemeData(
                indicatorColor: seed.withValues(alpha: 0.25),
              ),
            ),
            home: homeWidget,
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final titles = [
    'Overview',
    'Tasks & Agenda',
    'To-Do List',
    'Jadwal Kuliah',
    'Kalender Terpadu',
    'Knowledge Base',
    'Finance',
    'Habit Tracker',
    'Memory Log',
    'AI Assistant',
  ];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final screens = [
      DashboardScreen(onOpen: (value) => setState(() => index = value)),
      const TasksScreen(),
      const TodoScreen(),
      const ScheduleScreen(),
      const CalendarScreen(),
      const NotesScreen(),
      const FinanceScreen(),
      const HabitsScreen(),
      const MemoriesScreen(),
      AiAssistantScreen(onNavigate: (value) => setState(() => index = value)),
    ];

    // Map 10 screens to 5 main navigation bar destinations
    int navIndex;
    if (index == 0) {
      navIndex = 0;
    } else if (index == 1 || index == 2) {
      navIndex = 1; // Tasks & To-Do
    } else if (index == 3 || index == 4) {
      navIndex = 2; // Jadwal & Kalender
    } else if (index == 5) {
      navIndex = 3; // Notes
    } else if (index == 6) {
      navIndex = 4; // Finance
    } else {
      navIndex = 0;
    }

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => index = 0);
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
            showGlobalSearchDialog(
              context,
              store,
              onNavigate: (value) => setState(() => index = value),
            );
          },
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
            showGlobalSearchDialog(
              context,
              store,
              onNavigate: (value) => setState(() => index = value),
            );
          },
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, size) {
              final wide = size.maxWidth >= 800;
              return Scaffold(
                drawer: wide
                    ? null
                    : _AppDrawer(
                        selectedIndex: index,
                        onSelected: (i) {
                          Navigator.pop(context);
                          setState(() => index = i);
                        },
                      ),
                body: Row(
                  children: [
                    if (wide)
                      AppRail(
                        selected: index,
                        onSelected: (value) => setState(() => index = value),
                      ),
                    Expanded(
                      child: SafeArea(
                        child: Column(
                          children: [
                            AppBarLine(
                              title: titles[index.clamp(0, titles.length - 1)],
                              onAdd: () => openQuickAdd(context, store, index),
                              onSearch: () => showGlobalSearchDialog(
                                context,
                                store,
                                onNavigate: (value) =>
                                    setState(() => index = value),
                              ),
                            ),
                            Expanded(
                              child:
                                  screens[index.clamp(0, screens.length - 1)],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                floatingActionButton: (wide || index == 9)
                    ? null
                    : FloatingActionButton(
                        backgroundColor: store.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        onPressed: () => openQuickAdd(context, store, index),
                        child: const Icon(Icons.add, size: 24),
                      ),
                bottomNavigationBar: wide
                    ? null
                    : NavigationBar(
                        height: 65,
                        selectedIndex: navIndex,
                        onDestinationSelected: (value) {
                          if (value == 0) setState(() => index = 0);
                          if (value == 1) setState(() => index = 1);
                          if (value == 2) setState(() => index = 3);
                          if (value == 3) setState(() => index = 5);
                          if (value == 4) setState(() => index = 6);
                        },
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: 'Home',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.check_circle_outline),
                            selectedIcon: Icon(Icons.check_circle),
                            label: 'Tasks',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.school_outlined),
                            selectedIcon: Icon(Icons.school),
                            label: 'Jadwal',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.notes_outlined),
                            selectedIcon: Icon(Icons.notes),
                            label: 'Notes',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.account_balance_wallet_outlined),
                            selectedIcon: Icon(Icons.account_balance_wallet),
                            label: 'Finance',
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final overdueCount = store.tasks
        .where((t) => !t.done && t.due.isBefore(now))
        .length;

    final navItems = [
      ('Overview', Icons.home_outlined, 0),
      ('To-Do List (Centang)', Icons.checklist_rounded, 2),
      ('Tasks & Agenda', Icons.check_circle_outline, 1),
      ('Jadwal Kuliah', Icons.school_outlined, 3),
      ('Kalender Terpadu', Icons.calendar_month_outlined, 4),
      ('Knowledge Base', Icons.notes_outlined, 5),
      ('Finance & Dompet', Icons.account_balance_wallet_outlined, 6),
      ('Habit Tracker', Icons.track_changes_outlined, 7),
      ('Memory Bank', Icons.auto_awesome_outlined, 8),
      ('AI Assistant', Icons.chat_bubble_outline_rounded, 9),
    ];

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: store.accentColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: SecBrainShieldIcon(
                      size: 28,
                      color: store.accentColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.userName.isNotEmpty
                              ? store.userName
                              : 'SecBrain',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          store.userEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  ...navItems.map((item) {
                    final isSelected = selectedIndex == item.$3;
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      selected: isSelected,
                      selectedTileColor: store.accentColor.withValues(
                        alpha: 0.12,
                      ),
                      selectedColor: store.accentColor,
                      leading: Icon(
                        item.$2,
                        size: 20,
                        color: isSelected ? store.accentColor : muted,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.$1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.$3 == 1 && overdueCount > 0)
                            OverdueBadge(count: overdueCount),
                        ],
                      ),
                      onTap: () => onSelected(item.$3),
                    );
                  }),
                  const Divider(height: 20),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.backup_outlined,
                      size: 20,
                      color: muted,
                    ),
                    title: const Text(
                      'Ekspor & Backup Data',
                      style: TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showBackupDialog(context, store);
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: muted,
                    ),
                    title: const Text(
                      'Pengaturan & Tema',
                      style: TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showProfileDialog(context, store);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRail extends StatelessWidget {
  const AppRail({super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final overdueCount = store.tasks
        .where((t) => !t.done && t.due.isBefore(now))
        .length;

    final railItems = [
      ('Overview', Icons.home_outlined, 0),
      ('To-Do List', Icons.checklist_rounded, 2),
      ('Tasks & Agenda', Icons.check_circle_outline, 1),
      ('Jadwal Kuliah', Icons.school_outlined, 3),
      ('Kalender Terpadu', Icons.calendar_month_outlined, 4),
      ('Knowledge Base', Icons.notes_outlined, 5),
      ('Finance', Icons.account_balance_wallet_outlined, 6),
      ('Habit Tracker', Icons.track_changes_outlined, 7),
      ('Memory Log', Icons.auto_awesome_outlined, 8),
      ('AI Assistant', Icons.chat_bubble_outline_rounded, 9),
    ];
    return Container(
      width: 238,
      color: isDark ? const Color(0xFF19201C) : const Color(0xFFEDF1ED),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SecBrainLogo(
              size: 26,
              showSubtitle: true,
              color: store.accentColor,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'WORKSPACE PERSONAL',
            style: TextStyle(
              color: Color(0xFFA0AAA2),
              fontSize: 9,
              letterSpacing: 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: railItems.length,
              itemBuilder: (context, idx) {
                final item = railItems[idx];
                final isSelected = selected == item.$3;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -2),
                      selected: isSelected,
                      selectedTileColor: isDark
                          ? const Color(0xFF26322C)
                          : Colors.white,
                      selectedColor: store.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => onSelected(item.$3),
                      leading: Icon(item.$2, size: 18),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.$1,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          if (item.$3 == 1 && overdueCount > 0)
                            OverdueBadge(count: overdueCount),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF26322C) : store.accentColor,
              borderRadius: BorderRadius.circular(9),
              border: isDark
                  ? Border.all(color: store.accentColor.withValues(alpha: 0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOCUS OF THE DAY',
                  style: TextStyle(
                    color: isDark
                        ? store.accentColor
                        : const Color(0xFFA8C6AE),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Make space for\nwhat matters.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 6),
                Text(
                  '3 of 5 priorities complete',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFFBCD2BF),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppBarLine extends StatelessWidget {
  const AppBarLine({
    super.key,
    required this.title,
    required this.onAdd,
    required this.onSearch,
  });
  final String title;
  final VoidCallback onAdd;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isMobile) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF26322C) : const Color(0xFFE6EAE5),
            ),
          ),
        ),
        child: Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded, size: 20, color: muted),
              tooltip: 'Pencarian Global',
            ),
            IconButton(
              onPressed: () => showProfileDialog(context, store),
              icon: CircleAvatar(
                radius: 12,
                backgroundColor: store.accentColor,
                child: Text(
                  store.userName.isNotEmpty
                      ? store.userName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              tooltip: 'Profil',
            ),
          ],
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF26322C) : const Color(0xFFE6EAE5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => showBackupDialog(context, store),
            icon: const Icon(Icons.backup_outlined, color: muted, size: 20),
            tooltip: 'Backup & Ekspor Data',
          ),
          IconButton(
            onPressed: () => showProfileDialog(context, store),
            icon: const Icon(Icons.person_outline, color: muted, size: 20),
            tooltip: 'Pengaturan Profil & Tema',
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search, color: muted, size: 20),
            tooltip: 'Pencarian Global (Ctrl+K)',
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada notifikasi baru')),
            ),
            icon: const Icon(Icons.notifications_none, color: muted, size: 20),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: store.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Quick add'),
          ),
        ],
      ),
    );
  }
}

class Heading extends StatelessWidget {
  const Heading({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });
  final String kicker;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: const TextStyle(
              color: Color(0xFFA0AAA2),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 10),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : ink,
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            subtitle,
            style: TextStyle(color: muted, fontSize: isMobile ? 12 : 13),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpen});
  final ValueChanged<int> onOpen;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final done = store.tasks.where((task) => task.done).length;
    final highPriorityOpen = store.tasks
        .where((task) => !task.done && task.priority == 'High')
        .length;

    final hour = DateTime.now().hour;
    final greetingTime = hour < 11
        ? 'Selamat Pagi'
        : (hour < 15
              ? 'Selamat Siang'
              : (hour < 18 ? 'Selamat Sore' : 'Selamat Malam'));
    final greeting =
        '$greetingTime, ${store.userName.isNotEmpty ? store.userName : 'Aditya'}.';

    final cardBg = isDark ? const Color(0xFF1D2420) : Colors.white;
    final greenCardBg = isDark
        ? store.accentColor.withValues(alpha: 0.18)
        : store.accentColor.withValues(alpha: 0.12);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        isMobile ? 16 : 30,
        isMobile ? 16 : 32,
        isMobile ? 24 : 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PERSONAL MEMORY BANK',
            style: TextStyle(
              color: Color(0xFFA0AAA2),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            greeting,
            style: TextStyle(
              color: isDark ? Colors.white : ink,
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A clear mind starts with a clear place for everything.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    'Today\'s focus',
                    '${store.tasks.length}',
                    '$done completed',
                    greenCardBg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    'Open tasks',
                    '${store.tasks.where((task) => !task.done).length}',
                    '$highPriorityOpen high priority',
                    cardBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    'Monthly spend',
                    money(store.totalExpense),
                    store.transactions.isEmpty
                        ? '0 transaksi'
                        : '${store.transactions.length} transaksi',
                    cardBg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    'Memory log',
                    '${store.memories.length}',
                    'saved memories',
                    cardBg,
                  ),
                ),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatCard(
                  'Today\'s focus',
                  '${store.tasks.length}',
                  '$done completed',
                  greenCardBg,
                  width: 220,
                ),
                StatCard(
                  'Open tasks',
                  '${store.tasks.where((task) => !task.done).length}',
                  '$highPriorityOpen high priority',
                  cardBg,
                  width: 220,
                ),
                StatCard(
                  'Monthly spend',
                  money(store.totalExpense),
                  store.transactions.isEmpty
                      ? 'Belum ada transaksi'
                      : '${store.transactions.length} transaksi tercatat',
                  cardBg,
                  width: 220,
                ),
                StatCard(
                  'Memory log',
                  '${store.memories.length}',
                  'saved memories',
                  cardBg,
                  width: 220,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // AI Assistant Quick Access Banner
          Card(
            color: isDark
                ? const Color(0xFF26322C)
                : store.accentColor.withValues(alpha: 0.12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: store.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onOpen(9),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: store.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Assistant & Smart Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketik "besok rapat jam 7 malam" atau "terima beasiswa 6jt" untuk aksi instan.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFA0AAA2) : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: store.accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Buka Chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          WeeklyInsightCard(store: store, onNavigate: onOpen),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final left = Column(
                children: [
                  TodoPanel(onOpen: () => onOpen(2)),
                  const SizedBox(height: 14),
                  TaskPanel(onOpen: () => onOpen(1)),
                  const SizedBox(height: 14),
                  NotesPanel(onOpen: () => onOpen(5)),
                ],
              );
              final right = Column(
                children: [
                  FinancePanel(onOpen: () => onOpen(6)),
                  const SizedBox(height: 14),
                  MemoryPanel(onOpen: () => onOpen(8)),
                ],
              );
              return constraints.maxWidth < 700
                  ? Column(children: [left, const SizedBox(height: 14), right])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 14),
                        Expanded(child: right),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard(
    this.label,
    this.value,
    this.detail,
    this.color, {
    super.key,
    this.width,
  });
  final String label;
  final String value;
  final String detail;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(color: muted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return content;
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : ink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class TodoPanel extends StatelessWidget {
  const TodoPanel({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayTodos = store.todos
        .where((t) => t.timeframe == TodoTimeframe.today)
        .toList();
    final doneCount = todayTodos.where((t) => t.done).length;

    return Panel(
      title: 'To-Do Hari Ini',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? store.accentColor.withValues(alpha: 0.2)
                  : store.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$doneCount/${todayTodos.length}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF86EFAC) : store.accentColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(onPressed: onOpen, child: const Text('Buka Semua')),
        ],
      ),
      child: todayTodos.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Belum ada to-do hari ini. Ketuk "Buka Semua" untuk menambah.',
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            )
          : Column(
              children: todayTodos
                  .take(4)
                  .map(
                    (todo) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () => store.toggleTodo(todo),
                      leading: Checkbox(
                        value: todo.done,
                        onChanged: (_) => store.toggleTodo(todo),
                        activeColor: store.accentColor,
                        shape: const CircleBorder(),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: todo.done
                              ? muted
                              : (isDark ? Colors.white : ink),
                          decoration: todo.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class TaskPanel extends StatelessWidget {
  const TaskPanel({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Panel(
      title: 'Today\'s tasks',
      action: TextButton(onPressed: onOpen, child: const Text('View all')),
      child: Column(
        children: store.tasks
            .take(4)
            .map((task) => TaskTile(task: task))
            .toList(),
      ),
    );
  }
}

class NotesPanel extends StatelessWidget {
  const NotesPanel({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Panel(
      title: 'Recent notes',
      action: TextButton(onPressed: onOpen, child: const Text('View all')),
      child: Column(
        children: store.notes
            .map(
              (note) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: note.type == 'Meeting'
                      ? blueLight
                      : amberLight,
                  child: Icon(
                    note.type == 'Meeting'
                        ? Icons.groups_outlined
                        : Icons.lightbulb_outline,
                    color: store.accentColor,
                  ),
                ),
                title: Text(
                  note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  note.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class FinancePanel extends StatelessWidget {
  const FinancePanel({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spent = store.totalExpense;
    final income = store.totalIncome;
    final balance = store.balance;
    final progress = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;

    return Panel(
      title: 'Finance snapshot',
      action: TextButton(onPressed: onOpen, child: const Text('Details')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance this month',
            style: TextStyle(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 7),
          Text(
            money(balance),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            color: spent > income && income > 0 ? coral : store.accentColor,
            backgroundColor: isDark
                ? const Color(0xFF26322C)
                : store.accentColor.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 8),
          Text(
            store.transactions.isEmpty
                ? 'Belum ada transaksi bulan ini'
                : 'Pengeluaran ${money(spent)} dari pemasukan ${money(income)}',
            style: const TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class MemoryPanel extends StatelessWidget {
  const MemoryPanel({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final memories = StoreScope.of(context).memories;
    return Panel(
      title: 'Latest memory',
      action: TextButton(onPressed: onOpen, child: const Text('View log')),
      child: memories.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Belum ada memory.',
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          : ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 46,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF536D68),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Center(
                  child: Text(
                    'FILM',
                    style: TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
              title: Text(
                memories.first.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${stars(memories.first.rating)} - ${memories.first.quote}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ),
    );
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _viewMode = 0; // 0: Agenda List, 1: Kanban Board

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, isMobile ? 12 : 20, hPad, 8),
          child: Row(
            children: [
              Expanded(
                child: isMobile
                    ? Text(
                        _viewMode == 0 ? 'Tasks & Agenda' : 'Kanban Board',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Heading(
                        kicker: 'AGENDA & PRIORITAS',
                        title: 'Tasks & Agenda',
                        subtitle: 'Pantau komitmen, prioritas Eisenhower Matrix, dan progres tugas.',
                      ),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.format_list_bulleted, size: 16),
                    label: Text('Agenda', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.view_kanban_outlined, size: 16),
                    label: Text('Kanban', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (val) =>
                    setState(() => _viewMode = val.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _viewMode == 1
              ? ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 30),
                  children: [
                    const SizedBox(height: 8),
                    KanbanBoard(store: store),
                    const SizedBox(height: 16),
                    const MatrixCard(),
                  ],
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 30),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Today\'s tasks',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      showTaskDialog(context, store),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add task'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (store.tasks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'Belum ada tugas. Klik "Add task" untuk menambahkan.',
                                    style: TextStyle(
                                      color: muted.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...store.tasks.map(
                                (task) => TaskTile(task: task, detailed: true),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const MatrixCard(),
                  ],
                ),
        ),
      ],
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.detailed = false});
  final Task task;
  final bool detailed;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isOverdue = !task.done && task.due.isBefore(now);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => store.toggleTask(task),
      leading: Checkbox(
        value: task.done,
        onChanged: (_) => store.toggleTask(task),
        activeColor: store.accentColor,
        shape: const CircleBorder(),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          color: task.done ? muted : (isDark ? Colors.white : ink),
          fontSize: detailed ? 13 : 12,
          fontWeight: FontWeight.w600,
          decoration: task.done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${task.due.day}/${task.due.month} ${task.due.hour.toString().padLeft(2, '0')}:${task.due.minute.toString().padLeft(2, '0')}${task.recurring == 'None' ? '' : ' • ${task.recurring}'}${isOverdue ? ' • Overdue' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isOverdue ? coral : muted,
          fontSize: 10,
          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TaskCategoryChip(category: task.category),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: task.priority == 'High' ? coralLight : amberLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              task.priority,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: task.priority == 'High'
                    ? coral
                    : const Color(0xFFD97706),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16, color: muted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onSelected: (value) {
              if (value == 'delete') store.deleteTask(task);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete task')),
            ],
          ),
        ],
      ),
    );
  }
}

class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key});
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'September 2026',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                  .map(
                    (day) => Text(
                      day,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 1.5,
              children: List.generate(35, (index) {
                final day = index == 0 ? 31 : index;
                final current = day == 23;
                return Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current ? store.accentColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: current ? Colors.white : (isDark ? Colors.white : ink),
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class MatrixCard extends StatelessWidget {
  const MatrixCard({super.key});
  @override
  Widget build(BuildContext context) {
    final tasks = StoreScope.of(context).tasks;
    final groups = {
      'Do first': tasks.where((task) => task.priority == 'High').toList(),
      'Schedule': tasks.where((task) => task.priority == 'Medium').toList(),
      'Delegate': tasks.where((task) => task.priority == 'Low').toList(),
      'Eliminate': <Task>[],
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eisenhower matrix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: groups.entries
                  .map(
                    (entry) => Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: entry.key == 'Do first'
                            ? coralLight
                            : entry.key == 'Schedule'
                            ? amberLight
                            : blueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${entry.value.length} tasks',
                            style: const TextStyle(color: muted, fontSize: 10),
                          ),
                          ...entry.value
                              .take(2)
                              .map(
                                (task) => Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedDay = 'Semua';

  final _days = const [
    'Semua',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;
    final filteredSchedules = _selectedDay == 'Semua'
        ? store.schedules
        : store.schedules.where((s) => s.day == _selectedDay).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 24, hPad, 30),
      children: [
        if (isMobile) ...[
          const Heading(
            kicker: 'ACADEMIC SCHEDULE',
            title: 'Jadwal Mata Kuliah',
            subtitle: 'Kelola waktu kuliah, ruang kelas, dan dosen pengampu dengan rapi.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => showScheduleDialog(context, store),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add schedule'),
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Heading(
                  kicker: 'ACADEMIC SCHEDULE',
                  title: 'Jadwal Mata Kuliah',
                  subtitle: 'Kelola waktu kuliah, ruang kelas, dan dosen pengampu dengan rapi.',
                ),
              ),
              FilledButton.icon(
                onPressed: () => showScheduleDialog(context, store),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add schedule'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Day filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.map((day) {
              final isSelected = _selectedDay == day;
              final count = day == 'Semua'
                  ? store.schedules.length
                  : store.schedules.where((s) => s.day == day).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$day ($count)'),
                  selected: isSelected,
                  selectedColor: isDark
                      ? store.accentColor.withValues(alpha: 0.25)
                      : store.accentColor.withValues(alpha: 0.12),
                  backgroundColor: isDark
                      ? const Color(0xFF1D2420)
                      : Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (isDark ? const Color(0xFF86EFAC) : store.accentColor)
                        : (isDark ? Colors.white70 : ink),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? (isDark ? const Color(0xFF86EFAC) : store.accentColor)
                        : muted.withValues(alpha: 0.2),
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _selectedDay = day);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (filteredSchedules.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? store.accentColor.withValues(alpha: 0.2)
                            : store.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        size: 32,
                        color: store.accentColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _selectedDay == 'Semua'
                          ? 'Belum ada jadwal mata kuliah'
                          : 'Tidak ada jadwal di hari $_selectedDay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedDay == 'Semua'
                          ? 'Tambahkan mata kuliah untuk memantau agenda perkuliahan mingguan Anda.'
                          : 'Waktu yang tepat untuk istirahat, mengulang materi, atau mengerjakan tugas.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showScheduleDialog(
                        context,
                        store,
                        initialDay: _selectedDay == 'Semua'
                            ? 'Senin'
                            : _selectedDay,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Jadwal Kuliah'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...filteredSchedules.map((schedule) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? store.accentColor.withValues(alpha: 0.2)
                            : store.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 16,
                            color: store.accentColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            schedule.startTime,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF86EFAC)
                                  : store.accentColor,
                            ),
                          ),
                          Text(
                            schedule.endTime,
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF38321D)
                                      : amberLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  schedule.day,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isDark
                                        ? const Color(0xFFFDE047)
                                        : ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1D2F38)
                                      : blueLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${schedule.sks} SKS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isDark
                                        ? const Color(0xFF93C5FD)
                                        : ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            schedule.courseName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.room_outlined,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  schedule.room,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  schedule.lecturer,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: muted),
                      onSelected: (val) {
                        if (val == 'edit') {
                          showScheduleDialog(
                            context,
                            store,
                            schedule: schedule,
                          );
                        } else if (val == 'delete') {
                          store.deleteSchedule(schedule);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: isDark ? Colors.white : ink),
                              const SizedBox(width: 8),
                              const Text('Edit Jadwal'),
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
                              Text(
                                'Hapus Jadwal',
                                style: TextStyle(color: coral),
                              ),
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
      ],
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _selectedTag;

  Color _noteColor(String type) {
    switch (type) {
      case 'Meeting':
      case 'Agenda Rapat':
        return blueLight;
      case 'Client':
      case 'Notulensi Klien':
        return greenLight;
      case 'Workshop':
      case 'Catatan Workshop':
        return coralLight;
      default:
        return amberLight;
    }
  }

  IconData _noteIcon(String type) {
    switch (type) {
      case 'Meeting':
      case 'Agenda Rapat':
        return Icons.groups_outlined;
      case 'Client':
      case 'Notulensi Klien':
        return Icons.business_center_outlined;
      case 'Workshop':
      case 'Catatan Workshop':
        return Icons.school_outlined;
      default:
        return Icons.edit_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;
    final allTags = <String>{};
    for (final n in store.notes) {
      allTags.addAll(n.tags);
    }

    final displayedNotes = _selectedTag == null
        ? store.notes
        : store.notes.where((n) => n.tags.contains(_selectedTag)).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => store.load(),
      color: store.accentColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 24, hPad, 30),
        children: [
          if (isMobile) ...[
            const Heading(
              kicker: 'PERSONAL KNOWLEDGE BASE',
              title: 'Notes & Knowledge',
              subtitle: 'Capture context before the details disappear.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => showNoteDialog(context, store),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New note'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (allTags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      selected: _selectedTag == null,
                      label: const Text(
                        'Semua Tag',
                        style: TextStyle(fontSize: 11),
                      ),
                      selectedColor: greenLight,
                      onSelected: (_) => setState(() => _selectedTag = null),
                    ),
                    const SizedBox(width: 6),
                    ...allTags.map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          selected: _selectedTag == tag,
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selectedColor: greenLight,
                          onSelected: (_) => setState(() => _selectedTag = tag),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            const Heading(
              kicker: 'PERSONAL KNOWLEDGE BASE',
              title: 'Notes & Knowledge',
              subtitle: 'Capture context before the details disappear.',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (allTags.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            selected: _selectedTag == null,
                            label: const Text(
                              'Semua Tag',
                              style: TextStyle(fontSize: 11),
                            ),
                            selectedColor: greenLight,
                            onSelected: (_) =>
                                setState(() => _selectedTag = null),
                          ),
                          const SizedBox(width: 6),
                          ...allTags.map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                selected: _selectedTag == tag,
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                selectedColor: greenLight,
                                onSelected: (_) =>
                                    setState(() => _selectedTag = tag),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                FilledButton.icon(
                  onPressed: () => showNoteDialog(context, store),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New note'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (displayedNotes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF38321D)
                              : amberLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_outlined,
                          size: 32,
                          color: store.accentColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _selectedTag != null
                            ? 'Tidak ada catatan dengan tag "$_selectedTag"'
                            : 'Belum ada catatan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedTag != null
                            ? 'Coba pilih filter tag lain atau buat catatan baru dengan tag ini.'
                            : 'Mulai simpan ide, agenda rapat, atau notulensi penting dengan memilih template yang tersedia.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => showNoteDialog(context, store),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Buat Catatan'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...displayedNotes.map(
              (note) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  onTap: () => showNoteDetailDialog(context, store, note),
                  leading: CircleAvatar(
                    backgroundColor: _noteColor(note.type),
                    child: Icon(_noteIcon(note.type), color: store.accentColor),
                  ),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          '${note.type} - ${note.body}',
                          style: const TextStyle(color: muted),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: note.tags
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? store.accentColor.withValues(alpha: 0.2)
                                        : store.accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF86EFAC)
                                          : store.accentColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: muted),
                    onSelected: (value) {
                      if (value == 'view') {
                        showNoteDetailDialog(context, store, note);
                      } else if (value == 'edit') {
                        showNoteEditDialog(context, store, note);
                      } else if (value == 'delete') {
                        store.deleteNote(note);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Lihat Detail'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Catatan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: coral),
                            SizedBox(width: 8),
                            Text(
                              'Hapus Catatan',
                              style: TextStyle(color: coral),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;
    final income = store.totalIncome;
    final expense = store.totalExpense;
    final balance = store.balance;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 24, hPad, 30),
      children: [
        if (isMobile) ...[
          const Heading(
            kicker: 'MONEY, WITH CLARITY',
            title: 'Finance Tracker',
            subtitle: 'See your balance, goals, and spending in one calm view.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: store.accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => showFinanceAnalysisDialog(context, store),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Analisis AI'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Metric('Income', money(income), greenLight)),
              const SizedBox(width: 8),
              Expanded(child: Metric('Expenses', money(expense), coralLight)),
            ],
          ),
          const SizedBox(height: 8),
          Metric('Balance', money(balance), amberLight),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Heading(
                  kicker: 'MONEY, WITH CLARITY',
                  title: 'Finance Tracker',
                  subtitle:
                      'See your balance, goals, and spending in one calm view.',
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: store.accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => showFinanceAnalysisDialog(context, store),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Analisis AI'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Metric('Income', money(income), greenLight)),
              const SizedBox(width: 12),
              Expanded(child: Metric('Expenses', money(expense), coralLight)),
              const SizedBox(width: 12),
              Expanded(child: Metric('Balance', money(balance), amberLight)),
            ],
          ),
        ],
        const SizedBox(height: 18),
        FinanceCategoryChart(store: store),
        const SizedBox(height: 18),
        FinanceTrendChart(store: store),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transactions ${store.transactions.isNotEmpty ? '(${store.transactions.length})' : ''}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showTransactionDialog(context, store),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add entry'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (store.transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 16,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? store.accentColor.withValues(alpha: 0.2)
                                  : store.accentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 32,
                              color: store.accentColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Catat pemasukan atau pengeluaran Anda untuk melihat ringkasan keuangan secara real-time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                showTransactionDialog(context, store),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah Transaksi Pertama'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...store.transactions.map((item) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: item.income
                            ? (isDark ? store.accentColor.withValues(alpha: 0.2) : store.accentColor.withValues(alpha: 0.12))
                            : (isDark ? coral.withValues(alpha: 0.2) : coralLight),
                        child: Icon(
                          item.income ? Icons.south_west : Icons.north_east,
                          color: item.income
                              ? (isDark ? const Color(0xFF86EFAC) : store.accentColor)
                              : coral,
                          size: 17,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${item.category} • ${item.date.day}/${item.date.month}/${item.date.year}',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.income ? '+' : '-'} ${money(item.amount)}',
                            style: TextStyle(
                              color: item.income
                                  ? (isDark ? const Color(0xFF86EFAC) : store.accentColor)
                                  : coral,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 16,
                              color: muted,
                            ),
                            onSelected: (val) {
                              if (val == 'delete') {
                                store.deleteTransaction(item);
                              }
                            },
                            itemBuilder: (context) => const [
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
                                    Text(
                                      'Hapus',
                                      style: TextStyle(color: coral),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SavingsCard(),
        const SizedBox(height: 14),
        BillsCard(),
        const SizedBox(height: 14),
        InvestmentsCard(),
      ],
    );
  }
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, this.color, {super.key});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color effectiveBg = color;
    Color effectiveTextColor = isDark ? Colors.white : ink;
    if (isDark) {
      if (color == greenLight) {
        effectiveBg = const Color(0xFF1F352B);
        effectiveTextColor = const Color(0xFF86EFAC);
      } else if (color == coralLight) {
        effectiveBg = const Color(0xFF382320);
        effectiveTextColor = const Color(0xFFFCA5A5);
      } else if (color == amberLight) {
        effectiveBg = const Color(0xFF38321D);
        effectiveTextColor = const Color(0xFFFDE047);
      } else {
        effectiveBg = const Color(0xFF1D2420);
      }
    }
    return Card(
      color: effectiveBg,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : muted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavingsCard extends StatelessWidget {
  const SavingsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Savings goal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showSavingsGoalDialog(context, store),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add goal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (store.savingsGoals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF19201C) : paper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: muted.withValues(alpha: 0.15)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        color: muted,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada target tabungan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tetapkan target impian Anda untuk memantau progres tabungan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...store.savingsGoals.map((goal) {
                final ratio = goal.targetAmount > 0
                    ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                    : 0.0;
                final percentage = (ratio * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            color: store.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              goal.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF86EFAC) : store.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 16,
                              color: muted,
                            ),
                            onSelected: (val) {
                              if (val == 'delete') {
                                store.deleteSavingsGoal(goal);
                              }
                            },
                            itemBuilder: (context) => const [
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
                                    Text(
                                      'Hapus Target',
                                      style: TextStyle(color: coral),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: ratio,
                        color: store.accentColor,
                        backgroundColor: isDark
                            ? const Color(0xFF26322C)
                            : store.accentColor.withValues(alpha: 0.15),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${money(goal.currentAmount)} of ${money(goal.targetAmount)}${goal.targetDate.isNotEmpty ? ' - Target ${goal.targetDate}' : ''}',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

Future<void> showSavingsGoalDialog(
  BuildContext context,
  BrainStore store,
) async {
  final title = TextEditingController();
  final targetAmount = TextEditingController();
  final currentAmount = TextEditingController();
  final targetDate = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.savings_outlined, color: store.accentColor),
          const SizedBox(width: 8),
          const Text('Target Tabungan Baru'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Target',
                hintText: 'e.g. Dana Darurat, Laptop Baru',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetAmount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Nominal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: currentAmount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Terkumpul',
                prefixText: 'Rp ',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetDate,
              decoration: const InputDecoration(
                labelText: 'Batas Waktu / Catatan (Opsional)',
                hintText: 'e.g. Des 2026',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: store.accentColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final target = double.tryParse(
              targetAmount.text.replaceAll('.', '').replaceAll(',', ''),
            );
            final current =
                double.tryParse(
                  currentAmount.text.replaceAll('.', '').replaceAll(',', ''),
                ) ??
                0.0;

            if (title.text.trim().isEmpty || target == null || target <= 0) {
              return;
            }
            store.addSavingsGoal(
              SavingsGoal(
                title.text.trim(),
                target,
                current,
                targetDate: targetDate.text.trim(),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Simpan Target'),
        ),
      ],
    ),
  );
}

class BillsCard extends StatelessWidget {
  const BillsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final total = store.bills.fold(0.0, (sum, b) => sum + b.amount);

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
                        'Bills & subscriptions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (store.bills.isNotEmpty)
                        Text(
                          'Total rutin: ${money(total)} / bulan',
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showBillDialog(context, store),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (store.bills.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: muted.withValues(alpha: 0.5),
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Belum ada tagihan rutin',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...store.bills.map(
                (bill) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: amberLight,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: store.accentColor,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    bill.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${bill.category} - due every ${bill.dueDay}th',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        money(bill.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 16,
                          color: muted,
                        ),
                        onSelected: (val) {
                          if (val == 'delete') store.deleteBill(bill);
                        },
                        itemBuilder: (context) => const [
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
                                Text(
                                  'Hapus Tagihan',
                                  style: TextStyle(color: coral),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InvestmentsCard extends StatelessWidget {
  const InvestmentsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPortfolio = store.investments.fold(
      0.0,
      (sum, i) => sum + i.value,
    );

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
                        'Investments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (store.investments.isNotEmpty)
                        Text(
                          'Portfolio: ${money(totalPortfolio)}',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF86EFAC) : store.accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showInvestmentDialog(context, store),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (store.investments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: muted.withValues(alpha: 0.5),
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Belum ada data investasi',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...store.investments.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: blueLight,
                    child: Icon(Icons.trending_up, color: green, size: 18),
                  ),
                  title: Text(
                    '${item.name} (${item.symbol})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.units} units - avg ${money(item.averagePrice)}',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        money(item.value),
                        style: const TextStyle(
                          color: green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 16,
                          color: muted,
                        ),
                        onSelected: (val) {
                          if (val == 'delete') store.deleteInvestment(item);
                        },
                        itemBuilder: (context) => const [
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
                                Text(
                                  'Hapus Investasi',
                                  style: TextStyle(color: coral),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 32.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 16 : 24, hPad, 30),
      children: [
        if (isMobile) ...[
          const Heading(
            kicker: 'YOUR MEMORY LOG',
            title: 'Memories',
            subtitle: 'Keep the stories, ideas, and works that stay with you.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => showMemoryDialog(context, store),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log a memory'),
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Heading(
                  kicker: 'YOUR MEMORY LOG',
                  title: 'Memories',
                  subtitle:
                      'Keep the stories, ideas, and works that stay with you.',
                ),
              ),
              FilledButton.icon(
                onPressed: () => showMemoryDialog(context, store),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log a memory'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        ...store.memories.map(
          (memory) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFF536D68),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: memory.coverUrl.isEmpty
                        ? Center(
                            child: Text(
                              memory.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              memory.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Center(
                                child: Text(
                                  memory.type.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.type.toUpperCase(),
                          style: const TextStyle(
                            color: coral,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          stars(memory.rating),
                          style: const TextStyle(color: Color(0xFFC8A85A)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          memory.review,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${memory.quote}"',
                          style: const TextStyle(
                            color: muted,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') store.deleteMemory(memory);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete memory'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BrainSearchDelegate extends SearchDelegate<String> {
  BrainSearchDelegate(this.store);
  final BrainStore store;
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, ''),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) => _results();
  @override
  Widget buildSuggestions(BuildContext context) => _results();
  Widget _results() {
    final text = query.toLowerCase();
    final taskResults = store.tasks
        .where((item) => item.title.toLowerCase().contains(text))
        .map((item) => 'Task - ${item.title}');
    final noteResults = store.notes
        .where(
          (item) => '${item.title} ${item.body}'.toLowerCase().contains(text),
        )
        .map((item) => 'Note - ${item.title}');
    final memoryResults = store.memories
        .where(
          (item) => '${item.title} ${item.type}'.toLowerCase().contains(text),
        )
        .map((item) => 'Memory - ${item.title}');
    final results = [...taskResults, ...noteResults, ...memoryResults];
    return ListView(
      children: results.isEmpty
          ? [const ListTile(title: Text('No results found'))]
          : results
                .map(
                  (item) => ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(item),
                  ),
                )
                .toList(),
    );
  }
}

Future<void> openQuickAdd(BuildContext context, BrainStore store, int page) {
  if (page == 1) return showTaskDialog(context, store);
  if (page == 2 || page == 10) return showAddTodoDialog(context, store);
  if (page == 3) return showScheduleDialog(context, store);
  if (page == 4) return showTaskDialog(context, store);
  if (page == 5) return showNoteDialog(context, store);
  if (page == 6) return showTransactionDialog(context, store);
  if (page == 7) return showHabitDialog(context, store);
  if (page == 8) return showMemoryDialog(context, store);
  return showTaskDialog(context, store);
}

Future<void> showAddTodoDialog(BuildContext context, BrainStore store) async {
  final controller = TextEditingController();
  var timeframe = TodoTimeframe.today;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.checklist_rounded, color: store.accentColor),
            const SizedBox(width: 8),
            const Text('Tambah To-Do', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Target / Checklist',
                  hintText: 'Contoh: Selesaikan revisi bab 3...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Rentang Waktu:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: TodoTimeframe.values.map((tf) {
                  final isSel = timeframe == tf;
                  return ChoiceChip(
                    label: Text(tf.label, style: const TextStyle(fontSize: 11)),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setDialogState(() => timeframe = tf);
                    },
                    selectedColor: store.accentColor.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: store.accentColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                store.addTodo(TodoItem(title: text, timeframe: timeframe));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showTaskDialog(BuildContext context, BrainStore store) async {
  final title = TextEditingController();
  var category = 'Personal';
  var priority = 'Medium';
  var due = DateTime.now().add(const Duration(hours: 2));
  var recurring = 'None';
  var urgent = false;
  var important = true;
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Personal', 'University', 'Work', 'Organization']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => category = value!,
            ),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ['High', 'Medium', 'Low']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => priority = value!,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline'),
              subtitle: Text(
                '${due.day}/${due.month}/${due.year} ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                    initialDate: due,
                  );
                  if (picked != null) {
                    due = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      due.hour,
                      due.minute,
                    );
                  }
                },
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: recurring,
              decoration: const InputDecoration(labelText: 'Recurring'),
              items: ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => recurring = value!,
            ),
            StatefulBuilder(
              builder: (context, setLocal) => Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Urgent'),
                    value: urgent,
                    onChanged: (value) => setLocal(() => urgent = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Important'),
                    value: important,
                    onChanged: (value) => setLocal(() => important = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (title.text.trim().isEmpty) return;
            store.addTask(
              Task(
                title.text.trim(),
                category,
                priority,
                due: due,
                recurring: recurring,
                urgent: urgent,
                important: important,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Add task'),
        ),
      ],
    ),
  );
}

class _NewNoteDialog extends StatefulWidget {
  const _NewNoteDialog({required this.store});
  final BrainStore store;

  @override
  State<_NewNoteDialog> createState() => _NewNoteDialogState();
}

class _NewNoteDialogState extends State<_NewNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();
  NoteTemplate _selectedTemplate = noteTemplates.first;
  List<String> _linkedTasks = [];
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onSelectTemplate(NoteTemplate template) {
    if (_selectedTemplate.id == template.id) return;

    setState(() {
      final prevTemplate = _selectedTemplate;
      _selectedTemplate = template;

      // Template injection:
      if (_bodyController.text.trim().isEmpty ||
          _bodyController.text == prevTemplate.bodyContent) {
        _bodyController.text = template.bodyContent;
      } else if (template.bodyContent.isNotEmpty) {
        _bodyController.text = template.bodyContent;
      } else if (template.id == 'free') {
        if (_bodyController.text == prevTemplate.bodyContent) {
          _bodyController.text = '';
        }
      }

      // Title suggestion injection:
      if (_titleController.text.isEmpty ||
          _titleController.text == prevTemplate.defaultTitle) {
        _titleController.text = template.defaultTitle;
      }
    });
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Judul catatan tidak boleh kosong');
      return;
    }
    final body = _bodyController.text.trim();
    final rawTags = _tagsController.text
        .split(RegExp(r'[,\s]+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.startsWith('#') ? t : '#$t')
        .toList();
    widget.store.addNote(
      Note(
        title,
        body,
        _selectedTemplate.category,
        tags: rawTags,
        linkedTaskTitles: _linkedTasks,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? widget.store.accentColor.withValues(alpha: 0.2)
                          : widget.store.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.note_add_outlined,
                      color: widget.store.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Baru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : ink,
                          ),
                        ),
                        const Text(
                          'Pilih template untuk kerangka instan & terstruktur',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: muted),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Template Selector Chips
              const Text(
                'PILIH TEMPLATE',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: noteTemplates.map((template) {
                    final isSelected = _selectedTemplate.id == template.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          template.icon,
                          size: 16,
                          color: isSelected ? widget.store.accentColor : muted,
                        ),
                        label: Text(template.label),
                        selected: isSelected,
                        selectedColor: isDark
                            ? widget.store.accentColor.withValues(alpha: 0.25)
                            : widget.store.accentColor.withValues(alpha: 0.12),
                        backgroundColor: isDark ? const Color(0xFF26322C) : paper,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? widget.store.accentColor
                              : (isDark ? Colors.white70 : ink),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? widget.store.accentColor
                              : muted.withValues(alpha: 0.25),
                          width: isSelected ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) _onSelectTemplate(template);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        autofocus: false,
                        decoration: InputDecoration(
                          labelText: 'Judul Catatan',
                          hintText: _selectedTemplate.defaultTitleHint,
                          errorText: _titleError,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26322C) : paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (text) {
                          if (_titleError != null && text.trim().isNotEmpty) {
                            setState(() => _titleError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: 'Tagar / Tags (opsional)',
                          hintText: 'Contoh: #skripsi, #ide, #kuliah',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26322C) : paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_linkedTasks.isNotEmpty) ...[
                        CrossLinkChips(
                          linkedTaskTitles: _linkedTasks,
                          isEditable: true,
                          onRemove: (task) =>
                              setState(() => _linkedTasks.remove(task)),
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await showDialog<List<String>>(
                            context: context,
                            builder: (ctx) => TaskLinkSelectorDialog(
                              availableTasks: widget.store.tasks,
                              initiallySelected: _linkedTasks,
                            ),
                          );
                          if (res != null) setState(() => _linkedTasks = res);
                        },
                        icon: const Icon(Icons.link_rounded, size: 16),
                        label: Text(
                          _linkedTasks.isEmpty
                              ? 'Tautkan Task Terkait (Opsional)'
                              : 'Tautan Task (${_linkedTasks.length})',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bodyController,
                        minLines: 8,
                        maxLines: 14,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Isi Catatan',
                          hintText: 'Tulis isi catatan di sini atau gunakan kerangka template...',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26322C) : paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: muted)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.store.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _saveNote,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Simpan Catatan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showNoteDialog(BuildContext context, BrainStore store) async {
  await showDialog(
    context: context,
    builder: (context) => _NewNoteDialog(store: store),
  );
}

Future<void> showNoteDetailDialog(
  BuildContext context,
  BrainStore store,
  Note note,
) async {
  await showDialog(
    context: context,
    builder: (context) => _NoteDetailDialog(store: store, note: note),
  );
}

class _NoteDetailDialog extends StatefulWidget {
  const _NoteDetailDialog({required this.store, required this.note});
  final BrainStore store;
  final Note note;

  @override
  State<_NoteDetailDialog> createState() => _NoteDetailDialogState();
}

class _NoteDetailDialogState extends State<_NoteDetailDialog> {
  bool _loadingAi = false;
  String? _aiSummary;

  Future<void> _generateSummary() async {
    setState(() => _loadingAi = true);
    final summary = await AIService.summarizeNote(
      title: widget.note.title,
      body: widget.note.body,
      apiKey: widget.store.geminiApiKey,
    );
    if (mounted) {
      setState(() {
        _loadingAi = false;
        _aiSummary = summary;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? widget.store.accentColor.withValues(alpha: 0.2)
                          : widget.store.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.note.type,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : widget.store.accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: muted),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                widget.note.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : ink,
                ),
              ),
              if (widget.note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.note.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? widget.store.accentColor.withValues(alpha: 0.2)
                                : widget.store.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF86EFAC)
                                  : widget.store.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (widget.note.linkedTaskTitles.isNotEmpty) ...[
                const SizedBox(height: 10),
                CrossLinkChips(linkedTaskTitles: widget.note.linkedTaskTitles),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              // Body content & AI Summary
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF26322C) : paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE6EAE5),
                          ),
                        ),
                        child: SelectableText(
                          widget.note.body.isEmpty
                              ? '(Catatan ini belum memiliki isi)'
                              : widget.note.body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? Colors.white : ink,
                            fontFamily: widget.note.body.contains('\n')
                                ? 'monospace'
                                : null,
                          ),
                        ),
                      ),
                      if (_aiSummary != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? widget.store.accentColor.withValues(alpha: 0.15)
                                : widget.store.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.store.accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: isDark
                                        ? const Color(0xFF86EFAC)
                                        : widget.store.accentColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hasil Rangkuman Gemini AI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF86EFAC)
                                          : widget.store.accentColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _aiSummary!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: isDark ? Colors.white : ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Actions
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: coral,
                          side: const BorderSide(color: coral),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          widget.store.deleteNote(widget.note);
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Catatan berhasil dihapus'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Hapus'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final textToShare =
                              '${widget.note.title}\n\n${widget.note.body}\n\n---\nDibagikan dari SecBrain';
                          Clipboard.setData(ClipboardData(text: textToShare));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Isi catatan disalin ke clipboard'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Salin'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.store.accentColor,
                          side: BorderSide(color: widget.store.accentColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _loadingAi ? null : _generateSummary,
                        icon: _loadingAi
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(_loadingAi ? 'Meringkas...' : 'Rangkum AI'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(color: muted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.store.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          final navCtx = Navigator.of(
                            context,
                            rootNavigator: true,
                          ).context;
                          Navigator.pop(context);
                          showNoteEditDialog(navCtx, widget.store, widget.note);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Catatan'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showNoteEditDialog(
  BuildContext context,
  BrainStore store,
  Note note,
) async {
  await showDialog(
    context: context,
    builder: (context) => _NoteEditDialog(store: store, note: note),
  );
}

class _NoteEditDialog extends StatefulWidget {
  const _NoteEditDialog({required this.store, required this.note});
  final BrainStore store;
  final Note note;

  @override
  State<_NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<_NoteEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagsController;
  late List<String> _linkedTasks;
  late String _type;
  String? _titleError;

  final _typeOptions = const [
    'Catatan Bebas',
    'Agenda Rapat',
    'Notulensi Klien',
    'Catatan Workshop',
    'Ide Proyek',
    'Jurnal',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _bodyController = TextEditingController(text: widget.note.body);
    _tagsController = TextEditingController(text: widget.note.tags.join(', '));
    _linkedTasks = List.from(widget.note.linkedTaskTitles);
    _type = widget.note.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Judul catatan tidak boleh kosong');
      return;
    }
    final body = _bodyController.text.trim();
    final rawTags = _tagsController.text
        .split(RegExp(r'[,\s]+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.startsWith('#') ? t : '#$t')
        .toList();
    widget.store.updateNote(
      widget.note,
      title,
      body,
      _type,
      rawTags,
      _linkedTasks,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Catatan berhasil diperbarui')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? widget.store.accentColor.withValues(alpha: 0.2)
                          : widget.store.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_note_outlined,
                      color: widget.store.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Catatan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : ink,
                          ),
                        ),
                        const Text(
                          'Perbarui judul atau isi catatan Anda',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: muted),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(_type),
                        initialValue: _typeOptions.contains(_type)
                            ? _type
                            : _typeOptions.first,
                        decoration: InputDecoration(
                          labelText: 'Kategori Catatan',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26322C) : paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: _typeOptions
                            .map(
                              (opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _type = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Judul Catatan',
                          errorText: _titleError,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26322C) : paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (text) {
                          if (_titleError != null && text.trim().isNotEmpty) {
                            setState(() => _titleError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: 'Tagar / Tags (pisahkan koma)',
                          hintText: 'Misal: #skripsi, #ide, #kuliah',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26322C) : paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_linkedTasks.isNotEmpty) ...[
                        CrossLinkChips(
                          linkedTaskTitles: _linkedTasks,
                          isEditable: true,
                          onRemove: (task) =>
                              setState(() => _linkedTasks.remove(task)),
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await showDialog<List<String>>(
                            context: context,
                            builder: (ctx) => TaskLinkSelectorDialog(
                              availableTasks: widget.store.tasks,
                              initiallySelected: _linkedTasks,
                            ),
                          );
                          if (res != null) setState(() => _linkedTasks = res);
                        },
                        icon: const Icon(Icons.link_rounded, size: 16),
                        label: Text(
                          _linkedTasks.isEmpty
                              ? 'Tautkan Task Terkait'
                              : 'Tautan Task (${_linkedTasks.length})',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bodyController,
                        minLines: 8,
                        maxLines: 14,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Isi Catatan',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26322C) : paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: muted)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.store.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showScheduleDialog(
  BuildContext context,
  BrainStore store, {
  CourseSchedule? schedule,
  String? initialDay,
}) async {
  await showDialog(
    context: context,
    builder: (context) => _ScheduleDialog(
      store: store,
      schedule: schedule,
      initialDay: initialDay,
    ),
  );
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({required this.store, this.schedule, this.initialDay});
  final BrainStore store;
  final CourseSchedule? schedule;
  final String? initialDay;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final TextEditingController _courseController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _roomController;
  late final TextEditingController _lecturerController;

  late String _day;
  late int _sks;
  String? _courseError;
  String? _roomError;
  String? _lecturerError;

  final _days = const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  final _sksOptions = const [1, 2, 3, 4, 6];

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _courseController = TextEditingController(text: s?.courseName ?? '');
    _startTimeController = TextEditingController(text: s?.startTime ?? '08:00');
    _endTimeController = TextEditingController(text: s?.endTime ?? '09:40');
    _roomController = TextEditingController(text: s?.room ?? '');
    _lecturerController = TextEditingController(text: s?.lecturer ?? '');
    _day = s?.day ?? widget.initialDay ?? 'Senin';
    _sks = s?.sks ?? 3;
  }

  @override
  void dispose() {
    _courseController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _roomController.dispose();
    _lecturerController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final initialMin = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
    );
    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hourStr:$minStr';
      });
    }
  }

  void _save() {
    final course = _courseController.text.trim();
    final start = _startTimeController.text.trim();
    final end = _endTimeController.text.trim();
    final room = _roomController.text.trim();
    final lecturer = _lecturerController.text.trim();

    bool hasError = false;
    if (course.isEmpty) {
      setState(() => _courseError = 'Nama mata kuliah tidak boleh kosong');
      hasError = true;
    }
    if (room.isEmpty) {
      setState(() => _roomError = 'Ruang kelas / gedung harus diisi');
      hasError = true;
    }
    if (lecturer.isEmpty) {
      setState(() => _lecturerError = 'Nama dosen harus diisi');
      hasError = true;
    }

    if (hasError) return;

    if (widget.schedule == null) {
      widget.store.addSchedule(
        CourseSchedule(
          courseName: course,
          day: _day,
          startTime: start.isEmpty ? '08:00' : start,
          endTime: end.isEmpty ? '09:40' : end,
          room: room,
          lecturer: lecturer,
          sks: _sks,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal kuliah berhasil ditambahkan')),
      );
    } else {
      widget.store.updateSchedule(
        widget.schedule!,
        CourseSchedule(
          id: widget.schedule!.id,
          courseName: course,
          day: _day,
          startTime: start.isEmpty ? '08:00' : start,
          endTime: end.isEmpty ? '09:40' : end,
          room: room,
          lecturer: lecturer,
          sks: _sks,
          colorIndex: widget.schedule!.colorIndex,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal kuliah berhasil diperbarui')),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFill = isDark ? const Color(0xFF26322C) : paper;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? widget.store.accentColor.withValues(alpha: 0.2)
                          : widget.store.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      color: widget.store.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Jadwal Kuliah'
                              : 'Tambah Jadwal Kuliah',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : ink,
                          ),
                        ),
                        const Text(
                          'Catat mata kuliah, waktu, dosen, dan lokasi kelas',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: muted),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Name
                      TextField(
                        controller: _courseController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Nama Mata Kuliah',
                          hintText: 'Contoh: Algoritma & Pemrograman',
                          errorText: _courseError,
                          filled: true,
                          fillColor: fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (text) {
                          if (_courseError != null && text.trim().isNotEmpty) {
                            setState(() => _courseError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Day & SKS Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _day,
                              decoration: InputDecoration(
                                labelText: 'Hari',
                                filled: true,
                                fillColor: fieldFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _days
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _day = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              initialValue: _sks,
                              decoration: InputDecoration(
                                labelText: 'Bobot SKS',
                                filled: true,
                                fillColor: fieldFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _sksOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text('$s SKS'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _sks = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Start and End Time
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startTimeController,
                              readOnly: true,
                              onTap: () => _pickTime(_startTimeController),
                              decoration: InputDecoration(
                                labelText: 'Jam Mulai',
                                suffixIcon: const Icon(
                                  Icons.access_time,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: fieldFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _endTimeController,
                              readOnly: true,
                              onTap: () => _pickTime(_endTimeController),
                              decoration: InputDecoration(
                                labelText: 'Jam Selesai',
                                suffixIcon: const Icon(
                                  Icons.access_time,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: fieldFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Room
                      TextField(
                        controller: _roomController,
                        decoration: InputDecoration(
                          labelText: 'Ruang Kelas / Gedung',
                          hintText: 'Contoh: Gedung B, Ruang 304',
                          errorText: _roomError,
                          filled: true,
                          fillColor: fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (text) {
                          if (_roomError != null && text.trim().isNotEmpty) {
                            setState(() => _roomError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Lecturer
                      TextField(
                        controller: _lecturerController,
                        decoration: InputDecoration(
                          labelText: 'Nama Dosen Pengampu',
                          hintText: 'Contoh: Dr. Ir. Budi Santoso, M.Kom.',
                          errorText: _lecturerError,
                          filled: true,
                          fillColor: fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (text) {
                          if (_lecturerError != null &&
                              text.trim().isNotEmpty) {
                            setState(() => _lecturerError = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: muted)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.store.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      isEditing ? 'Simpan Perubahan' : 'Tambah Jadwal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.store});
  final BrainStore store;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  bool _isIncome = false;
  late String _category;
  String? _titleError;
  String? _amountError;

  final _expenseCategories = const [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Event',
    'Health',
    'Education',
    'Other',
  ];

  final _incomeCategories = const [
    'Salary',
    'Freelance',
    'Allowance',
    'Investment',
    'Bonus',
    'Gift',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _category = _expenseCategories.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _onTypeChanged(bool income) {
    if (_isIncome == income) return;
    setState(() {
      _isIncome = income;
      _category = income ? _incomeCategories.first : _expenseCategories.first;
    });
  }

  void _save() {
    final title = _title.text.trim();
    final rawAmount = _amount.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final value = double.tryParse(rawAmount);

    bool hasError = false;
    if (title.isEmpty) {
      setState(() => _titleError = 'Deskripsi tidak boleh kosong');
      hasError = true;
    }
    if (value == null || value <= 0) {
      setState(() => _amountError = 'Masukkan nominal yang valid');
      hasError = true;
    }

    if (hasError) return;

    widget.store.addTransaction(
      TransactionItem(title, value!, _category, _isIncome),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = _isIncome ? _incomeCategories : _expenseCategories;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFill = isDark ? const Color(0xFF26322C) : paper;
    final accentTint = isDark
        ? widget.store.accentColor.withValues(alpha: 0.2)
        : widget.store.accentColor.withValues(alpha: 0.12);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isIncome ? accentTint : coralLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isIncome ? Icons.south_west : Icons.north_east,
                        color: _isIncome ? widget.store.accentColor : coral,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isIncome
                                ? 'Tambah Pemasukan'
                                : 'Tambah Pengeluaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : ink,
                            ),
                          ),
                          const Text(
                            'Catat transaksi secara real-time',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18, color: muted),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Type Switcher
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: !_isIncome ? coral : muted,
                        ),
                        label: const Center(child: Text('Pengeluaran')),
                        selected: !_isIncome,
                        selectedColor: isDark
                            ? coral.withValues(alpha: 0.25)
                            : coralLight,
                        backgroundColor: fieldFill,
                        labelStyle: TextStyle(
                          color: !_isIncome ? coral : (isDark ? Colors.white70 : muted),
                          fontWeight: !_isIncome
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: !_isIncome
                              ? coral
                              : muted.withValues(alpha: 0.2),
                        ),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) _onTypeChanged(false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: _isIncome ? widget.store.accentColor : muted,
                        ),
                        label: const Center(child: Text('Pemasukan')),
                        selected: _isIncome,
                        selectedColor: accentTint,
                        backgroundColor: fieldFill,
                        labelStyle: TextStyle(
                          color: _isIncome ? widget.store.accentColor : (isDark ? Colors.white70 : muted),
                          fontWeight: _isIncome
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: _isIncome
                              ? widget.store.accentColor
                              : muted.withValues(alpha: 0.2),
                        ),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) _onTypeChanged(true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Transaksi',
                    hintText: _isIncome
                        ? 'e.g. Gaji Bulan Ini, Proyek Desain'
                        : 'e.g. Makan Siang, Bensin, Tiket',
                    errorText: _titleError,
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (text) {
                    if (_titleError != null && text.trim().isNotEmpty) {
                      setState(() => _titleError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                    hintText: '0',
                    errorText: _amountError,
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (text) {
                    if (_amountError != null && text.trim().isNotEmpty) {
                      setState(() => _amountError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_isIncome),
                  initialValue: activeCategories.contains(_category)
                      ? _category
                      : activeCategories.first,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: activeCategories
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: muted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _isIncome ? widget.store.accentColor : coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _save,
                      child: const Text('Simpan Transaksi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showTransactionDialog(
  BuildContext context,
  BrainStore store,
) async {
  await showDialog(
    context: context,
    builder: (context) => _TransactionDialog(store: store),
  );
}

Future<void> showMemoryDialog(BuildContext context, BrainStore store) async {
  final title = TextEditingController();
  final review = TextEditingController();
  final quote = TextEditingController();
  final cover = TextEditingController();
  var type = 'Film';
  var rating = 5.0;
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log a memory'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Film', 'Anime', 'Book', 'Comic']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => type = value!,
            ),
            StatefulBuilder(
              builder: (context, setLocal) => Row(
                children: [
                  const Text('Rating'),
                  Expanded(
                    child: Slider(
                      value: rating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (value) => setLocal(() => rating = value),
                    ),
                  ),
                  Text(rating.toStringAsFixed(1)),
                ],
              ),
            ),
            TextField(
              controller: review,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Review / impression',
              ),
            ),
            TextField(
              controller: quote,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Favorite quote'),
            ),
            TextField(
              controller: cover,
              decoration: const InputDecoration(
                labelText: 'Cover image URL (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (title.text.trim().isEmpty) return;
            store.addMemory(
              Memory(
                title.text.trim(),
                type,
                rating,
                review.text.trim(),
                quote.text.trim(),
                coverUrl: cover.text.trim(),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Save memory'),
        ),
      ],
    ),
  );
}

Future<void> showBillDialog(BuildContext context, BrainStore store) async {
  final title = TextEditingController();
  final amount = TextEditingController();
  final day = TextEditingController(text: '1');
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add bill or subscription'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly amount',
              prefixText: 'Rp ',
            ),
          ),
          TextField(
            controller: day,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Due day'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(
              amount.text.replaceAll('.', '').replaceAll(',', ''),
            );
            final due = int.tryParse(day.text);
            if (title.text.trim().isEmpty || value == null || due == null) {
              return;
            }
            store.addBill(Bill(title.text.trim(), value, due, 'Subscription'));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showInvestmentDialog(
  BuildContext context,
  BrainStore store,
) async {
  final name = TextEditingController();
  final symbol = TextEditingController();
  final units = TextEditingController();
  final price = TextEditingController();
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add investment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Asset name'),
          ),
          TextField(
            controller: symbol,
            decoration: const InputDecoration(labelText: 'Symbol'),
          ),
          TextField(
            controller: units,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Units'),
          ),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Current price',
              prefixText: 'Rp ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final unitValue = double.tryParse(units.text);
            final priceValue = double.tryParse(
              price.text.replaceAll('.', '').replaceAll(',', ''),
            );
            if (name.text.trim().isEmpty ||
                symbol.text.trim().isEmpty ||
                unitValue == null ||
                priceValue == null) {
              return;
            }
            store.addInvestment(
              Investment(
                name.text.trim(),
                symbol.text.trim().toUpperCase(),
                unitValue,
                priceValue,
                priceValue,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

String money(double value) {
  if (value == 0) return 'Rp 0';
  final isNegative = value < 0;
  final absInt = value.abs().round();
  final str = absInt.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  final formatted = 'Rp ${buffer.toString()}';
  return isNegative ? '- $formatted' : formatted;
}

String stars(double value) =>
    '${'★' * value.round()}  ${value.toStringAsFixed(1)}/5';

Future<void> showProfileDialog(BuildContext context, BrainStore store) async {
  await showDialog(
    context: context,
    builder: (context) => _ProfileDialog(store: store),
  );
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.store});
  final BrainStore store;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _apiKeyController;
  bool _isSyncingCloud = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.userName);
    _emailController = TextEditingController(text: widget.store.userEmail);
    _apiKeyController = TextEditingController(text: widget.store.geminiApiKey);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.store.setUserProfile(_nameController.text, _emailController.text);
    widget.store.setGeminiApiKey(_apiKeyController.text);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Pengaturan profil & tema disimpan')),
    );
  }

  Future<void> _manualSync() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _isSyncingCloud = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SyncService.uploadLocalToCloud(user.uid, widget.store);
      await SyncService.fetchAndSyncFromCloud(user.uid, widget.store);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Sinkronisasi cloud berhasil!')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal sinkronisasi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingCloud = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.isLoggedIn;
    final currentUser = AuthService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFill = isDark ? const Color(0xFF26322C) : paper;
    final accentTint = isDark
        ? widget.store.accentColor.withValues(alpha: 0.2)
        : widget.store.accentColor.withValues(alpha: 0.12);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: widget.store.accentColor,
                    child: Text(
                      widget.store.userName.isNotEmpty
                          ? widget.store.userName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.store.userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : ink,
                          ),
                        ),
                        Text(
                          widget.store.userEmail,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cloud Sync & Auth Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isLoggedIn ? accentTint : fieldFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isLoggedIn
                                ? widget.store.accentColor
                                : muted.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isLoggedIn
                                      ? Icons.cloud_done_outlined
                                      : Icons.cloud_off_outlined,
                                  color: isLoggedIn ? widget.store.accentColor : muted,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isLoggedIn
                                            ? 'Tersinkronisasi ke Cloud'
                                            : 'Mode Lokal / Tamu',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isLoggedIn ? widget.store.accentColor : (isDark ? Colors.white : ink),
                                        ),
                                      ),
                                      Text(
                                        isLoggedIn
                                            ? 'Akun: ${currentUser?.email}'
                                            : 'Login untuk menyinkronkan data antar perangkat',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLoggedIn) ...[
                                  if (_isSyncingCloud)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: widget.store.accentColor,
                                      ),
                                    )
                                  else
                                    IconButton(
                                      tooltip: 'Sinkronkan Sekarang',
                                      icon: Icon(
                                        Icons.sync,
                                        size: 20,
                                        color: widget.store.accentColor,
                                      ),
                                      onPressed: _manualSync,
                                    ),
                                  TextButton(
                                    onPressed: () async {
                                      await AuthService.signOut();
                                      if (context.mounted) {
                                        setState(() {});
                                      }
                                    },
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(color: coral),
                                    ),
                                  ),
                                ] else
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: widget.store.accentColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showAuthDialog(context, widget.store);
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Theme Selector
                      const Text(
                        'PILIH TEMA APLIKASI',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Gelap (Dark)'),
                            selected: widget.store.themeMode == ThemeMode.dark,
                            selectedColor: accentTint,
                            onSelected: (val) {
                              if (val) {
                                widget.store.setThemeMode(ThemeMode.dark);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Terang (Light)'),
                            selected: widget.store.themeMode == ThemeMode.light,
                            selectedColor: accentTint,
                            onSelected: (val) {
                              if (val) {
                                widget.store.setThemeMode(ThemeMode.light);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Sistem'),
                            selected:
                                widget.store.themeMode == ThemeMode.system,
                            selectedColor: accentTint,
                            onSelected: (val) {
                              if (val) {
                                widget.store.setThemeMode(ThemeMode.system);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AccentColorPicker(
                        selectedColor: widget.store.accentColor,
                        onColorSelected: (c) {
                          widget.store.setAccentColor(c);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 18),
                      // App Lock Security Container
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: fieldFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: muted.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.store.lockEnabled
                                  ? Icons.lock_outline
                                  : Icons.lock_open_outlined,
                              color: widget.store.lockEnabled ? widget.store.accentColor : muted,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kunci Aplikasi (PIN Lock)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : ink,
                                    ),
                                  ),
                                  Text(
                                    widget.store.lockEnabled
                                        ? 'PIN Lock aktif saat aplikasi dibuka'
                                        : 'Kunci aplikasi dengan 4-digit PIN',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: widget.store.lockEnabled,
                              activeTrackColor: accentTint,
                              activeThumbColor: widget.store.accentColor,
                              onChanged: (val) {
                                if (val) {
                                  widget.store.setLock(
                                    true,
                                    LockScreen.hashPin('1234'),
                                  );
                                } else {
                                  widget.store.setLock(false, '');
                                }
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Profile Input Fields
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          filled: true,
                          fillColor: fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Alamat Email',
                          filled: true,
                          fillColor: fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Gemini API Key Input
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Gemini AI API Key (Opsional)',
                          hintText: 'AIzaSy...',
                          helperText: 'Digunakan untuk fitur rangkuman AI & analisis keuangan',
                          filled: true,
                          fillColor: fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: muted,
                          side: BorderSide(color: muted.withValues(alpha: 0.3)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => OnboardingScreen(
                                onFinish: () => Navigator.pop(ctx),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.school_outlined, size: 16),
                        label: const Text(
                          'Buka Panduan Aplikasi (Onboarding)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: muted)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.store.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Simpan Pengaturan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAuthDialog(BuildContext context, BrainStore store) async {
  await showDialog(
    context: context,
    builder: (context) => _AuthDialog(store: store),
  );
}

class _AuthDialog extends StatefulWidget {
  const _AuthDialog({required this.store});
  final BrainStore store;

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  bool _isSignUp = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _loadingGoogle = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loadingGoogle = true;
      _error = null;
    });

    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) {
        // Pengguna membatalkan dialog pemilihan akun
        return;
      }
      final user = cred.user;
      if (user != null) {
        final displayName =
            user.displayName ?? user.email?.split('@').first ?? 'User';
        widget.store.setUserProfile(displayName, user.email ?? '');

        // Fetch sinkronisasi secara asynchronous di latar belakang tanpa menahan navigasi
        unawaited(
          SyncService.fetchAndSyncFromCloud(user.uid, widget.store).catchError((
            e,
          ) {
            debugPrint('Background cloud sync error: $e');
            return false;
          }),
        );
        SyncService.startRealtimeSync(user.uid, widget.store);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selamat datang, ${user?.displayName ?? "User"}! Data cloud sedang disinkronkan.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      final friendlyMsg =
          e.toString().contains('SHA-1') ||
              e.toString().contains('timeout') ||
              e.toString().contains('Timeout') ||
              e.toString().contains('network')
          ? 'Gagal login, periksa koneksi atau konfigurasi SHA-1 Firebase.'
          : 'Gagal login: ${e.toString().replaceAll('Exception: ', '')}';
      if (mounted) {
        setState(() => _error = friendlyMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyMsg), backgroundColor: coral),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingGoogle = false);
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email dan Password wajib diisi');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      UserCredential? cred;
      if (_isSignUp) {
        cred = await AuthService.signUpWithEmail(
          email: email,
          password: password,
          displayName: name.isEmpty ? 'User' : name,
        );
      } else {
        cred = await AuthService.signInWithEmail(
          email: email,
          password: password,
        );
      }

      final user = cred?.user;
      if (user != null) {
        widget.store.setUserProfile(
          _isSignUp
              ? (name.isEmpty ? 'User' : name)
              : (user.displayName ?? email.split('@').first),
          email,
        );

        // Fetch sinkronisasi secara asynchronous di latar belakang tanpa menahan navigasi
        unawaited(
          SyncService.fetchAndSyncFromCloud(user.uid, widget.store).catchError((
            e,
          ) {
            debugPrint('Background cloud sync error: $e');
            return false;
          }),
        );
        SyncService.startRealtimeSync(user.uid, widget.store);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignUp
                  ? 'Pendaftaran berhasil! Selamat datang di SecBrain.'
                  : 'Selamat datang kembali! Data sedang disinkronkan.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Auth Error: $e');
      final friendlyMsg =
          e.toString().contains('timeout') ||
              e.toString().contains('Timeout') ||
              e.toString().contains('network')
          ? 'Gagal login, periksa koneksi atau konfigurasi SHA-1 Firebase.'
          : e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() => _error = friendlyMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyMsg), backgroundColor: coral),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFill = isDark ? const Color(0xFF26322C) : paper;
    final accentTint = isDark
        ? widget.store.accentColor.withValues(alpha: 0.2)
        : widget.store.accentColor.withValues(alpha: 0.12);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan Logo Resmi SecBrain
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SecBrainShieldIcon(size: 28, color: widget.store.accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSignUp
                                ? 'Daftar Akun SecBrain'
                                : 'Masuk ke SecBrain',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSignUp
                                ? 'Satu akun untuk sinkronisasi seluruh perangkat'
                                : 'Akses seluruh catatan, jadwal & sinkronisasi cloud',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: coralLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: coral.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: coral, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: coral,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Tombol Login Google
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: muted.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: (_loading || _loadingGoogle)
                      ? null
                      : _signInWithGoogle,
                  child: _loadingGoogle
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.store.accentColor,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: muted.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.g_mobiledata_rounded,
                                color: Color(0xFF4285F4),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Lanjutkan dengan Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white : ink,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),

                // Divider ATAU
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: muted.withValues(alpha: 0.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'ATAU EMAIL',
                        style: TextStyle(
                          color: muted.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: muted.withValues(alpha: 0.2)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_isSignUp) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      filled: true,
                      fillColor: fieldFill,
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: fieldFill,
                    prefixIcon: const Icon(Icons.mail_outline, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: fieldFill,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.store.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: (_loading || _loadingGoogle) ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isSignUp ? 'Daftar Sekarang' : 'Masuk'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Sudah punya akun? Masuk'
                          : 'Belum punya akun? Daftar',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showFinanceAnalysisDialog(
  BuildContext context,
  BrainStore store,
) async {
  await showDialog(
    context: context,
    builder: (context) => _FinanceAnalysisDialog(store: store),
  );
}

class _FinanceAnalysisDialog extends StatefulWidget {
  const _FinanceAnalysisDialog({required this.store});
  final BrainStore store;

  @override
  State<_FinanceAnalysisDialog> createState() => _FinanceAnalysisDialogState();
}

class _FinanceAnalysisDialogState extends State<_FinanceAnalysisDialog> {
  bool _loading = true;
  String _analysis = '';

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    final result = await AIService.analyzeFinances(
      transactions: widget.store.transactions,
      totalIncome: widget.store.totalIncome,
      totalExpense: widget.store.totalExpense,
      balance: widget.store.balance,
      apiKey: widget.store.geminiApiKey,
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _analysis = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentTint = isDark
        ? widget.store.accentColor.withValues(alpha: 0.2)
        : widget.store.accentColor.withValues(alpha: 0.12);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1D2420) : Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: widget.store.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analisis Keuangan AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : ink,
                          ),
                        ),
                        const Text(
                          'Wawasan pengeluaran & rekomendasi tabungan cerdas',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF26322C) : paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF33403A) : const Color(0xFFE6EAE5),
                    ),
                  ),
                  child: _loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.store.accentColor,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Menganalisis pola transaksi Anda...',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: SelectableText(
                            _analysis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isDark ? Colors.white : ink,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: widget.store.accentColor),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
