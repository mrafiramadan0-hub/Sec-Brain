import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/todo_item.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.secbrain.app/widget',
  );

  /// Sinkronisasi data terkini ke Android Home Screen Widget
  static Future<void> syncWidgetData(BrainStore store) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final todayTodos = store.todos
          .where((t) => t.timeframe == TodoTimeframe.today)
          .toList();
      final doneCount = todayTodos.where((t) => t.done).length;
      final totalCount = todayTodos.length;

      String countText;
      if (totalCount == 0) {
        countText = 'Belum ada target hari ini';
      } else if (doneCount == totalCount) {
        countText = '$doneCount/$totalCount Selesai 🎉';
      } else {
        countText = '$doneCount/$totalCount To-Do Selesai';
      }

      // Cari to-do aktif berikutnya yang belum selesai
      final pendingTodo = todayTodos.where((t) => !t.done).firstOrNull;
      final pendingTask = store.tasks.where((t) => !t.done).firstOrNull;

      String titleText;
      String subtitleText;

      if (pendingTodo != null) {
        titleText = pendingTodo.title;
        subtitleText = 'Target Hari Ini • ${pendingTodo.category}';
      } else if (pendingTask != null) {
        titleText = pendingTask.title;
        subtitleText = 'Agenda • Prioritas: ${pendingTask.priority}';
      } else if (totalCount > 0 && doneCount == totalCount) {
        titleText = 'Semua target hari ini selesai!';
        subtitleText = 'Luar biasa, produktivitas Anda optimal';
      } else {
        titleText = 'Kelola pikiran & target harian';
        subtitleText = 'Tap untuk membuka SecBrain';
      }

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_todo_title', titleText);
      await prefs.setString('widget_todo_count', countText);
      await prefs.setString('widget_todo_subtitle', subtitleText);

      // Trigger Native Android Widget Update
      await _channel.invokeMethod('updateWidget', {
        'todoTitle': titleText,
        'todoCount': countText,
        'todoSubtitle': subtitleText,
      });
    } catch (e) {
      debugPrint('Widget sync error: $e');
    }
  }
}
