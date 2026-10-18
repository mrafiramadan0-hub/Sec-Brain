import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/habit.dart';
import '../models/todo_item.dart';

class BackupService {
  /// Export all SecBrain data to formatted JSON string
  static String exportAllToJson(BrainStore store) {
    final data = {
      'app': 'SecBrain',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': store.tasks.map((e) => e.toJson()).toList(),
      'notes': store.notes.map((e) => e.toJson()).toList(),
      'schedules': store.schedules.map((e) => e.toJson()).toList(),
      'transactions': store.transactions.map((e) => e.toJson()).toList(),
      'bills': store.bills.map((e) => e.toJson()).toList(),
      'investments': store.investments.map((e) => e.toJson()).toList(),
      'savingsGoals': store.savingsGoals.map((e) => e.toJson()).toList(),
      'memories': store.memories.map((e) => e.toJson()).toList(),
      'habits': store.habits.map((e) => e.toJson()).toList(),
      'todos': store.todos.map((e) => e.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Import and restore data from a JSON string into store
  static bool importFromJson(String jsonString, BrainStore store) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return false;

      if (decoded.containsKey('tasks') && decoded['tasks'] is List) {
        store.tasks.clear();
        for (final item in decoded['tasks'] as List) {
          if (item is Map<String, dynamic>) {
            store.tasks.add(Task.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('notes') && decoded['notes'] is List) {
        store.notes.clear();
        for (final item in decoded['notes'] as List) {
          if (item is Map<String, dynamic>) {
            store.notes.add(Note.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('schedules') && decoded['schedules'] is List) {
        store.schedules.clear();
        for (final item in decoded['schedules'] as List) {
          if (item is Map<String, dynamic>) {
            store.schedules.add(CourseSchedule.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('transactions') &&
          decoded['transactions'] is List) {
        store.transactions.clear();
        for (final item in decoded['transactions'] as List) {
          if (item is Map<String, dynamic>) {
            store.transactions.add(TransactionItem.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('bills') && decoded['bills'] is List) {
        store.bills.clear();
        for (final item in decoded['bills'] as List) {
          if (item is Map<String, dynamic>) {
            store.bills.add(Bill.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('investments') &&
          decoded['investments'] is List) {
        store.investments.clear();
        for (final item in decoded['investments'] as List) {
          if (item is Map<String, dynamic>) {
            store.investments.add(Investment.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('savingsGoals') &&
          decoded['savingsGoals'] is List) {
        store.savingsGoals.clear();
        for (final item in decoded['savingsGoals'] as List) {
          if (item is Map<String, dynamic>) {
            store.savingsGoals.add(SavingsGoal.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('memories') && decoded['memories'] is List) {
        store.memories.clear();
        for (final item in decoded['memories'] as List) {
          if (item is Map<String, dynamic>) {
            store.memories.add(Memory.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('habits') && decoded['habits'] is List) {
        store.habits.clear();
        for (final item in decoded['habits'] as List) {
          if (item is Map<String, dynamic>) {
            store.habits.add(Habit.fromJson(item));
          }
        }
      }

      if (decoded.containsKey('todos') && decoded['todos'] is List) {
        store.todos.clear();
        for (final item in decoded['todos'] as List) {
          if (item is Map<String, dynamic>) {
            store.todos.add(TodoItem.fromJson(item));
          }
        }
      }

      store.save();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Export transactions to CSV format compatible with Excel / Google Sheets
  static String exportTransactionsToCsv(BrainStore store) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('No,Tipe,Kategori,Deskripsi,Jumlah (IDR)');

    int index = 1;
    for (final tx in store.transactions) {
      final type = tx.income ? 'Pemasukan' : 'Pengeluaran';
      // Escape commas in description/category
      final category = _escapeCsv(tx.category);
      final title = _escapeCsv(tx.title);
      final amount = tx.amount.toStringAsFixed(0);
      buffer.writeln('$index,$type,$category,$title,$amount');
      index++;
    }

    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Copy text to clipboard and show snackbar notification
  static Future<void> copyToClipboard(
    BuildContext context,
    String content,
    String successMessage,
  ) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xFF235A4C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
