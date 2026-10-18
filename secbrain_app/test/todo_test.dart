import 'package:flutter_test/flutter_test.dart';
import 'package:secbrain_app/main.dart';
import 'package:secbrain_app/models/todo_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TodoItem Model & BrainStore Todo Tests', () {
    test('TodoTimeframe parses strings correctly', () {
      expect(TodoTimeframe.fromString('today'), TodoTimeframe.today);
      expect(TodoTimeframe.fromString('Hari Ini'), TodoTimeframe.today);
      expect(TodoTimeframe.fromString('thisWeek'), TodoTimeframe.thisWeek);
      expect(TodoTimeframe.fromString('Minggu Ini'), TodoTimeframe.thisWeek);
      expect(TodoTimeframe.fromString('thisMonth'), TodoTimeframe.thisMonth);
      expect(TodoTimeframe.fromString('Bulan Ini'), TodoTimeframe.thisMonth);
      expect(TodoTimeframe.fromString('thisYear'), TodoTimeframe.thisYear);
      expect(TodoTimeframe.fromString('Tahun Ini'), TodoTimeframe.thisYear);
    });

    test('TodoItem serializes to and from JSON', () {
      final now = DateTime.now();
      final item = TodoItem(
        id: 't1',
        title: 'Beli buku algoritma',
        timeframe: TodoTimeframe.thisWeek,
        done: true,
        createdAt: now,
        completedAt: now,
        category: 'Kuliah',
      );

      final json = item.toJson();
      expect(json['id'], 't1');
      expect(json['title'], 'Beli buku algoritma');
      expect(json['timeframe'], 'thisWeek');
      expect(json['done'], true);
      expect(json['category'], 'Kuliah');

      final fromJson = TodoItem.fromJson(json);
      expect(fromJson.id, 't1');
      expect(fromJson.title, 'Beli buku algoritma');
      expect(fromJson.timeframe, TodoTimeframe.thisWeek);
      expect(fromJson.done, true);
      expect(fromJson.category, 'Kuliah');
    });

    test('TodoItem toggle changes done state and timestamp', () {
      final item = TodoItem(title: 'Lari pagi 5k');
      expect(item.done, false);
      expect(item.completedAt, isNull);

      item.toggle();
      expect(item.done, true);
      expect(item.completedAt, isNotNull);

      item.toggle();
      expect(item.done, false);
      expect(item.completedAt, isNull);
    });

    test('BrainStore manages todos (add, toggle, update, delete, clear)', () {
      final store = BrainStore();
      final initialCount = store.todos.length;

      // Add
      final newTodo = TodoItem(
        id: 'test_todo',
        title: 'Target riset',
        timeframe: TodoTimeframe.today,
      );
      store.addTodo(newTodo);
      expect(store.todos.length, initialCount + 1);
      expect(store.todos.first.id, 'test_todo');

      // Toggle
      store.toggleTodo(newTodo);
      expect(newTodo.done, true);

      // Update
      store.updateTodo(
        newTodo,
        title: 'Target riset diperbarui',
        timeframe: TodoTimeframe.thisMonth,
      );
      expect(newTodo.title, 'Target riset diperbarui');
      expect(newTodo.timeframe, TodoTimeframe.thisMonth);

      // Clear completed for thisMonth
      store.clearCompletedTodos(TodoTimeframe.thisMonth);
      expect(store.todos.any((t) => t.id == 'test_todo'), false);

      // Delete
      final another = TodoItem(title: 'Hapus saya');
      store.addTodo(another);
      expect(store.todos.contains(another), true);
      store.deleteTodo(another);
      expect(store.todos.contains(another), false);
    });
  });
}
