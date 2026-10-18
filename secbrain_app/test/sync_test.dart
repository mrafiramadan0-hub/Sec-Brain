import 'package:flutter_test/flutter_test.dart';
import 'package:secbrain_app/main.dart';
import 'package:secbrain_app/models/habit.dart';
import 'package:secbrain_app/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Cloud Sync & Data Models Serialization Tests', () {
    test('Task model has unique id and serializes/deserializes correctly', () {
      final task = Task(
        'Belajar Cloud Firestore',
        'Kuliah',
        'High',
        id: 'task_custom_123',
        done: false,
        urgent: true,
      );

      expect(task.id, 'task_custom_123');
      final json = task.toJson();
      expect(json['id'], 'task_custom_123');
      expect(json['title'], 'Belajar Cloud Firestore');
      expect(json['urgent'], true);

      final restored = Task.fromJson(json);
      expect(restored.id, 'task_custom_123');
      expect(restored.title, 'Belajar Cloud Firestore');
      expect(restored.category, 'Kuliah');
    });

    test('Note model has unique id and serializes/deserializes correctly', () {
      final note = Note(
        'Catatan Arsitektur',
        'Gunakan Firestore offline-first',
        'General',
        id: 'note_custom_456',
        tags: ['cloud', 'sync'],
      );

      expect(note.id, 'note_custom_456');
      final json = note.toJson();
      expect(json['id'], 'note_custom_456');
      expect(json['tags'], ['cloud', 'sync']);

      final restored = Note.fromJson(json);
      expect(restored.id, 'note_custom_456');
      expect(restored.title, 'Catatan Arsitektur');
      expect(restored.tags, contains('cloud'));
    });

    test('TransactionItem model has unique id and serializes/deserializes correctly', () {
      final tx = TransactionItem(
        'Buku Algoritma',
        125000,
        'Edukasi',
        false,
        id: 'tx_custom_789',
      );

      expect(tx.id, 'tx_custom_789');
      final json = tx.toJson();
      expect(json['id'], 'tx_custom_789');
      expect(json['amount'], 125000.0);

      final restored = TransactionItem.fromJson(json);
      expect(restored.id, 'tx_custom_789');
      expect(restored.title, 'Buku Algoritma');
      expect(restored.income, false);
    });

    test('CourseSchedule model has unique id and serializes/deserializes correctly', () {
      final schedule = CourseSchedule(
        id: 'sched_custom_999',
        courseName: 'Sistem Terdistribusi',
        day: 'Selasa',
        startTime: '08:00',
        endTime: '10:30',
        room: 'Lab Cloud',
        lecturer: 'Dr. Budi',
        sks: 3,
      );

      expect(schedule.id, 'sched_custom_999');
      final json = schedule.toJson();
      expect(json['id'], 'sched_custom_999');
      expect(json['courseName'], 'Sistem Terdistribusi');

      final restored = CourseSchedule.fromJson(json);
      expect(restored.id, 'sched_custom_999');
      expect(restored.courseName, 'Sistem Terdistribusi');
      expect(restored.lecturer, 'Dr. Budi');
    });

    test('Habit model has unique id and serializes/deserializes correctly', () {
      final habit = Habit(
        id: 'habit_custom_001',
        title: 'Review PR & Sinkronisasi',
        description: 'Setiap hari',
        targetDaysPerWeek: 7,
        completedDates: ['2026-09-29'],
      );

      expect(habit.id, 'habit_custom_001');
      final json = habit.toJson();
      expect(json['id'], 'habit_custom_001');
      expect(json['completedDates'], contains('2026-09-29'));

      final restored = Habit.fromJson(json);
      expect(restored.id, 'habit_custom_001');
      expect(restored.title, 'Review PR & Sinkronisasi');
      expect(restored.isCompletedOn(DateTime(2026, 9, 29)), true);
    });
  });

  group('BrainStore Cloud Data Application & State Tests', () {
    test('applyCloudData updates all state collections and cache', () async {
      final store = BrainStore();
      await Future.delayed(const Duration(milliseconds: 50));

      final cloudTasks = [Task('Cloud Task 1', 'Work', 'High', id: 'ct_1')];
      final cloudNotes = [
        Note('Cloud Note 1', 'Body from cloud', 'General', id: 'cn_1'),
      ];
      final cloudSchedules = [
        CourseSchedule(
          id: 'cs_1',
          courseName: 'Cloud Computing',
          day: 'Rabu',
          startTime: '10:00',
          endTime: '12:00',
          room: 'R.301',
          lecturer: 'Prof. John',
        ),
      ];
      final cloudTransactions = [
        TransactionItem('Cloud Expense', 50000, 'Food', false, id: 'ctx_1'),
      ];
      final cloudHabits = [
        Habit(id: 'ch_1', title: 'Minum Air 2L', targetDaysPerWeek: 7),
      ];

      store.applyCloudData(
        cloudTasks: cloudTasks,
        cloudNotes: cloudNotes,
        cloudSchedules: cloudSchedules,
        cloudTransactions: cloudTransactions,
        cloudHabits: cloudHabits,
        saveToLocal: true,
      );

      expect(store.tasks.length, 1);
      expect(store.tasks.first.title, 'Cloud Task 1');
      expect(store.notes.length, 1);
      expect(store.notes.first.title, 'Cloud Note 1');
      expect(store.schedules.length, 1);
      expect(store.schedules.first.courseName, 'Cloud Computing');
      expect(store.transactions.length, 1);
      expect(store.transactions.first.title, 'Cloud Expense');
      expect(store.habits.length, 1);
      expect(store.habits.first.title, 'Minum Air 2L');
    });

    test(
      'SyncService methods are safely invokable in offline/mock environment',
      () async {
        final store = BrainStore();
        await Future.delayed(const Duration(milliseconds: 50));

        // Without Firebase initialized, methods should gracefully handle without unhandled exceptions
        await SyncService.uploadLocalToCloud('test_user_id', store);
        final fetched = await SyncService.fetchAndSyncFromCloud(
          'test_user_id',
          store,
        );
        expect(fetched, false);

        SyncService.startRealtimeSync('test_user_id', store);
        SyncService.stopRealtimeSync();
      },
    );
  });
}
