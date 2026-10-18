import 'package:flutter/material.dart';

import '../main.dart';
import 'backup_dialog.dart';

Future<void> showGlobalSearchDialog(
  BuildContext context,
  BrainStore store, {
  void Function(int index)? onNavigate,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        _GlobalSearchDialog(store: store, onNavigate: onNavigate),
  );
}

class _GlobalSearchDialog extends StatefulWidget {
  const _GlobalSearchDialog({required this.store, this.onNavigate});
  final BrainStore store;
  final void Function(int index)? onNavigate;

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final matchedTasks = widget.store.tasks.where((t) {
      return t.title.toLowerCase().contains(_query) ||
          t.category.toLowerCase().contains(_query);
    }).toList();

    final matchedNotes = widget.store.notes.where((n) {
      final tagsMatch = n.tags.any((tag) => tag.toLowerCase().contains(_query));
      return n.title.toLowerCase().contains(_query) ||
          n.body.toLowerCase().contains(_query) ||
          n.type.toLowerCase().contains(_query) ||
          tagsMatch;
    }).toList();

    final matchedSchedules = widget.store.schedules.where((s) {
      return s.courseName.toLowerCase().contains(_query) ||
          s.lecturer.toLowerCase().contains(_query) ||
          s.room.toLowerCase().contains(_query) ||
          s.day.toLowerCase().contains(_query);
    }).toList();

    final matchedTransactions = widget.store.transactions.where((tx) {
      return tx.title.toLowerCase().contains(_query) ||
          tx.category.toLowerCase().contains(_query);
    }).toList();

    final matchedHabits = widget.store.habits.where((h) {
      return h.title.toLowerCase().contains(_query) ||
          h.description.toLowerCase().contains(_query);
    }).toList();

    final totalResults =
        matchedTasks.length +
        matchedNotes.length +
        matchedSchedules.length +
        matchedTransactions.length +
        matchedHabits.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : ink,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: widget.store.accentColor,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF26322C) : paper,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF37463E)
                                  : const Color(0xFFD4DAD5),
                            ),
                          ),
                          child: const Text(
                            'ESC',
                            style: TextStyle(
                              fontSize: 10,
                              color: muted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  hintText:
                      'Cari tugas, catatan, jadwal kuliah, transaksi, habit...',
                  hintStyle: const TextStyle(fontSize: 13, color: muted),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF26322C) : paper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _query.isEmpty
                  ? _buildQuickCommands(context, widget.store)
                  : (totalResults == 0
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 40,
                                  color: muted,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tidak ditemukan hasil untuk "$_query"',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : ink,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              if (matchedTasks.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'TUGAS (${matchedTasks.length})',
                                  widget.store.accentColor,
                                ),
                                ...matchedTasks.map(
                                  (t) => ListTile(
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isDark
                                          ? widget.store.accentColor.withValues(
                                              alpha: 0.2,
                                            )
                                          : widget.store.accentColor.withValues(
                                              alpha: 0.12,
                                            ),
                                      child: Icon(
                                        Icons.check,
                                        size: 14,
                                        color: widget.store.accentColor,
                                      ),
                                    ),
                                    title: Text(
                                      t.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : ink,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${t.category} • ${t.priority}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: muted,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onNavigate?.call(1);
                                    },
                                  ),
                                ),
                              ],
                              if (matchedNotes.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'CATATAN (${matchedNotes.length})',
                                  const Color(0xFF5D8AA8),
                                ),
                                ...matchedNotes.map(
                                  (n) => ListTile(
                                    leading: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: blueLight,
                                      child: Icon(
                                        Icons.notes,
                                        size: 14,
                                        color: Color(0xFF5D8AA8),
                                      ),
                                    ),
                                    title: Text(
                                      n.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      n.tags.isNotEmpty
                                          ? '${n.type} • ${n.tags.join(" ")}'
                                          : n.type,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: muted,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showNoteDetailDialog(
                                        context,
                                        widget.store,
                                        n,
                                      );
                                    },
                                  ),
                                ),
                              ],
                              if (matchedSchedules.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'JADWAL KULIAH (${matchedSchedules.length})',
                                  widget.store.accentColor,
                                ),
                                ...matchedSchedules.map(
                                  (s) => ListTile(
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isDark
                                          ? widget.store.accentColor.withValues(
                                              alpha: 0.2,
                                            )
                                          : widget.store.accentColor.withValues(
                                              alpha: 0.12,
                                            ),
                                      child: Icon(
                                        Icons.school,
                                        size: 14,
                                        color: widget.store.accentColor,
                                      ),
                                    ),
                                    title: Text(
                                      s.courseName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : ink,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${s.day}, ${s.startTime}-${s.endTime} • ${s.room}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: muted,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onNavigate?.call(3);
                                    },
                                  ),
                                ),
                              ],
                              if (matchedTransactions.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'TRANSAKSI (${matchedTransactions.length})',
                                  coral,
                                ),
                                ...matchedTransactions.map(
                                  (tx) => ListTile(
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: tx.income
                                          ? (isDark
                                                ? widget.store.accentColor
                                                      .withValues(alpha: 0.2)
                                                : widget.store.accentColor
                                                      .withValues(alpha: 0.12))
                                          : (isDark
                                                ? coral.withValues(alpha: 0.2)
                                                : coralLight),
                                      child: Icon(
                                        tx.income
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 14,
                                        color: tx.income
                                            ? widget.store.accentColor
                                            : coral,
                                      ),
                                    ),
                                    title: Text(
                                      tx.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : ink,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${tx.category} • ${money(tx.amount)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: muted,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onNavigate?.call(6);
                                    },
                                  ),
                                ),
                              ],
                              if (matchedHabits.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'HABITS (${matchedHabits.length})',
                                  const Color(0xFF7E57C2),
                                ),
                                ...matchedHabits.map(
                                  (h) => ListTile(
                                    leading: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: amberLight,
                                      child: Icon(
                                        Icons.track_changes,
                                        size: 14,
                                        color: Color(0xFF9A7B2C),
                                      ),
                                    ),
                                    title: Text(
                                      h.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      h.description.isNotEmpty
                                          ? h.description
                                          : 'Streak: ${h.currentStreak} hari',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: muted,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onNavigate?.call(7);
                                    },
                                  ),
                                ),
                              ],
                            ],
                          )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickCommands(BuildContext context, BrainStore store) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSectionHeader('AKSI CEPAT (COMMANDS)', muted),
        ListTile(
          leading: Icon(Icons.auto_awesome, color: store.accentColor, size: 20),
          title: const Text(
            'Tanya AI Assistant (Smart Actions)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Perintah otomatis untuk jadwal, finance, tugas & catatan',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onNavigate?.call(9);
          },
        ),
        ListTile(
          leading: Icon(Icons.add_task, color: store.accentColor, size: 20),
          title: const Text(
            'Buat Tugas Baru',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Catat komitmen dan agenda baru',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          onTap: () {
            Navigator.pop(context);
            showTaskDialog(context, store);
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.note_add,
            color: Color(0xFF5D8AA8),
            size: 20,
          ),
          title: const Text(
            'Tulis Catatan Baru',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Gunakan template rapat, workshop, atau bebas',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          onTap: () {
            Navigator.pop(context);
            showNoteDialog(context, store);
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.calendar_month,
            color: Color(0xFF7E57C2),
            size: 20,
          ),
          title: const Text(
            'Buka Kalender Terpadu',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Lihat semua agenda kuliah, deadline, dan tagihan',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onNavigate?.call(4);
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.track_changes,
            color: Color(0xFF9A7B2C),
            size: 20,
          ),
          title: const Text(
            'Kelola Habits & Refleksi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Pantau konsistensi dan evaluasi harian',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onNavigate?.call(7);
          },
        ),
        ListTile(
          leading: Icon(Icons.backup, color: store.accentColor, size: 20),
          title: const Text(
            'Ekspor & Backup Data (JSON/CSV)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Simpan atau restore seluruh database SecBrain',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          onTap: () {
            Navigator.pop(context);
            showBackupDialog(context, store);
          },
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined, color: muted, size: 20),
          title: const Text(
            'Ganti Tema Tampilan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Beralih antara Mode Gelap dan Mode Terang',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          onTap: () {
            Navigator.pop(context);
            store.setThemeMode(
              store.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            );
          },
        ),
      ],
    );
  }
}
