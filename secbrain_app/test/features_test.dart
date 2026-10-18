import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secbrain_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Finance & Note Templates Tests', () {
    test(
      'BrainStore initializes with empty transactions and dynamic getters',
      () {
        final store = BrainStore();
        expect(store.transactions, isEmpty);
        expect(store.totalIncome, 0.0);
        expect(store.totalExpense, 0.0);
        expect(store.balance, 0.0);
        expect(money(store.balance), 'Rp 0');
        expect(money(store.totalIncome), 'Rp 0');
        expect(money(store.totalExpense), 'Rp 0');

        // Add income
        store.addTransaction(TransactionItem('Gaji', 5000000, 'Salary', true));
        expect(store.transactions.length, 1);
        expect(store.totalIncome, 5000000.0);
        expect(store.totalExpense, 0.0);
        expect(store.balance, 5000000.0);

        // Add expense
        store.addTransaction(TransactionItem('Makan', 50000, 'Food', false));
        expect(store.transactions.length, 2);
        expect(store.totalIncome, 5000000.0);
        expect(store.totalExpense, 50000.0);
        expect(store.balance, 4950000.0);
      },
    );

    test('SavingsGoal model and store management work dynamically', () {
      final store = BrainStore();
      expect(store.savingsGoals, isEmpty);

      final goal = SavingsGoal(
        'Emergency Fund',
        10000000,
        2500000,
        targetDate: 'Dec 2026',
      );
      store.addSavingsGoal(goal);
      expect(store.savingsGoals.length, 1);
      expect(store.savingsGoals.first.title, 'Emergency Fund');
      expect(store.savingsGoals.first.targetAmount, 10000000.0);
      expect(store.savingsGoals.first.currentAmount, 2500000.0);

      store.deleteSavingsGoal(goal);
      expect(store.savingsGoals, isEmpty);
    });

    test(
      'NoteTemplate constants are properly defined with required 4 templates',
      () {
        expect(noteTemplates.length, 4);

        final free = noteTemplates.firstWhere((t) => t.id == 'free');
        expect(free.label, 'Catatan Bebas');
        expect(free.bodyContent, isEmpty);

        final meeting = noteTemplates.firstWhere((t) => t.id == 'meeting');
        expect(meeting.label, 'Agenda Rapat');
        expect(meeting.bodyContent, contains('Tujuan Rapat'));
        expect(meeting.bodyContent, contains('Action Items'));

        final client = noteTemplates.firstWhere((t) => t.id == 'client');
        expect(client.label, 'Notulensi Klien');
        expect(client.bodyContent, contains('Klien / Instansi'));
        expect(client.bodyContent, contains('Tindak Lanjut'));

        final workshop = noteTemplates.firstWhere((t) => t.id == 'workshop');
        expect(workshop.label, 'Catatan Workshop');
        expect(workshop.bodyContent, contains('Topik Workshop'));
        expect(workshop.bodyContent, contains('Key Takeaways'));
      },
    );

    testWidgets(
      'FinanceScreen displays empty state when transactions list is empty',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1400));
        await tester.pumpWidget(const SecBrainApp());
        await tester.pumpAndSettle();

        // Navigate to Finance tab (Index 3)
        final financeNav = find.text('Finance');
        expect(financeNav, findsWidgets);
        await tester.tap(financeNav.first);
        await tester.pumpAndSettle();

        // Verify Empty State is displayed
        expect(find.text('Belum ada transaksi'), findsOneWidget);
        expect(find.text('Tambah Transaksi Pertama'), findsOneWidget);
        expect(find.text('Belum ada target tabungan'), findsOneWidget);
        expect(find.text('New MacBook Pro'), findsNothing);
        expect(find.text('Monthly allowance'), findsNothing);
      },
    );

    testWidgets('New Note Modal has ChoiceChips and injects template content', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const SecBrainApp());
      await tester.pumpAndSettle();

      // Navigate to Knowledge Base (Index 2)
      final kbNav = find.text('Knowledge Base');
      expect(kbNav, findsWidgets);
      await tester.tap(kbNav.first);
      await tester.pumpAndSettle();

      // Tap "New note" button
      final newNoteBtn = find.widgetWithText(FilledButton, 'New note');
      expect(newNoteBtn, findsOneWidget);
      await tester.tap(newNoteBtn);
      await tester.pumpAndSettle();

      // Verify all 4 ChoiceChips exist
      expect(find.text('Catatan Bebas'), findsOneWidget);
      expect(find.text('Agenda Rapat'), findsOneWidget);
      expect(find.text('Notulensi Klien'), findsOneWidget);
      expect(find.text('Catatan Workshop'), findsOneWidget);

      // Tap "Agenda Rapat" ChoiceChip
      await tester.ensureVisible(find.text('Agenda Rapat'));
      await tester.tap(find.text('Agenda Rapat'));
      await tester.pumpAndSettle();

      // Verify template content is injected into Note body
      expect(find.textContaining('Tujuan Rapat'), findsWidgets);
      expect(find.textContaining('Action Items'), findsOneWidget);

      // Tap "Notulensi Klien" ChoiceChip
      await tester.ensureVisible(find.text('Notulensi Klien'));
      await tester.tap(find.text('Notulensi Klien'));
      await tester.pumpAndSettle();

      // Verify client template content is injected
      expect(find.textContaining('Klien / Instansi'), findsOneWidget);
      expect(find.textContaining('Tindak Lanjut'), findsOneWidget);

      // Tap "Catatan Workshop" ChoiceChip
      await tester.ensureVisible(find.text('Catatan Workshop'));
      await tester.tap(find.text('Catatan Workshop'));
      await tester.pumpAndSettle();

      // Verify workshop template content is injected
      expect(find.textContaining('Topik Workshop'), findsOneWidget);
      expect(find.textContaining('Key Takeaways'), findsOneWidget);

      // Tap "Catatan Bebas" ChoiceChip
      await tester.ensureVisible(find.text('Catatan Bebas'));
      await tester.tap(find.text('Catatan Bebas'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    });

    test('Bill and Investment delete operations update store and totals', () {
      final store = BrainStore();
      final initialBills = store.bills.length;
      final bill1 = Bill('Indihome', 350000, 15, 'Internet');
      final bill2 = Bill('Netflix', 186000, 20, 'Streaming');
      store.addBill(bill1);
      store.addBill(bill2);
      expect(store.bills.length, initialBills + 2);

      store.deleteBill(bill1);
      expect(store.bills.length, initialBills + 1);
      expect(store.bills.any((b) => b.title == 'Indihome'), isFalse);

      final initialInvs = store.investments.length;
      final inv1 = Investment('BBCA', 'BBCA.JK', 100, 9500, 10000);
      final inv2 = Investment('GOTO', 'GOTO.JK', 1000, 80, 70);
      store.addInvestment(inv1);
      store.addInvestment(inv2);
      expect(store.investments.length, initialInvs + 2);

      store.deleteInvestment(inv2);
      expect(store.investments.length, initialInvs + 1);
      expect(store.investments.any((i) => i.symbol == 'GOTO.JK'), isFalse);
    });

    test('Note updating modifies title, body, and type in store', () {
      final store = BrainStore();
      final note = Note('Original Title', 'Original Body', 'Catatan Bebas');
      store.addNote(note);

      store.updateNote(note, 'Updated Title', 'Updated Body', 'Agenda Rapat');
      expect(note.title, 'Updated Title');
      expect(note.body, 'Updated Body');
      expect(note.type, 'Agenda Rapat');
    });

    test('CourseSchedule model serializes to and from JSON', () {
      final schedule = CourseSchedule(
        id: 'cs-123',
        courseName: 'Basis Data',
        day: 'Selasa',
        startTime: '10:00',
        endTime: '11:40',
        room: 'Lab Komputer 3',
        lecturer: 'Prof. Bambang',
        sks: 3,
        colorIndex: 1,
      );

      final json = schedule.toJson();
      expect(json['courseName'], 'Basis Data');
      expect(json['day'], 'Selasa');
      expect(json['startTime'], '10:00');
      expect(json['endTime'], '11:40');
      expect(json['room'], 'Lab Komputer 3');
      expect(json['lecturer'], 'Prof. Bambang');
      expect(json['sks'], 3);

      final restored = CourseSchedule.fromJson(json);
      expect(restored.courseName, schedule.courseName);
      expect(restored.day, schedule.day);
      expect(restored.startTime, schedule.startTime);
      expect(restored.endTime, schedule.endTime);
      expect(restored.room, schedule.room);
      expect(restored.lecturer, schedule.lecturer);
      expect(restored.sks, schedule.sks);
    });

    test('BrainStore manages course schedules correctly', () {
      final store = BrainStore();
      expect(store.schedules, isEmpty);

      final s1 = CourseSchedule(
        courseName: 'Jaringan Komputer',
        day: 'Rabu',
        startTime: '08:00',
        endTime: '09:40',
        room: 'Ruang 201',
        lecturer: 'Dr. Hendra',
        sks: 3,
      );
      final s2 = CourseSchedule(
        courseName: 'Kecerdasan Buatan',
        day: 'Kamis',
        startTime: '13:00',
        endTime: '15:30',
        room: 'Ruang 305',
        lecturer: 'Dr. Sarah',
        sks: 3,
      );

      store.addSchedule(s1);
      store.addSchedule(s2);
      expect(store.schedules.length, 2);

      final updated = CourseSchedule(
        id: s1.id,
        courseName: 'Jaringan Komputer Lanjut',
        day: 'Rabu',
        startTime: '08:00',
        endTime: '10:30',
        room: 'Ruang 204',
        lecturer: 'Dr. Hendra',
        sks: 4,
      );
      store.updateSchedule(s1, updated);
      expect(store.schedules.first.courseName, 'Jaringan Komputer Lanjut');
      expect(store.schedules.first.sks, 4);

      store.deleteSchedule(updated);
      expect(store.schedules.length, 1);
      expect(store.schedules.first.courseName, 'Kecerdasan Buatan');
    });

    testWidgets('ScheduleScreen displays and filters schedules by day', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const SecBrainApp());
      await tester.pumpAndSettle();

      // Navigate to Jadwal Kuliah tab
      final scheduleNav = find.text('Jadwal Kuliah');
      expect(scheduleNav, findsWidgets);
      await tester.tap(scheduleNav.first);
      await tester.pumpAndSettle();

      // Check header and day chips
      expect(find.text('Jadwal Mata Kuliah'), findsOneWidget);
      expect(find.text('Add schedule'), findsOneWidget);
      expect(find.textContaining('Semua'), findsOneWidget);
      expect(find.textContaining('Senin'), findsOneWidget);
      expect(find.textContaining('Selasa'), findsOneWidget);

      // Verify empty state is shown initially
      expect(find.text('Belum ada jadwal mata kuliah'), findsOneWidget);
      expect(find.text('Tambah Jadwal Kuliah'), findsOneWidget);

      // Tap "Add schedule" button
      await tester.tap(find.text('Add schedule'));
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('Tambah Jadwal Kuliah'), findsWidgets);
      final courseField = find.widgetWithText(
        TextField,
        'Contoh: Algoritma & Pemrograman',
      );
      await tester.enterText(courseField, 'Struktur Data');

      final roomField = find.widgetWithText(
        TextField,
        'Contoh: Gedung B, Ruang 304',
      );
      await tester.enterText(roomField, 'Lab 101');

      final lecturerField = find.widgetWithText(
        TextField,
        'Contoh: Dr. Ir. Budi Santoso, M.Kom.',
      );
      await tester.enterText(lecturerField, 'Ir. Sinta');

      // Submit form
      await tester.tap(find.text('Tambah Jadwal'));
      await tester.pumpAndSettle();

      // Verify schedule is rendered on screen
      expect(find.text('Struktur Data'), findsOneWidget);
      expect(find.text('Lab 101'), findsOneWidget);
      expect(find.text('Ir. Sinta'), findsOneWidget);
      expect(find.text('Senin'), findsWidgets);

      // Switch to Selasa filter chip
      final selasaChip = find.textContaining('Selasa');
      await tester.tap(selasaChip);
      await tester.pumpAndSettle();

      // Verify Struktur Data is not in Selasa
      expect(find.text('Struktur Data'), findsNothing);
      expect(find.text('Tidak ada jadwal di hari Selasa'), findsOneWidget);

      // Switch back to Semua
      final semuaChip = find.textContaining('Semua');
      await tester.tap(semuaChip);
      await tester.pumpAndSettle();
      expect(find.text('Struktur Data'), findsOneWidget);
    });

    testWidgets('Notes can be viewed in detail and edited', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(const SecBrainApp());
      await tester.pumpAndSettle();

      // Navigate to Knowledge Base
      final kbNav = find.text('Knowledge Base');
      await tester.tap(kbNav.first);
      await tester.pumpAndSettle();

      // Find initial note card "Client discovery - Karsa Studio"
      final noteCard = find.text('Client discovery - Karsa Studio');
      expect(noteCard, findsOneWidget);

      // Tap note card to view detail
      await tester.tap(noteCard);
      await tester.pumpAndSettle();

      // Verify detail dialog is shown
      expect(find.text('Edit Catatan'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      // Tap "Edit Catatan" button inside detail dialog
      await tester.tap(find.text('Edit Catatan'));
      await tester.pumpAndSettle();

      // Verify edit dialog is shown
      expect(find.text('Perbarui judul atau isi catatan Anda'), findsOneWidget);
      final titleField = find.widgetWithText(
        TextField,
        'Client discovery - Karsa Studio',
      );
      await tester.enterText(
        titleField,
        'Client discovery - Karsa Studio (Rev)',
      );

      // Save changes
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Verify updated note is displayed on screen
      expect(
        find.text('Client discovery - Karsa Studio (Rev)'),
        findsOneWidget,
      );
    });
  });
}
