import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../main.dart';
import '../models/habit.dart';
import '../models/todo_item.dart';

class SyncService {
  static StreamSubscription? _scheduleSub;
  static StreamSubscription? _taskSub;
  static StreamSubscription? _financeSub;
  static StreamSubscription? _noteSub;
  static StreamSubscription? _habitSub;
  static StreamSubscription? _billSub;
  static StreamSubscription? _savingsSub;
  static StreamSubscription? _investSub;
  static StreamSubscription? _memorySub;
  static StreamSubscription? _todoSub;

  static bool _persistenceConfigured = false;

  static FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        if (!_persistenceConfigured && !kIsWeb) {
          firestore.settings = const Settings(persistenceEnabled: true);
          _persistenceConfigured = true;
        }
        return firestore;
      }
    } catch (e) {
      debugPrint('Cloud Firestore not available: $e');
    }
    return null;
  }

  /// Mengunggah seluruh data lokal ke Cloud Firestore
  static Future<void> uploadLocalToCloud(
    String userId,
    BrainStore store,
  ) async {
    final db = _db;
    if (db == null || userId.isEmpty) return;

    try {
      final userRef = db.collection('users').doc(userId);

      // 1. Simpan metadata overview pengguna
      await userRef.set({
        'lastSynced': FieldValue.serverTimestamp(),
        'userName': store.userName,
        'userEmail': store.userEmail,
        'tasksCount': store.tasks.length,
        'notesCount': store.notes.length,
        'schedulesCount': store.schedules.length,
        'habitsCount': store.habits.length,
        'transactionsCount': store.transactions.length,
        'balance': store.balance,
      }, SetOptions(merge: true));

      // 2. Unggah data koleksi utama (users/{uid}/...)
      await _uploadCollection(
        userRef.collection('schedules'),
        store.schedules.map((s) => s.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('tasks'),
        store.tasks.map((t) => t.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('finance'),
        store.transactions.map((tr) => tr.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('notes'),
        store.notes.map((n) => n.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('habits'),
        store.habits.map((h) => h.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('todos'),
        store.todos.map((t) => t.toJson()).toList(),
      );

      // 3. Unggah data pendukung (bills, savings_goals, investments, memories)
      await _uploadCollection(
        userRef.collection('bills'),
        store.bills.map((b) => b.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('savings_goals'),
        store.savingsGoals.map((g) => g.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('investments'),
        store.investments.map((i) => i.toJson()).toList(),
      );
      await _uploadCollection(
        userRef.collection('memories'),
        store.memories.map((m) => m.toJson()).toList(),
      );

      debugPrint('Sync: Data lokal berhasil diunggah ke Cloud Firestore.');
    } catch (e) {
      debugPrint('Sync upload error: $e');
    }
  }

  /// Mengunduh seluruh data milik user dari Cloud Firestore dan menyinkronkan ke local store
  static Future<bool> fetchAndSyncFromCloud(
    String userId,
    BrainStore store,
  ) async {
    final db = _db;
    if (db == null || userId.isEmpty) return false;

    try {
      final userRef = db.collection('users').doc(userId);

      // Ambil snapshot koleksi utama secara paralel
      final results = await Future.wait([
        userRef.collection('schedules').get(),
        userRef.collection('tasks').get(),
        userRef.collection('finance').get(),
        userRef.collection('notes').get(),
        userRef.collection('habits').get(),
        userRef.collection('bills').get(),
        userRef.collection('savings_goals').get(),
        userRef.collection('investments').get(),
        userRef.collection('memories').get(),
        userRef.collection('todos').get(),
      ]);

      final schedulesSnap = results[0];
      final tasksSnap = results[1];
      final financeSnap = results[2];
      final notesSnap = results[3];
      final habitsSnap = results[4];
      final billsSnap = results[5];
      final savingsSnap = results[6];
      final investSnap = results[7];
      final memoriesSnap = results[8];
      final todosSnap = results[9];

      final bool hasCloudData =
          schedulesSnap.docs.isNotEmpty ||
          tasksSnap.docs.isNotEmpty ||
          financeSnap.docs.isNotEmpty ||
          notesSnap.docs.isNotEmpty ||
          habitsSnap.docs.isNotEmpty ||
          billsSnap.docs.isNotEmpty ||
          todosSnap.docs.isNotEmpty;

      // Jika data cloud masih kosong untuk akun ini, upload data lokal yang ada
      if (!hasCloudData) {
        final bool hasLocalData =
            store.tasks.isNotEmpty ||
            store.notes.isNotEmpty ||
            store.schedules.isNotEmpty ||
            store.transactions.isNotEmpty ||
            store.habits.isNotEmpty ||
            store.todos.isNotEmpty;
        if (hasLocalData) {
          await uploadLocalToCloud(userId, store);
        }
        return false;
      }

      // Deserialisasi data dari Cloud Firestore
      final cloudSchedules = schedulesSnap.docs
          .map((d) => CourseSchedule.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudTasks = tasksSnap.docs
          .map((d) => Task.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudTransactions = financeSnap.docs
          .map((d) => TransactionItem.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudNotes = notesSnap.docs
          .map((d) => Note.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudHabits = habitsSnap.docs
          .map((d) => Habit.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudBills = billsSnap.docs
          .map((d) => Bill.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudSavings = savingsSnap.docs
          .map((d) => SavingsGoal.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudInvestments = investSnap.docs
          .map((d) => Investment.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudMemories = memoriesSnap.docs
          .map((d) => Memory.fromJson({...d.data(), 'id': d.id}))
          .toList();
      final cloudTodos = todosSnap.docs
          .map((d) => TodoItem.fromJson({...d.data(), 'id': d.id}))
          .toList();

      store.isSyncing = true;
      try {
        store.applyCloudData(
          cloudTasks: cloudTasks,
          cloudNotes: cloudNotes,
          cloudSchedules: cloudSchedules,
          cloudTransactions: cloudTransactions,
          cloudHabits: cloudHabits,
          cloudBills: cloudBills,
          cloudSavingsGoals: cloudSavings,
          cloudInvestments: cloudInvestments,
          cloudMemories: cloudMemories,
          cloudTodos: cloudTodos,
          saveToLocal: true,
        );
      } finally {
        store.isSyncing = false;
      }

      debugPrint(
        'Sync: Data berhasil diunduh dari cloud dan diterapkan ke lokal.',
      );
      return true;
    } catch (e) {
      debugPrint('Sync fetch error: $e');
      return false;
    }
  }

  /// Memulai sinkronisasi realtime snapshot listener lintas perangkat
  static void startRealtimeSync(String userId, BrainStore store) {
    stopRealtimeSync();
    final db = _db;
    if (db == null || userId.isEmpty) return;

    final userRef = db.collection('users').doc(userId);

    _scheduleSub = userRef.collection('schedules').snapshots().listen((snap) {
      if (store.isSyncing || snap.metadata.hasPendingWrites) return;
      final items = snap.docs
          .map((d) => CourseSchedule.fromJson({...d.data(), 'id': d.id}))
          .toList();
      store.applyCloudData(cloudSchedules: items, saveToLocal: true);
    }, onError: (e) => debugPrint('Realtime schedules sync error: $e'));

    _taskSub = userRef.collection('tasks').snapshots().listen((snap) {
      if (store.isSyncing || snap.metadata.hasPendingWrites) return;
      final items = snap.docs
          .map((d) => Task.fromJson({...d.data(), 'id': d.id}))
          .toList();
      store.applyCloudData(cloudTasks: items, saveToLocal: true);
    }, onError: (e) => debugPrint('Realtime tasks sync error: $e'));

    _financeSub = userRef.collection('finance').snapshots().listen((snap) {
      if (store.isSyncing || snap.metadata.hasPendingWrites) return;
      final items = snap.docs
          .map((d) => TransactionItem.fromJson({...d.data(), 'id': d.id}))
          .toList();
      store.applyCloudData(cloudTransactions: items, saveToLocal: true);
    }, onError: (e) => debugPrint('Realtime finance sync error: $e'));

    _noteSub = userRef.collection('notes').snapshots().listen((snap) {
      if (store.isSyncing || snap.metadata.hasPendingWrites) return;
      final items = snap.docs
          .map((d) => Note.fromJson({...d.data(), 'id': d.id}))
          .toList();
      store.applyCloudData(cloudNotes: items, saveToLocal: true);
    }, onError: (e) => debugPrint('Realtime notes sync error: $e'));

    _habitSub = userRef.collection('habits').snapshots().listen((snap) {
      if (store.isSyncing || snap.metadata.hasPendingWrites) return;
      final items = snap.docs
          .map((d) => Habit.fromJson({...d.data(), 'id': d.id}))
          .toList();
      store.applyCloudData(cloudHabits: items, saveToLocal: true);
    }, onError: (e) => debugPrint('Realtime habits sync error: $e'));

    _todoSub = userRef.collection('todos').snapshots().listen((snap) {
      if (store.isSyncing || snap.metadata.hasPendingWrites) return;
      final items = snap.docs
          .map((d) => TodoItem.fromJson({...d.data(), 'id': d.id}))
          .toList();
      store.applyCloudData(cloudTodos: items, saveToLocal: true);
    }, onError: (e) => debugPrint('Realtime todos sync error: $e'));
  }

  /// Menghentikan seluruh realtime snapshot listener
  static void stopRealtimeSync() {
    _scheduleSub?.cancel();
    _taskSub?.cancel();
    _financeSub?.cancel();
    _noteSub?.cancel();
    _habitSub?.cancel();
    _billSub?.cancel();
    _savingsSub?.cancel();
    _investSub?.cancel();
    _memorySub?.cancel();
    _todoSub?.cancel();

    _scheduleSub = null;
    _taskSub = null;
    _financeSub = null;
    _noteSub = null;
    _habitSub = null;
    _billSub = null;
    _savingsSub = null;
    _investSub = null;
    _memorySub = null;
    _todoSub = null;
  }

  /// Listener snapshot publik untuk pemanggilan fleksibel
  static StreamSubscription? listenToRealtimeUpdates(
    String userId,
    BrainStore store,
  ) {
    startRealtimeSync(userId, store);
    return _taskSub;
  }

  /// Kompatibilitas method lama
  static Future<void> syncUserData(String userId, BrainStore store) async {
    await uploadLocalToCloud(userId, store);
  }

  static Future<void> _uploadCollection(
    CollectionReference ref,
    List<Map<String, dynamic>> items,
  ) async {
    final db = _db;
    if (db == null) return;

    try {
      final snap = await ref.get();
      final currentIds = <String>{};
      for (final item in items) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          currentIds.add(id);
        }
      }

      final batch = db.batch();

      // Hapus dokumen yang sudah tidak ada di lokal
      for (final doc in snap.docs) {
        if (!currentIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }

      // Simpan atau perbarui dokumen dengan ID yang konsisten
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final id = item['id']?.toString() ?? 'item_$i';
        final docRef = ref.doc(id);
        batch.set(docRef, item, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Upload collection ${ref.path} error: $e');
    }
  }
}
