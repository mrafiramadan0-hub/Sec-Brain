import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/todo_item.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  TodoTimeframe _selectedTimeframe = TodoTimeframe.today;
  bool _hideCompleted = false;

  final List<String> _quickCategories = [
    'Umum',
    'Kuliah',
    'Kerja',
    'Pribadi',
    'Target',
  ];
  final String _selectedCategory = 'Umum';

  @override
  void initState() {
    super.initState();
    // 5 tabs: Semua, Hari Ini, Minggu Ini, Bulan Ini, Tahun Ini
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _selectedTimeframe = TodoTimeframe.today;
          } else {
            _selectedTimeframe = TodoTimeframe.values[_tabController.index - 1];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitTodo(BrainStore store) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final targetTimeframe = _tabController.index == 0
        ? _selectedTimeframe
        : TodoTimeframe.values[_tabController.index - 1];

    final newTodo = TodoItem(
      title: text,
      timeframe: targetTimeframe,
      category: _selectedCategory,
    );

    store.addTodo(newTodo);
    _textController.clear();
    HapticFeedback.lightImpact();
  }

  void _showEditDialog(BuildContext context, BrainStore store, TodoItem item) {
    final editController = TextEditingController(text: item.title);
    TodoTimeframe editTimeframe = item.timeframe;
    String editCategory = item.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_note, color: store.accentColor),
              const SizedBox(width: 8),
              const Text('Edit To-Do', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: editController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Judul / Isi To-Do',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rentang Waktu:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: TodoTimeframe.values.map((tf) {
                    final isSel = editTimeframe == tf;
                    return ChoiceChip(
                      label: Text(
                        tf.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setDialogState(() => editTimeframe = tf);
                      },
                      selectedColor: store.accentColor.withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kategori:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _quickCategories.map((cat) {
                    final isSel = editCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setDialogState(() => editCategory = cat);
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
              style: FilledButton.styleFrom(backgroundColor: store.accentColor),
              onPressed: () {
                final newText = editController.text.trim();
                if (newText.isNotEmpty) {
                  store.updateTodo(
                    item,
                    title: newText,
                    timeframe: editTimeframe,
                    category: editCategory,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCompleted(
    BuildContext context,
    BrainStore store,
    TodoTimeframe? tf,
  ) {
    final title = tf != null
        ? 'Hapus yang selesai (${tf.label})?'
        : 'Hapus semua to-do yang sudah selesai?';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Hapus'),
        content: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: coral),
            onPressed: () {
              store.clearCompletedTodos(tf);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 16.0 : 28.0;

    final allTodos = store.todos;
    final totalCount = allTodos.length;
    final completedCount = allTodos.where((t) => t.done).length;
    final overallProgress = totalCount == 0
        ? 0.0
        : (completedCount / totalCount).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header Stats & Title
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, isMobile ? 12 : 20, hPad, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CHECKLIST & TARGET',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'To-Do List',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: store.accentColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$completedCount/$totalCount Selesai',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: store.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Centang cepat untuk target Hari ini, Minggu ini, Bulan ini, & Tahun ini.',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Quick Action Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: muted),
                      tooltip: 'Menu Opsi',
                      onSelected: (val) {
                        if (val == 'toggle_completed') {
                          setState(() => _hideCompleted = !_hideCompleted);
                        } else if (val == 'clear_completed') {
                          final currentTf = _tabController.index == 0
                              ? null
                              : TodoTimeframe.values[_tabController.index - 1];
                          _confirmClearCompleted(context, store, currentTf);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'toggle_completed',
                          child: Row(
                            children: [
                              Icon(
                                _hideCompleted
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hideCompleted
                                    ? 'Tampilkan yang selesai'
                                    : 'Sembunyikan yang selesai',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear_completed',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_sweep_outlined,
                                size: 18,
                                color: coral,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hapus yang sudah selesai',
                                style: TextStyle(fontSize: 12, color: coral),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Overall progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      store.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2823)
                        : const Color(0xFFEBEFEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: isMobile,
                    tabAlignment: isMobile ? TabAlignment.start : null,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: isDark ? const Color(0xFF2E3D35) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    labelColor: store.accentColor,
                    unselectedLabelColor: muted,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    padding: const EdgeInsets.all(3),
                    tabs: [
                      const Tab(text: 'Semua'),
                      Tab(text: TodoTimeframe.today.label),
                      Tab(text: TodoTimeframe.thisWeek.label),
                      Tab(text: TodoTimeframe.thisMonth.label),
                      Tab(text: TodoTimeframe.thisYear.label),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Add Input Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: store.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: _tabController.index == 0
                                  ? 'Tambah to-do baru untuk ${_selectedTimeframe.label}...'
                                  : 'Tambah to-do baru untuk ${TodoTimeframe.values[_tabController.index - 1].label}...',
                              hintStyle: const TextStyle(
                                color: muted,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _submitTodo(store),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                            color: store.accentColor,
                            size: 20,
                          ),
                          onPressed: () => _submitTodo(store),
                          tooltip: 'Tambah (Enter)',
                        ),
                      ],
                    ),
                    // Quick timeframe selector when in "Semua" tab
                    if (_tabController.index == 0)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text(
                              'Target:',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                            const SizedBox(width: 6),
                            ...TodoTimeframe.values.map((tf) {
                              final isSel = _selectedTimeframe == tf;
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ChoiceChip(
                                  label: Text(
                                    tf.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSel,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() => _selectedTimeframe = tf);
                                    }
                                  },
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  selectedColor: store.accentColor.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Tab Semua (Grouped by timeframe)
                _buildAllTimeframesView(store, hPad),
                // 2. Tab Hari Ini
                _buildSingleTimeframeView(store, TodoTimeframe.today, hPad),
                // 3. Tab Minggu Ini
                _buildSingleTimeframeView(store, TodoTimeframe.thisWeek, hPad),
                // 4. Tab Bulan Ini
                _buildSingleTimeframeView(store, TodoTimeframe.thisMonth, hPad),
                // 5. Tab Tahun Ini
                _buildSingleTimeframeView(store, TodoTimeframe.thisYear, hPad),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// View untuk Tab "Semua" (Menampilkan 4 Section: Hari Ini, Minggu Ini, Bulan Ini, Tahun Ini)
  Widget _buildAllTimeframesView(BrainStore store, double hPad) {
    return RefreshIndicator(
      onRefresh: () async => store.load(),
      color: store.accentColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 80),
        children: TodoTimeframe.values.map((tf) {
          var items = store.todos.where((t) => t.timeframe == tf).toList();
          if (_hideCompleted) {
            items = items.where((t) => !t.done).toList();
          }
          final totalInTf = store.todos.where((t) => t.timeframe == tf).length;
          final doneInTf = store.todos
              .where((t) => t.timeframe == tf && t.done)
              .length;

          return _buildTimeframeSection(
            store: store,
            timeframe: tf,
            items: items,
            totalCount: totalInTf,
            doneCount: doneInTf,
          );
        }).toList(),
      ),
    );
  }

  /// Widget Section per Kategori Waktu di Tab Semua
  Widget _buildTimeframeSection({
    required BrainStore store,
    required TodoTimeframe timeframe,
    required List<TodoItem> items,
    required int totalCount,
    required int doneCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalCount == 0
        ? 0.0
        : (doneCount / totalCount).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getTimeframeColor(timeframe)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTimeframeIcon(timeframe),
                    size: 16,
                    color: _getTimeframeColor(timeframe),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeframe.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeframe.subtitle,
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$doneCount/$totalCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: totalCount > 0 && doneCount == totalCount
                        ? green
                        : muted,
                  ),
                ),
              ],
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTimeframeColor(timeframe),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    totalCount == 0
                        ? 'Belum ada to-do di ${timeframe.label.toLowerCase()}.'
                        : 'Semua to-do sudah selesai 🎉',
                    style: TextStyle(
                      color: muted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...items.map((item) => _buildTodoTile(store, item)),
          ],
        ),
      ),
    );
  }

  /// View untuk Tab Single Timeframe (Hari Ini / Minggu Ini / Bulan Ini / Tahun Ini)
  Widget _buildSingleTimeframeView(
    BrainStore store,
    TodoTimeframe timeframe,
    double hPad,
  ) {
    var items = store.todos.where((t) => t.timeframe == timeframe).toList();
    final totalCount = items.length;
    final doneCount = items.where((t) => t.done).length;

    if (_hideCompleted) {
      items = items.where((t) => !t.done).toList();
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => store.load(),
        color: store.accentColor,
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 80),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getTimeframeIcon(timeframe),
                        size: 54,
                        color: _getTimeframeColor(timeframe)
                            .withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        totalCount == 0
                            ? 'Belum ada to-do untuk ${timeframe.label}'
                            : 'Semua to-do ${timeframe.label} sudah selesai!',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalCount == 0
                            ? 'Ketik target atau tugasmu di kolom input di atas dan tekan Enter.'
                            : 'Hebat! Kamu telah menyelesaikan seluruh target $doneCount to-do 🎉',
                        style: const TextStyle(fontSize: 11, color: muted),
                        textAlign: TextAlign.center,
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

    return RefreshIndicator(
      onRefresh: () async => store.load(),
      color: store.accentColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 80),
        itemCount: items.length,
        itemBuilder: (ctx, idx) {
          final item = items[idx];
          return _buildTodoTile(store, item);
        },
      ),
    );
  }

  /// Single Item Tile dengan Checkbox ("Centang Doang")
  Widget _buildTodoTile(BrainStore store, TodoItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(
        'todo_${item.id}_${item.timeframe.name}_${identityHashCode(item)}',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: coral.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        store.deleteTodo(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('To-do "${item.title}" dihapus'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => store.addTodo(item),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: item.done
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.015))
              : (isDark ? const Color(0xFF222B25) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: item.done
                ? Colors.transparent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            store.toggleTodo(item);
            HapticFeedback.selectionClick();
          },
          onLongPress: () => _showEditDialog(context, store, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Centang Checkbox Bulat
                Transform.scale(
                  scale: 1.15,
                  child: Checkbox(
                    value: item.done,
                    activeColor: store.accentColor,
                    checkColor: Colors.white,
                    shape: const CircleBorder(),
                    side: BorderSide(
                      color: item.done
                          ? store.accentColor
                          : (isDark ? Colors.white54 : Colors.black45),
                      width: 1.5,
                    ),
                    onChanged: (_) {
                      store.toggleTodo(item);
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
                const SizedBox(width: 4),

                // Judul & Detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: item.done
                              ? FontWeight.normal
                              : FontWeight.w600,
                          color: item.done
                              ? muted.withValues(alpha: 0.6)
                              : (isDark ? Colors.white : ink),
                          decoration: item.done
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: muted,
                        ),
                      ),
                      if (item.category.isNotEmpty &&
                          item.category != 'Umum') ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 9,
                              color: muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tombol Edit & Hapus Cepat
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 16, color: muted),
                  onPressed: () => _showEditDialog(context, store, item),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit to-do',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTimeframeColor(TodoTimeframe tf, [BrainStore? store]) {
    switch (tf) {
      case TodoTimeframe.today:
        return store?.accentColor ?? const Color(0xFF365C4C);
      case TodoTimeframe.thisWeek:
        return const Color(0xFF2E6B8E); // blue
      case TodoTimeframe.thisMonth:
        return const Color(0xFF8E5E2E); // amber/brown
      case TodoTimeframe.thisYear:
        return const Color(0xFF7A368E); // purple
    }
  }

  IconData _getTimeframeIcon(TodoTimeframe tf) {
    switch (tf) {
      case TodoTimeframe.today:
        return Icons.wb_sunny_outlined;
      case TodoTimeframe.thisWeek:
        return Icons.calendar_view_week_outlined;
      case TodoTimeframe.thisMonth:
        return Icons.calendar_month_outlined;
      case TodoTimeframe.thisYear:
        return Icons.flag_outlined;
    }
  }
}
