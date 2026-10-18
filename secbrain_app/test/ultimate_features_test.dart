import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secbrain_app/main.dart';
import 'package:secbrain_app/screens/lock_screen.dart';
import 'package:secbrain_app/screens/onboarding_screen.dart';
import 'package:secbrain_app/screens/pomodoro_screen.dart';
import 'package:secbrain_app/widgets/accent_color_picker.dart';
import 'package:secbrain_app/widgets/cross_link_chip.dart';
import 'package:secbrain_app/widgets/dashboard_analytics.dart';
import 'package:secbrain_app/widgets/finance_trend_chart.dart';
import 'package:secbrain_app/widgets/kanban_board.dart';
import 'package:secbrain_app/widgets/overdue_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Ultimate Polish - Model & Utility Tests', () {
    test('Task model supports inProgress field in serialization', () {
      final task = Task(
        'Refactor Database',
        'Work',
        'High',
        inProgress: true,
        done: false,
      );

      final json = task.toJson();
      expect(json['inProgress'], true);

      final deserialized = Task.fromJson(json);
      expect(deserialized.inProgress, true);
      expect(deserialized.title, 'Refactor Database');
    });

    test('Note model supports linkedTaskTitles in serialization', () {
      final note = Note(
        'Meeting Summary',
        'Discussion points',
        'Meeting',
        tags: ['#sprint', '#tech'],
        linkedTaskTitles: ['Refactor Database', 'API Integration'],
      );

      final json = note.toJson();
      expect(json['linkedTaskTitles'], contains('Refactor Database'));

      final deserialized = Note.fromJson(json);
      expect(deserialized.linkedTaskTitles.length, 2);
      expect(deserialized.linkedTaskTitles, contains('API Integration'));
    });

    test('TransactionItem model supports timestamp date in serialization', () {
      final txDate = DateTime(2026, 9, 24, 10, 30);
      final item = TransactionItem(
        'Beli Kopi',
        35000,
        'Food & Drink',
        false,
        date: txDate,
      );

      final json = item.toJson();
      expect(json['date'], txDate.toIso8601String());

      final deserialized = TransactionItem.fromJson(json);
      expect(deserialized.date.year, 2026);
      expect(deserialized.date.day, 24);
    });

    test('PomodoroSession model serializes and deserializes correctly', () {
      final session = PomodoroSession(
        taskTitle: 'Write unit tests',
        mode: PomodoroMode.focus,
        durationMinutes: 25,
        completedAt: DateTime(2026, 9, 24, 11, 0),
      );

      final json = session.toJson();
      expect(json['mode'], 'focus');
      expect(json['durationMinutes'], 25);

      final deserialized = PomodoroSession.fromJson(json);
      expect(deserialized.taskTitle, 'Write unit tests');
      expect(deserialized.mode, PomodoroMode.focus);
    });

    test('LockScreen hash helper produces consistent hash string', () {
      final hash1 = LockScreen.hashPin('1234');
      final hash2 = LockScreen.hashPin('1234');
      final hashDiff = LockScreen.hashPin('5678');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashDiff)));
    });

    test('CategoryColorHelper maps categories properly', () {
      final workBg = CategoryColorHelper.getCategoryBgColor('Work');
      final workText = CategoryColorHelper.getCategoryTextColor('Work');
      expect(workBg, equals(blueLight));
      expect(workText, isNotNull);

      final univBg = CategoryColorHelper.getCategoryBgColor('University');
      expect(univBg, equals(greenLight));
    });

    test(
      'BrainStore manages accentColor, lockEnabled, and onboardingCompleted',
      () {
        final store = BrainStore();
        expect(store.accentColor, equals(green));
        expect(store.lockEnabled, false);
        expect(store.onboardingCompleted, true);

        store.setAccentColor(const Color(0xFF1565C0));
        expect(store.accentColor, equals(const Color(0xFF1565C0)));

        store.setLock(true, LockScreen.hashPin('4321'));
        expect(store.lockEnabled, true);
        expect(store.pinHash, equals(LockScreen.hashPin('4321')));
      },
    );
  });

  group('Ultimate Polish - Widget UI Tests', () {
    testWidgets(
      'WeeklyInsightCard renders productivity metrics and overdue badge',
      (tester) async {
        final store = BrainStore();
        store.tasks.clear();
        store.tasks.add(Task('Task Selesai', 'Work', 'High', done: true));
        store.tasks.add(
          Task(
            'Task Terlambat',
            'Work',
            'High',
            done: false,
            due: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeeklyInsightCard(store: store, onNavigate: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Ringkasan Produktivitas & Aktivitas'),
          findsOneWidget,
        );
        expect(find.text('1 Overdue'), findsOneWidget);
        expect(find.text('1 / 2 tugas'), findsOneWidget);
      },
    );

    testWidgets('PomodoroScreen renders timer, controls, and mode switcher', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        StoreScope(
          child: const MaterialApp(home: Scaffold(body: PomodoroScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focus Timer & Pomodoro'), findsOneWidget);
      expect(find.text('Fokus'), findsWidgets);
      expect(find.text('Istirahat Singkat'), findsOneWidget);
      expect(find.text('Istirahat Panjang'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('MULAI FOKUS'), findsOneWidget);

      // Tap Istirahat Singkat
      await tester.tap(find.text('Istirahat Singkat'));
      await tester.pumpAndSettle();
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('KanbanBoard displays 3 columns and drag targets', (
      tester,
    ) async {
      final store = BrainStore();
      store.tasks.clear();
      store.tasks.add(
        Task('Task A', 'Work', 'High', done: false, inProgress: false),
      );
      store.tasks.add(
        Task('Task B', 'Personal', 'Medium', done: false, inProgress: true),
      );
      store.tasks.add(
        Task('Task C', 'University', 'Low', done: true, inProgress: false),
      );

      await tester.pumpWidget(
        StoreScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: KanbanBoard(store: store)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Task A'), findsOneWidget);
      expect(find.text('Task B'), findsOneWidget);
      expect(find.text('Task C'), findsOneWidget);
    });

    testWidgets('FinanceTrendChart renders range toggle and canvas', (
      tester,
    ) async {
      final store = BrainStore();
      store.transactions.clear();
      store.transactions.add(
        TransactionItem('Gaji Freelance', 3000000, 'Income', true),
      );
      store.transactions.add(
        TransactionItem('Belanja Bulanan', 500000, 'Groceries', false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: FinanceTrendChart(store: store)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tren Arus Kas'), findsOneWidget);
      expect(find.text('7 Hari'), findsOneWidget);
      expect(find.text('30 Hari'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('CrossLinkChips renders linked tasks chips properly', (
      tester,
    ) async {
      String? tappedTask;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrossLinkChips(
              linkedTaskTitles: const ['Selesaikan Modul 1', 'Review PR'],
              onTaskTap: (t) => tappedTask = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LINKED TASKS'), findsOneWidget);
      expect(find.text('Selesaikan Modul 1'), findsOneWidget);
      expect(find.text('Review PR'), findsOneWidget);

      await tester.tap(find.text('Review PR'));
      expect(tappedTask, 'Review PR');
    });

    testWidgets('OnboardingScreen displays slides and calls onFinish', (
      tester,
    ) async {
      bool finished = false;
      await tester.pumpWidget(
        MaterialApp(home: OnboardingScreen(onFinish: () => finished = true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang di SecBrain'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      expect(finished, true);
    });

    testWidgets('AccentColorPicker renders palette and selects color', (
      tester,
    ) async {
      Color selected = const Color(0xFF365C4C);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccentColorPicker(
              selectedColor: selected,
              onColorSelected: (c) => selected = c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WARNA AKSEN APLIKASI'), findsOneWidget);
      expect(find.text('Ocean Blue'), findsOneWidget);

      await tester.tap(find.text('Ocean Blue'));
      expect(selected.toARGB32(), equals(const Color(0xFF1565C0).toARGB32()));
    });
  });
}
