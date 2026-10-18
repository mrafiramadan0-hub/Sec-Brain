import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secbrain_app/main.dart';
import 'package:secbrain_app/models/habit.dart';
import 'package:secbrain_app/screens/calendar_screen.dart';
import 'package:secbrain_app/screens/habits_screen.dart';
import 'package:secbrain_app/services/backup_service.dart';
import 'package:secbrain_app/widgets/backup_dialog.dart';
import 'package:secbrain_app/widgets/global_search_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pro Features - Habit Model Tests', () {
    test('Habit initializes correctly with default values', () {
      final habit = Habit(
        id: 'h1',
        title: 'Membaca Buku',
        description: '15 menit per hari',
      );

      expect(habit.id, 'h1');
      expect(habit.title, 'Membaca Buku');
      expect(habit.targetDaysPerWeek, 7);
      expect(habit.completedDates, isEmpty);
      expect(habit.currentStreak, 0);
    });

    test('Habit toggles date completion and calculates streak', () {
      final habit = Habit(id: 'h1', title: 'Olahraga Pagi');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      expect(habit.isCompletedToday, isFalse);

      habit.toggleDate(today);
      expect(habit.isCompletedToday, isTrue);
      expect(habit.currentStreak, 1);

      // Add consecutive days
      habit.toggleDate(yesterday);
      habit.toggleDate(twoDaysAgo);
      expect(habit.currentStreak, 3);

      // Untoggle today
      habit.toggleDate(today);
      expect(habit.isCompletedToday, isFalse);
      // Since yesterday is completed, streak from yesterday is 2
      expect(habit.currentStreak, 2);
    });

    test('Habit serializes to and from JSON', () {
      final habit = Habit(
        id: 'habit_test',
        title: 'Meditasi',
        description: 'Ketenangan batin',
        targetDaysPerWeek: 5,
        completedDates: ['2026-09-21', '2026-09-22'],
        iconName: 'meditation',
      );

      final json = habit.toJson();
      expect(json['id'], 'habit_test');
      expect(json['title'], 'Meditasi');
      expect(json['completedDates'], ['2026-09-21', '2026-09-22']);

      final restored = Habit.fromJson(json);
      expect(restored.id, 'habit_test');
      expect(restored.title, 'Meditasi');
      expect(restored.iconName, 'meditation');
      expect(restored.completedDates.length, 2);
    });
  });

  group('Pro Features - BackupService Tests', () {
    test('BackupService exports all store data to valid JSON', () {
      final store = BrainStore();
      final jsonStr = BackupService.exportAllToJson(store);

      expect(jsonStr, contains('"app": "SecBrain"'));
      expect(jsonStr, contains('"tasks"'));
      expect(jsonStr, contains('"notes"'));
      expect(jsonStr, contains('"schedules"'));
      expect(jsonStr, contains('"transactions"'));
      expect(jsonStr, contains('"habits"'));
    });

    test('BackupService exports transactions to CSV format', () {
      final store = BrainStore();
      store.addTransaction(
        TransactionItem('Gaji Bulanan', 8000000, 'Pemasukan Utama', true),
      );
      store.addTransaction(
        TransactionItem('Beli Kopi, Cemilan', 45000, 'Konsumsi', false),
      );

      final csvStr = BackupService.exportTransactionsToCsv(store);

      expect(csvStr, contains('No,Tipe,Kategori,Deskripsi,Jumlah (IDR)'));
      expect(csvStr, contains('Pemasukan'));
      expect(csvStr, contains('8000000'));
      expect(csvStr, contains('Pengeluaran'));
      expect(csvStr, contains('"Beli Kopi, Cemilan"'));
    });

    test('BackupService imports data correctly from JSON string', () {
      final store = BrainStore();
      final backupData = '''
      {
        "app": "SecBrain",
        "tasks": [
          {
            "title": "Tugas Impor Khusus",
            "category": "Testing",
            "priority": "High",
            "done": true,
            "due": null,
            "recurring": "None",
            "urgent": true,
            "important": true
          }
        ],
        "notes": [
          {
            "title": "Catatan Impor",
            "body": "Isi catatan impor hasil backup",
            "type": "General",
            "tags": ["#impor", "#test"]
          }
        ],
        "habits": [
          {
            "id": "h_imported",
            "title": "Habit Impor",
            "description": "Tes impor",
            "targetDaysPerWeek": 7,
            "completedDates": []
          }
        ]
      }
      ''';

      final success = BackupService.importFromJson(backupData, store);
      expect(success, isTrue);
      expect(store.tasks.any((t) => t.title == 'Tugas Impor Khusus'), isTrue);
      expect(store.notes.any((n) => n.title == 'Catatan Impor'), isTrue);
      expect(store.notes.first.tags, contains('#impor'));
      expect(store.habits.any((h) => h.title == 'Habit Impor'), isTrue);
    });
  });

  group('Pro Features - Note Tags Tests', () {
    test('Note correctly serializes and preserves tags', () {
      final note = Note(
        'Catatan Arsitektur',
        'Pembahasan microservices',
        'Meeting',
        tags: ['#arsitektur', '#backend'],
      );

      final json = note.toJson();
      expect(json['tags'], ['#arsitektur', '#backend']);

      final fromJson = Note.fromJson(json);
      expect(fromJson.tags, ['#arsitektur', '#backend']);
    });
  });

  group('Pro Features - Widget UI Tests', () {
    testWidgets('CalendarScreen displays month header and weekday columns', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreScope(child: const Scaffold(body: CalendarScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kalender Aktivitas'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Sen'), findsOneWidget);
      expect(find.text('Min'), findsOneWidget);
    });

    testWidgets(
      'HabitsScreen renders habit items and allows toggling completion',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreScope(child: const Scaffold(body: HabitsScreen())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Habit Tracker'), findsOneWidget);
        expect(find.text('Progres Kebiasaan Hari Ini'), findsOneWidget);
        expect(find.text('Add Habit'), findsOneWidget);

        // Find the first habit checkbox circle and tap
        final habitCheckbox = find.byType(InkWell).first;
        await tester.tap(habitCheckbox);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('GlobalSearchDialog displays quick commands when opened', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreScope(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showGlobalSearchDialog(context, StoreScope.of(context)),
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      expect(find.text('AKSI CEPAT (COMMANDS)'), findsOneWidget);
      expect(find.text('Buat Tugas Baru'), findsOneWidget);
      expect(find.text('Tulis Catatan Baru'), findsOneWidget);
      expect(find.text('Buka Kalender Terpadu'), findsOneWidget);
    });

    testWidgets('BackupDialog renders export options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreScope(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showBackupDialog(context, StoreScope.of(context)),
                child: const Text('Open Backup'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Ekspor & Impor Data'), findsOneWidget);
      expect(find.text('Ekspor Seluruh Data (JSON)'), findsOneWidget);
      expect(find.text('Ekspor Transaksi Keuangan (CSV)'), findsOneWidget);
    });
  });
}
