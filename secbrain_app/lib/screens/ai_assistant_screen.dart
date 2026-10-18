import 'package:flutter/material.dart';

import '../main.dart';
import '../models/habit.dart';
import '../models/todo_item.dart';
import '../services/ai_service.dart';
import '../widgets/secbrain_logo.dart';

class AiChatMessage {
  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionResult,
    this.isError = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  AiActionResult? actionResult;
  final bool isError;
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  bool _hasInputText = false;

  final List<String> _quickSuggestions = const [
    'To-do beli susu & vitamin hari ini',
    'To-do selesaikan skripsi tahun ini',
    'Besok rapat proyek jam 19.00 di CC',
    'Terima beasiswa 6000000',
    'Beli makan siang 25000',
    'Jadwal kuliah Fisika Dasar Senin jam 08.00 di Lab',
    'Catat ide judul skripsi kecerdasan buatan',
    'Tugas resume jurnal deadline jumat',
    'Tambah habit minum air 2 liter',
  ];

  @override
  void initState() {
    super.initState();
    _initWelcomeMessage();
    _inputController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasInputText) {
      setState(() {
        _hasInputText = hasText;
      });
    }
  }

  void _initWelcomeMessage() {
    _messages.add(
      AiChatMessage(
        id: 'welcome_msg',
        text:
            'Halo! Saya **SecBrain AI Assistant** dengan integrasi aksi cerdas real-time.\n\n'
            'Ketik atau pilih perintah di bawah untuk mencatat keuangan, membuat agenda, menjadwalkan kuliah, atau menyimpan catatan otomatis!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? overrideText]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty || _isLoading) return;

    final store = StoreScope.of(context);

    // 1. Add User message
    setState(() {
      _messages.add(
        AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      if (overrideText == null) {
        _inputController.clear();
      }
      _isLoading = true;
    });

    _scrollToBottom();

    // 2. Prepare conversation history for API
    final history = _messages
        .where((m) => m.id != 'welcome_msg')
        .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
        .toList();

    try {
      // 3. Process via AIService
      final actionResult = await AIService.processAssistantMessage(
        userMessage: text,
        store: store,
        history: history,
        apiKey: store.geminiApiKey,
      );

      // 4. Execute Local State Mutation based on Action
      _executeLocalAction(actionResult, store);

      if (mounted) {
        setState(() {
          _messages.add(
            AiChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: actionResult.reply,
              isUser: false,
              timestamp: DateTime.now(),
              actionResult: actionResult,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error processing AI message: $e');
      if (mounted) {
        setState(() {
          _messages.add(
            AiChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text:
                  'Maaf, terjadi kendala saat memproses permintaan: $e\n\nSilakan coba lagi.',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _executeLocalAction(AiActionResult result, BrainStore store) {
    final action = result.action.toLowerCase();
    final data = result.data;

    try {
      if (action == 'add_todo' || action == 'create_todo') {
        final title = data['title']?.toString() ?? 'To-Do Baru';
        final timeframeStr = data['timeframe']?.toString() ?? 'today';
        final timeframe = TodoTimeframe.fromString(timeframeStr);
        final category = data['category']?.toString() ?? 'Umum';

        final todo = TodoItem(
          title: title,
          timeframe: timeframe,
          category: category,
        );

        store.addTodo(todo);
        result.executed = true;
        result.actionDescription =
            '${timeframe.label} • Kategori: $category • To-Do List';
      } else if (action == 'add_course_schedule' ||
          action == 'create_schedule') {
        final title =
            data['title']?.toString() ??
            data['courseName']?.toString() ??
            'Mata Kuliah Baru';
        final day = data['day']?.toString() ?? 'Senin';
        final startTime =
            data['startTime']?.toString() ??
            data['time']?.toString() ??
            '08:00';
        final endTime = data['endTime']?.toString() ?? '09:40';
        final room =
            data['room']?.toString() ??
            data['location']?.toString() ??
            'Ruang Kuliah';
        final lecturer = data['lecturer']?.toString() ?? 'Dosen Pengampu';
        final sks = (data['sks'] as num?)?.toInt() ?? 3;

        final schedule = CourseSchedule(
          courseName: title,
          day: day,
          startTime: startTime,
          endTime: endTime,
          room: room,
          lecturer: lecturer,
          sks: sks,
        );

        store.addSchedule(schedule);
        result.executed = true;
        result.actionDescription =
            '$day, $startTime - $endTime • $room ($sks SKS)';
      } else if (action == 'add_agenda_event') {
        final rawTitle = data['title']?.toString() ?? 'Agenda';
        final location = data['location']?.toString().trim() ?? '';
        final timeStr = data['time']?.toString() ?? '19:00';
        final dateStr =
            data['date']?.toString() ?? data['day']?.toString() ?? '';

        DateTime due = DateTime.now();
        final lowerDate = dateStr.toLowerCase();
        if (lowerDate.contains('besok')) {
          due = due.add(const Duration(days: 1));
        } else if (lowerDate.contains('lusa')) {
          due = due.add(const Duration(days: 2));
        } else {
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            due = parsedDate;
          }
        }

        final timeParts = timeStr.split(RegExp(r'[:.]'));
        if (timeParts.isNotEmpty) {
          final hour = int.tryParse(timeParts[0]) ?? due.hour;
          final minute = timeParts.length > 1
              ? (int.tryParse(timeParts[1]) ?? 0)
              : 0;
          due = DateTime(due.year, due.month, due.day, hour, minute);
        }

        var taskTitle = rawTitle;
        if (location.isNotEmpty &&
            !taskTitle.toLowerCase().contains(location.toLowerCase())) {
          taskTitle = '$rawTitle ($location)';
        }

        final category = rawTitle.toLowerCase().contains('rapat')
            ? 'Organization'
            : 'Personal';

        final task = Task(taskTitle, category, 'Medium', due: due);
        store.addTask(task);
        result.executed = true;
        final locSuffix = location.isNotEmpty ? ' • $location' : '';
        result.actionDescription = 'Waktu: $timeStr$locSuffix • Tasks & Agenda';
      } else if (action == 'create_task' || action == 'add_task') {
        final title = data['title']?.toString() ?? 'Tugas Baru';
        final category = data['category']?.toString() ?? 'University';
        final priority = data['priority']?.toString() ?? 'Medium';
        final dateStr =
            (data['due_date'] ?? data['due'] ?? data['date'] ?? data['day'])
                ?.toString() ??
            '';
        final timeStr = (data['due_time'] ?? data['time'])?.toString() ?? '';

        DateTime due = DateTime.now();
        final lowerDate = dateStr.toLowerCase();
        if (lowerDate.contains('besok')) {
          due = due.add(const Duration(days: 1));
        } else if (lowerDate.contains('lusa')) {
          due = due.add(const Duration(days: 2));
        } else {
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            due = parsedDate;
          } else {
            due = due.add(const Duration(hours: 24));
          }
        }

        if (timeStr.isNotEmpty) {
          final timeParts = timeStr.split(RegExp(r'[:.]'));
          if (timeParts.isNotEmpty) {
            final hour = int.tryParse(timeParts[0]) ?? due.hour;
            final minute = timeParts.length > 1
                ? (int.tryParse(timeParts[1]) ?? 0)
                : 0;
            due = DateTime(due.year, due.month, due.day, hour, minute);
          }
        }

        final task = Task(title, category, priority, due: due);
        store.addTask(task);
        result.executed = true;
        final timeSuffix = timeStr.isNotEmpty ? ' ($timeStr)' : '';
        result.actionDescription = '$title$timeSuffix • Prioritas: $priority';
      } else if (action == 'add_finance' ||
          action == 'add_income' ||
          action == 'add_expense') {
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final isIncome =
            action == 'add_income' ||
            (data['type']?.toString().toLowerCase() == 'income');
        final category =
            data['category']?.toString() ??
            (isIncome ? 'Pemasukan' : 'Lainnya');
        final note =
            data['note']?.toString() ??
            data['title']?.toString() ??
            (isIncome ? 'Pemasukan $category' : 'Pengeluaran $category');

        if (amount > 0) {
          final tx = TransactionItem(
            note.isNotEmpty
                ? note
                : '${isIncome ? "Pemasukan" : "Pengeluaran"} $category',
            amount,
            category,
            isIncome,
          );

          store.addTransaction(tx);
          result.executed = true;
          result.actionDescription =
              '${money(amount)} • Kategori: $category • Finance';
        }
      } else if (action == 'create_note') {
        final title = data['title']?.toString() ?? 'Catatan Baru';
        final content =
            data['content']?.toString() ?? data['body']?.toString() ?? title;
        final type = data['type']?.toString() ?? 'Idea';
        final tagsList = (data['tags'] is List)
            ? (data['tags'] as List).map((t) => t.toString()).toList()
            : <String>['#ai_assistant'];

        final note = Note(title, content, type, tags: tagsList);
        store.addNote(note);
        result.executed = true;
        result.actionDescription = 'Tipe: $type • Knowledge Base';
      } else if (action == 'create_habit') {
        final title = data['title']?.toString() ?? 'Habit Baru';
        final category = data['category']?.toString() ?? 'Produktivitas';

        final habit = Habit(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: category,
        );

        store.addHabit(habit);
        result.executed = true;
        result.actionDescription = 'Target: Setiap Hari • Habit Tracker';
      }
    } catch (e) {
      debugPrint('Error executing local action: $e');
      result.executed = false;
    }
  }

  void _showApiKeyDialog(BrainStore store) {
    final controller = TextEditingController(text: store.geminiApiKey);
    var obscureApiKey = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: green, size: 22),
              SizedBox(width: 8),
              Text('Konfigurasi Gemini API', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SecBrain menggunakan model Gemini 2.5 Flash-Lite berkecepatan tinggi dengan auto-failover & local fallback.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  obscureText: obscureApiKey,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key (Opsional)',
                    hintText: 'AIzaSy...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureApiKey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: muted,
                      ),
                      tooltip: obscureApiKey
                          ? 'Tampilkan API Key'
                          : 'Sembunyikan API Key',
                      onPressed: () {
                        setDialogState(() {
                          obscureApiKey = !obscureApiKey;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '💡 Biarkan kosong untuk menggunakan Cloud Engine bawaan SecBrain.',
                  style: TextStyle(fontSize: 11, color: muted),
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
              style: FilledButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                store.setGeminiApiKey(controller.text.trim());
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasApiKey = store.geminiApiKey.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Sleek Status Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2823) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF26322C)
                      : const Color(0xFFE8ECE8),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: greenLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SecBrainShieldIcon(size: 18, color: green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SecBrain AI Assistant',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showApiKeyDialog(store),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasApiKey
                                  ? 'Gemini (Custom Key)'
                                  : 'Gemini 2.5 Flash-Lite (High Speed)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white60 : muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.tune_rounded,
                              size: 11,
                              color: green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus Riwayat Chat',
                  onPressed: () {
                    setState(() {
                      _messages.clear();
                      _initWelcomeMessage();
                    });
                  },
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    size: 20,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message, store, isDark);
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF24312A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: green.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(green),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI sedang menganalisis & mengeksekusi aksi...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Horizontal Quick Suggestions
          if (_messages.length <= 4 && !_isLoading)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _quickSuggestions.length,
                separatorBuilder: (context, i) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final suggestion = _quickSuggestions[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _handleSendMessage(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF223028) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: green.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: green),
                          const SizedBox(width: 4),
                          Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white : ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Modern Bottom Input Bar
          Container(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 6,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2823) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF26322C)
                      : const Color(0xFFE8ECE8),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF28362E)
                            : const Color(0xFFF1F5F2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: muted.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.auto_awesome,
                            color: green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : ink,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Ketik aksi (misal: "terima gaji 5jt")...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : muted.withValues(alpha: 0.8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _handleSendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasInputText
                          ? store.accentColor
                          : (isDark
                                ? const Color(0xFF28362E)
                                : const Color(0xFFE4ECE6)),
                      boxShadow: _hasInputText
                          ? [
                              BoxShadow(
                                color: store.accentColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isLoading ? null : () => _handleSendMessage(),
                        child: Icon(
                          _hasInputText
                              ? Icons.arrow_upward_rounded
                              : Icons.send_rounded,
                          color: _hasInputText
                              ? Colors.white
                              : muted.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    AiChatMessage message,
    BrainStore store,
    bool isDark,
  ) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: store.accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: store.accentColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 13,
              backgroundColor: store.accentColor.withValues(alpha: 0.9),
              child: Text(
                store.userName.isNotEmpty
                    ? store.userName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Message Bubble
    final hasAction =
        message.actionResult != null &&
        message.actionResult!.action != 'chat' &&
        message.actionResult!.executed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B3224) : greenLight,
              shape: BoxShape.circle,
              border: Border.all(color: green.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.auto_awesome, color: green, size: 15),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF24312A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: message.isError
                      ? coral.withValues(alpha: 0.5)
                      : (isDark
                            ? const Color(0xFF2D3E35)
                            : const Color(0xFFE4ECE6)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _formatMarkdownText(message.text, isDark),
                  if (hasAction) ...[
                    const SizedBox(height: 10),
                    _buildExecutedActionCard(message.actionResult!, isDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutedActionCard(AiActionResult result, bool isDark) {
    IconData icon;
    Color iconColor;
    String actionTitle;
    int navIndex;
    String moduleName;

    switch (result.action) {
      case 'add_todo':
      case 'create_todo':
        icon = Icons.checklist_rounded;
        iconColor = const Color(0xFF10B981);
        actionTitle = 'To-Do List Ditambahkan';
        navIndex = 2;
        moduleName = 'To-Do List';
        break;
      case 'add_course_schedule':
      case 'create_schedule':
        icon = Icons.school_rounded;
        iconColor = const Color(0xFF10B981);
        actionTitle = 'Jadwal Kuliah Ditambahkan';
        navIndex = 3;
        moduleName = 'Jadwal Kuliah';
        break;
      case 'add_agenda_event':
        icon = Icons.event_available_rounded;
        iconColor = const Color(0xFF3B82F6);
        actionTitle = 'Agenda Ditambahkan';
        navIndex = 1;
        moduleName = 'Tasks & Agenda';
        break;
      case 'create_task':
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF6366F1);
        actionTitle = 'Tugas Baru Dibuat';
        navIndex = 1;
        moduleName = 'Tasks & Agenda';
        break;
      case 'add_finance':
      case 'add_income':
      case 'add_expense':
        final isIncome =
            result.action == 'add_income' ||
            (result.data['type']?.toString().toLowerCase() == 'income');
        icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;
        iconColor = isIncome
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);
        actionTitle = isIncome ? 'Pemasukan Dicatat' : 'Pengeluaran Dicatat';
        navIndex = 6;
        moduleName = 'Finance';
        break;
      case 'create_note':
        icon = Icons.note_alt_rounded;
        iconColor = const Color(0xFFF59E0B);
        actionTitle = 'Catatan Disimpan';
        navIndex = 5;
        moduleName = 'Knowledge Base';
        break;
      case 'create_habit':
        icon = Icons.track_changes_rounded;
        iconColor = const Color(0xFF8B5CF6);
        actionTitle = 'Habit Ditambahkan';
        navIndex = 7;
        moduleName = 'Habit Tracker';
        break;
      default:
        icon = Icons.auto_awesome;
        iconColor = green;
        actionTitle = 'Aksi Berhasil Dieksekusi';
        navIndex = 0;
        moduleName = 'Overview';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2721) : const Color(0xFFF4FAF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  actionTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: isDark ? Colors.white : ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'Tercatat',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.actionDescription != null &&
              result.actionDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF24312A) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: muted.withValues(alpha: 0.15)),
              ),
              child: Text(
                result.actionDescription!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(navIndex);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka di $moduleName',
                      style: const TextStyle(
                        fontSize: 11,
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: green,
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

  Widget _formatMarkdownText(String text, bool isDark) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 4);

        var content = line;
        var isBullet = false;
        if (content.startsWith('• ') ||
            content.startsWith('- ') ||
            content.startsWith('* ')) {
          isBullet = true;
          content = content.substring(2);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBullet)
                const Padding(
                  padding: EdgeInsets.only(right: 6, top: 4),
                  child: Icon(Icons.circle, size: 4.5, color: green),
                ),
              Expanded(child: _buildRichTextWithBold(content, isDark)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRichTextWithBold(String text, bool isDark) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white : ink,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: isDark ? Colors.white : ink,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.white : ink,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
