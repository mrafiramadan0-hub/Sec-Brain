import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class AIService {
  static const String defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Primary and waterfall fallback models in priority order
  static const List<String> _modelWaterfall = [
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  /// Helper to send request with automatic waterfall fallback across Gemini models
  static Future<http.Response> _postGemini({
    required String apiKey,
    required Map<String, dynamic> payload,
    http.Client? httpClient,
  }) async {
    if (apiKey.trim().isEmpty) {
      return http.Response(
        '{"error": "API key is not configured"}',
        400,
      );
    }

    final body = jsonEncode(payload);
    final headers = {'Content-Type': 'application/json'};

    http.Response? lastResponse;

    for (final model in _modelWaterfall) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final response = httpClient != null
            ? await httpClient.post(url, headers: headers, body: body)
            : await http.post(url, headers: headers, body: body);

        lastResponse = response;
        if (response.statusCode == 200) {
          return response;
        } else {
          debugPrint(
            'Gemini model ($model) returned HTTP ${response.statusCode}. Trying next fallback...',
          );
        }
      } catch (e) {
        debugPrint('Gemini model ($model) network error: $e');
      }
    }

    return lastResponse ??
        http.Response(
          '{"error": "All Gemini models are currently experiencing high demand"}',
          503,
        );
  }

  /// Summarize note with direct Gemini API call
  static Future<String> summarizeNote({
    required String title,
    required String body,
    String? apiKey,
    http.Client? httpClient,
  }) async {
    if (body.trim().isEmpty) {
      return 'Catatan ini belum memiliki isi untuk dirangkum.';
    }

    final key = apiKey?.trim().isNotEmpty == true
        ? apiKey!.trim()
        : defaultApiKey;

    try {
      final payload = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Rangkum catatan berikut secara singkat, profesional, dan poin-poin penting (termasuk Action Items jika ada):\n\nJudul: $title\nIsi: $body',
              },
            ],
          },
        ],
      };

      final response = await _postGemini(
        apiKey: key,
        payload: payload,
        httpClient: httpClient,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.toString().isNotEmpty) {
          return text.toString().trim();
        }
      }

      // Local intelligent summary fallback
      return _localSummarizeFallback(title, body);
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return _localSummarizeFallback(title, body);
    }
  }

  /// Analyze finances with direct Gemini API call + local financial rule fallback
  static Future<String> analyzeFinances({
    required List<TransactionItem> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    String? apiKey,
    http.Client? httpClient,
  }) async {
    if (transactions.isEmpty) {
      return 'Belum ada transaksi tercatat untuk dianalisis oleh AI. Tambahkan pengeluaran atau pemasukan pertama Anda!';
    }

    final key = apiKey?.trim().isNotEmpty == true
        ? apiKey!.trim()
        : defaultApiKey;

    try {
      final txListText = transactions
          .take(15)
          .map(
            (t) =>
                '${t.income ? "+" : "-"} Rp ${t.amount.round()} (${t.category}: ${t.title})',
          )
          .join(', ');

      final payload = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Analisis data keuangan personal/mahasiswa berikut dalam bahasa Indonesia dan berikan 3 saran penghematan atau alokasi budget konkret:\nTotal Pemasukan: Rp $totalIncome, Total Pengeluaran: Rp $totalExpense, Saldo Saat Ini: Rp $balance. Riwayat Transaksi: $txListText',
              },
            ],
          },
        ],
      };

      final response = await _postGemini(
        apiKey: key,
        payload: payload,
        httpClient: httpClient,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.toString().isNotEmpty) {
          return text.toString().trim();
        }
      }

      // Local intelligent financial insights fallback
      return _localFinanceFallback(
        totalIncome,
        totalExpense,
        balance,
        transactions,
      );
    } catch (e) {
      debugPrint('Gemini API Financial Analysis Error: $e');
      return _localFinanceFallback(
        totalIncome,
        totalExpense,
        balance,
        transactions,
      );
    }
  }

  /// Real-time chat & smart action execution directly via Google Gemini API
  static Future<AiActionResult> processAssistantMessage({
    required String userMessage,
    required BrainStore store,
    List<Map<String, String>> history = const [],
    String? apiKey,
    http.Client? httpClient,
  }) async {
    final cleanInput = userMessage.trim();
    if (cleanInput.isEmpty) {
      return AiActionResult(
        reply: 'Halo! Tuliskan apa yang ingin Anda tanyakan atau catat.',
        action: 'chat',
      );
    }

    final key = apiKey?.trim().isNotEmpty == true
        ? apiKey!.trim()
        : (store.geminiApiKey.trim().isNotEmpty
              ? store.geminiApiKey.trim()
              : defaultApiKey);

    final now = DateTime.now();
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final currentDay = days[(now.weekday - 1) % 7];
    final currentDateStr =
        '$currentDay, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final systemInstructionText =
        '''
Anda adalah SecBrain AI Assistant, asisten cerdas untuk produktivitas, manajemen jadwal kuliah, to-do list, agenda kegiatan, catatan, dan keuangan pribadi.
Waktu lokal saat ini: $currentDateStr.
Nama pengguna: ${store.userName.isNotEmpty ? store.userName : "Pengguna"}.

ATURAN UTAMA & FORMAT OUTPUT:
Anda HARUS SELALU merespons dalam format raw JSON murni yang valid tanpa markdown triple backticks (tanpa ```json atau ```) dan tanpa teks pengantar tambahan apapun.

Struktur JSON yang WAJIB digunakan:
{
  "action": "add_todo" | "add_finance" | "add_agenda_event" | "add_course_schedule" | "create_note" | "create_task" | "create_habit" | "chat",
  "data": {
    "title": "deskripsi to-do / kegiatan / transaksi / catatan / tugas",
    "timeframe": "today" | "thisWeek" | "thisMonth" | "thisYear",
    "amount": 500000,
    "type": "expense" | "income",
    "category": "Kuliah / Kerja / Pribadi / Target / Umum",
    "time": "HH:mm",
    "day": "Senin/Selasa/Rabu/Kamis/Jumat/Sabtu/Minggu",
    "date": "YYYY-MM-DD atau besok/lusa",
    "location": "nama tempat atau ruangan",
    "room": "nama ruangan (khusus kuliah)",
    "lecturer": "nama dosen (khusus kuliah)",
    "sks": 3,
    "content": "isi lengkap catatan atau detail",
    "priority": "High | Medium | Low"
  },
  "reply": "Kalimat konfirmasi santai, ramah, dan jelas ke pengguna dalam Bahasa Indonesia"
}

PANDUAN KLASIFIKASI AKSI (SANGAT PENTING):
1. "add_todo":
   - Jika pengguna meminta membuat to-do list, checklist centang, atau target rentang waktu (contoh: "tambahkan to-do beli susu hari ini", "to-do selesaikan skripsi tahun ini", "checklist olahraga minggu ini", "target evaluasi portofolio bulan ini", "buat to-do belajar flutter").
   - Isi "title", "timeframe" ("today" / "thisWeek" / "thisMonth" / "thisYear"), dan "category" ("Kuliah" / "Kerja" / "Pribadi" / "Target" / "Umum").

2. "add_finance":
   - Jika pengguna menyebut transaksi uang (beli barang, pengeluaran makan, terima beasiswa, gajian, transfer uang, topup saldo, bayar kos, dsb).
   - Isi "amount" dengan nominal angka (contoh: 500000).
   - Isi "type" dengan "income" (jika pemasukan/terima uang) atau "expense" (jika pengeluaran/beli/bayar).
   - Isi "category" sesuai jenis transaksi (contoh: "Beasiswa", "Makan & Minum", "Belanja", "Transportasi", "Pendidikan", "Tagihan", dll).

3. "add_agenda_event":
   - Jika pengguna menyebut agenda umum, rapat organisasi/kepanitiaan, janji temu, kegiatan harian, atau rutinitas terjadwal (contoh: "besok rapat jam 19.00 di CC", "hari senin mengambil laundry jam 7 pagi di laundry hernes", "nanti malam jam 20:00 kumpul tim").
   - Isi "title", "time" (format HH:mm), "day"/"date", dan "location".

4. "add_course_schedule":
   - HANYA jika pengguna secara spesifik menyebut jadwal kuliah akademis, mata kuliah, dosen pengampu, praktikum laboratorium perkuliahan, atau SKS.
   - Contoh: "Jadwal kuliah Termodinamika hari Senin jam 08.00 di Lab", "Kuliah Jaringan Komputer dosen Pak Budi jam 10.00".

5. "create_note":
   - Jika pengguna ingin mencatat ide, rangkuman, notulensi rapat, atau materi penting.
   - Isi "title" dan "content".

6. "create_task":
   - Jika pengguna meminta membuat tugas akademis / deadline besar dengan batas waktu spesifik (misal: "tugas resume jurnal deadline jumat").
   - Isi "title", "priority", dan "category".

7. "create_habit":
   - Jika pengguna ingin menambahkan kebiasaan/rutinitas baru untuk dipantau.

8. "chat":
   - Jika pengguna hanya menyapa, menanyakan tips, bertanya tentang saldo keuangan, atau obrolan santai.

Pastikan hanya mengembalikan JSON murni!
''';

    try {
      final contents = <Map<String, dynamic>>[];

      // Add conversation history
      for (final item in history.take(8)) {
        contents.add({
          'role': item['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': item['text'] ?? ''},
          ],
        });
      }

      // Add current user message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': cleanInput},
        ],
      });

      final payload = {
        'system_instruction': {
          'parts': [
            {'text': systemInstructionText},
          ],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      };

      final response = await _postGemini(
        apiKey: key,
        payload: payload,
        httpClient: httpClient,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final rawText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (rawText != null && rawText.toString().trim().isNotEmpty) {
          return _parseJsonResponse(rawText.toString().trim());
        }
      }

      // Cloud API returned non-200 (e.g. 503 high demand / 429 rate limit / 404).
      // Seamlessly fallback to offline/local smart intent parser so action ALWAYS executes!
      debugPrint(
        'Gemini API returned status ${response.statusCode}. Executing Local Smart Intent Parser...',
      );
      return _localFallbackParser(cleanInput, store);
    } catch (e) {
      debugPrint(
        'Gemini Assistant Error: $e. Executing Local Smart Intent Parser...',
      );
      return _localFallbackParser(cleanInput, store);
    }
  }

  /// Intelligent local parser that executes smart tool actions when Cloud AI is unavailable (503/429/offline)
  static AiActionResult _localFallbackParser(String input, BrainStore store) {
    final text = input.trim();
    final lower = text.toLowerCase();

    // 1. Check Course Schedule (Jadwal Kuliah akademis)
    final isCourse =
        lower.contains('kuliah') ||
        lower.contains('matkul') ||
        lower.contains('mata kuliah') ||
        lower.contains('praktikum') ||
        lower.contains('dosen');
    if (isCourse) {
      String courseName = text;
      courseName = courseName
          .replaceAll(
            RegExp(
              r'jadwal\s+kuliah\s*:?|mata\s+kuliah\s*:?|matkul\s*:?',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      final day = _extractDay(lower);
      final time = _extractTime(lower, defaultTime: '08:00');
      final room = _extractLocation(text, defaultVal: 'Ruang Kuliah');

      final title = courseName.isNotEmpty ? courseName : 'Mata Kuliah';
      final reply =
          'Siap! Jadwal kuliah "$title" ($day jam $time di $room) berhasil dicatat ke Jadwal Kuliah.';

      return AiActionResult(
        action: 'add_course_schedule',
        reply: reply,
        actionData: {
          'action': 'add_course_schedule',
          'data': {
            'title': title,
            'day': day,
            'startTime': time,
            'endTime': _addDurationToTime(time, 100),
            'room': room,
            'lecturer': 'Dosen Pengampu',
            'sks': 3,
          },
          'reply': reply,
        },
      );
    }

    // 2. Check To-Do List & Checklist
    final isTodo =
        lower.startsWith('todo') ||
        lower.startsWith('to-do') ||
        lower.contains('to-do') ||
        lower.contains('todo') ||
        lower.contains('checklist') ||
        lower.contains('centang') ||
        (lower.contains('target') && !lower.contains('tabungan'));
    if (isTodo) {
      String timeframe = 'today';
      String timeframeLabel = 'Hari Ini';
      if (lower.contains('minggu') ||
          lower.contains('pekan') ||
          lower.contains('week')) {
        timeframe = 'thisWeek';
        timeframeLabel = 'Minggu Ini';
      } else if (lower.contains('bulan') || lower.contains('month')) {
        timeframe = 'thisMonth';
        timeframeLabel = 'Bulan Ini';
      } else if (lower.contains('tahun') ||
          lower.contains('year') ||
          lower.contains('resolusi')) {
        timeframe = 'thisYear';
        timeframeLabel = 'Tahun Ini';
      }

      String category = 'Umum';
      if (lower.contains('kuliah') ||
          lower.contains('kampus') ||
          lower.contains('skripsi')) {
        category = 'Kuliah';
      } else if (lower.contains('kerja') ||
          lower.contains('kantor') ||
          lower.contains('proyek')) {
        category = 'Kerja';
      } else if (lower.contains('pribadi') ||
          lower.contains('belanja') ||
          lower.contains('makan') ||
          lower.contains('minum') ||
          lower.contains('olahraga')) {
        category = 'Pribadi';
      } else if (lower.contains('target') ||
          lower.contains('skill') ||
          lower.contains('belajar')) {
        category = 'Target';
      }

      var todoTitle = text
          .replaceAll(
            RegExp(
              r'^(tambahkan\s+|tambah\s+|buat\s+|masukkan\s+)?(to-?do|checklist|centang|target)\s*(list)?\s*:?\s*',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r'\b(hari\s+ini|minggu\s+ini|bulan\s+ini|tahun\s+ini|pekan\s+ini|untuk\s+hari\s+ini|untuk\s+minggu\s+ini|untuk\s+bulan\s+ini|untuk\s+tahun\s+ini)\b',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      if (todoTitle.isEmpty) todoTitle = text;

      final reply =
          'Siap! To-Do "$todoTitle" untuk $timeframeLabel berhasil ditambahkan ke To-Do List.';

      return AiActionResult(
        action: 'add_todo',
        reply: reply,
        actionData: {
          'action': 'add_todo',
          'data': {
            'title': todoTitle,
            'timeframe': timeframe,
            'category': category,
          },
          'reply': reply,
        },
      );
    }

    // 3. Check Tasks & Deadlines (PRIORITY OVER FINANCE & AGENDA)
    final isTask =
        lower.startsWith('tugas') ||
        lower.contains('deadline') ||
        lower.contains('pr ') ||
        lower.startsWith('pr') ||
        lower.contains('submit') ||
        lower.contains('kumpul') ||
        lower.contains('resume') ||
        lower.contains('jurnal');
    if (isTask) {
      final time = _extractTime(lower, defaultTime: '17:00');
      final date = lower.contains('besok')
          ? 'besok'
          : (lower.contains('lusa') ? 'lusa' : _extractDay(lower));
      var taskTitle = text
          .replaceAll(
            RegExp(
              r'besok|lusa|jam\s*\d+([\.:]\d+)?(\s*(pagi|siang|sore|malam))?|\b\d{1,2}[\.:]\d{2}\b|^tugas\s*:?',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      if (taskTitle.isEmpty) taskTitle = text;

      final reply =
          'Siap! Tugas "$taskTitle" (Tenggat: $date jam $time) berhasil ditambahkan ke Tasks & Agenda.';

      return AiActionResult(
        action: 'create_task',
        reply: reply,
        actionData: {
          'action': 'create_task',
          'data': {
            'title': taskTitle,
            'due_date': date,
            'due_time': time,
            'priority': 'Medium',
            'category': 'University',
          },
          'reply': reply,
        },
      );
    }

    // 3. Check General Agenda / Event (Rapat, Janji Temu, Laundry, dll)
    final isAgenda =
        lower.contains('rapat') ||
        lower.contains('meeting') ||
        lower.contains('pertemuan') ||
        lower.contains('kumpul') ||
        lower.contains('laundry') ||
        lower.contains('janji') ||
        lower.contains('acara') ||
        lower.contains('webinar') ||
        ((lower.contains('jam ') || lower.contains('pukul ')) &&
            !lower.contains('beli') &&
            !lower.contains('bayar') &&
            !lower.contains('terima'));
    if (isAgenda) {
      final time = _extractTime(lower, defaultTime: '19:00');
      final day = _extractDay(lower);
      final date = lower.contains('besok')
          ? 'besok'
          : (lower.contains('lusa') ? 'lusa' : day);
      final location = _extractLocation(text);
      String title = text;
      title = title
          .replaceAll(
            RegExp(
              r'besok|lusa|jam\s*\d+([\.:]\d+)?(\s*(pagi|siang|sore|malam))?|di\s+[^,\.]+|hari\s+[a-z]+|\b\d{1,2}[\.:]\d{2}\b',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      if (title.isEmpty) title = 'Agenda';

      final locText = location.isNotEmpty ? ' di $location' : '';
      final reply =
          'Siap! Agenda "$title"$locText ($date jam $time) berhasil dicatat ke Tasks & Agenda.';

      return AiActionResult(
        action: 'add_agenda_event',
        reply: reply,
        actionData: {
          'action': 'add_agenda_event',
          'data': {
            'title': title,
            'time': time,
            'date': date,
            'day': day,
            'location': location,
          },
          'reply': reply,
        },
      );
    }

    // 4. Check Finance (Pemasukan / Pengeluaran - HANYA jika ada transaksi uang eksplisit)
    final amount = _extractAmount(lower);
    if (amount > 0) {
      final isIncome =
          lower.contains('terima') ||
          lower.contains('pemasukan') ||
          lower.contains('gaji') ||
          lower.contains('beasiswa') ||
          lower.contains('dapat uang') ||
          lower.contains('cair') ||
          lower.contains('masuk');

      String category = 'Lainnya';
      if (lower.contains('beasiswa')) {
        category = 'Beasiswa';
      } else if (lower.contains('kopi') ||
          lower.contains('makan') ||
          lower.contains('minum') ||
          lower.contains('sarapan') ||
          lower.contains('nasi') ||
          lower.contains('cafe')) {
        category = 'Makanan & Minuman';
      } else if (lower.contains('gaji') ||
          lower.contains('fee') ||
          lower.contains('upah') ||
          lower.contains('proyek')) {
        category = 'Gaji';
      } else if (lower.contains('bensin') ||
          lower.contains('ojol') ||
          lower.contains('gojek') ||
          lower.contains('grab') ||
          lower.contains('transport')) {
        category = 'Transportasi';
      } else if (lower.contains('kos') ||
          lower.contains('listrik') ||
          lower.contains('wifi') ||
          lower.contains('air') ||
          lower.contains('tagihan')) {
        category = 'Tagihan';
      } else if (lower.contains('belanja') ||
          lower.contains('baju') ||
          lower.contains('beli')) {
        category = 'Belanja';
      } else if (isIncome) {
        category = 'Pemasukan';
      }

      final typeStr = isIncome ? 'income' : 'expense';
      final formattedMoney = money(amount);
      final reply = isIncome
          ? 'Siap! Pemasukan $category sebesar $formattedMoney berhasil dicatat ke Finance.'
          : 'Siap! Pengeluaran $category sebesar $formattedMoney berhasil dicatat ke Finance.';

      return AiActionResult(
        action: 'add_finance',
        reply: reply,
        actionData: {
          'action': 'add_finance',
          'data': {
            'title': text,
            'amount': amount,
            'type': typeStr,
            'category': category,
          },
          'reply': reply,
        },
      );
    }

    // 5. Check Notes
    if (lower.startsWith('catat') ||
        lower.startsWith('tulis') ||
        lower.contains('catatan') ||
        lower.contains('ide')) {
      var noteContent = text
          .replaceAll(
            RegExp(
              r'^catat\s*(?:ide|catatan)?\s*:?|^tulis\s*(?:catatan)?\s*:?',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      if (noteContent.isEmpty) noteContent = text;
      final noteTitle = noteContent.split('\n').first;
      final shortTitle = noteTitle.length > 35
          ? '${noteTitle.substring(0, 35)}...'
          : noteTitle;
      final reply =
          'Catatan "$shortTitle" berhasil disimpan ke Knowledge Base.';

      return AiActionResult(
        action: 'create_note',
        reply: reply,
        actionData: {
          'action': 'create_note',
          'data': {'title': shortTitle, 'content': noteContent, 'type': 'Idea'},
          'reply': reply,
        },
      );
    }

    // 6. Check Habit
    if (lower.contains('habit') || lower.contains('kebiasaan')) {
      final habitTitle = text
          .replaceAll(
            RegExp(r'tambah\s*habit\s*:?|habit\s*:?', caseSensitive: false),
            '',
          )
          .trim();
      final reply =
          'Habit "$habitTitle" berhasil ditambahkan ke Habit Tracker.';

      return AiActionResult(
        action: 'create_habit',
        reply: reply,
        actionData: {
          'action': 'create_habit',
          'data': {
            'title': habitTitle.isNotEmpty ? habitTitle : text,
            'category': 'Produktivitas',
          },
          'reply': reply,
        },
      );
    }

    // Default friendly chat
    return AiActionResult(
      action: 'chat',
      reply: 'Halo! Saya SecBrain Assistant. Anda dapat meminta saya mencatat pengeluaran ("beli kopi 25rb"), pemasukan ("terima beasiswa 6000000"), agenda ("rapat besok jam 9 malam"), tugas ("tugas MK Profesi jam 17.00 besok"), atau jadwal kuliah.',
    );
  }

  /// Extracts financial transaction amount.
  /// Strictly ignores time references (e.g. "jam 17.00", "jam 9 malam", "pukul 10.00").
  static double _extractAmount(String inputLower) {
    // Check if input has explicit finance intent:
    final hasFinanceKeyword =
        inputLower.contains('beli') ||
        inputLower.contains('bayar') ||
        inputLower.contains('transfer') ||
        inputLower.contains('terima') ||
        inputLower.contains('gaji') ||
        inputLower.contains('beasiswa') ||
        inputLower.contains('uang') ||
        inputLower.contains('topup') ||
        inputLower.contains('top up') ||
        inputLower.contains('saldo') ||
        inputLower.contains('biaya') ||
        inputLower.contains('ongkir') ||
        inputLower.contains('jajan') ||
        inputLower.contains('belanja') ||
        inputLower.contains('pengeluaran') ||
        inputLower.contains('pemasukan') ||
        inputLower.contains('rp') ||
        inputLower.contains('idr') ||
        inputLower.contains('rb') ||
        inputLower.contains('ribu') ||
        inputLower.contains('jt') ||
        inputLower.contains('juta') ||
        inputLower.contains('k');

    if (!hasFinanceKeyword) {
      return 0.0;
    }

    // Strip time phrases so "jam 17.00", "jam 9 malam", "pukul 08.00" are not parsed as money
    final clean = inputLower
        .replaceAll(
          RegExp(
            r'jam\s*\d{1,2}(?:[\.:]\d{2})?\s*(pagi|siang|sore|malam)?',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'pukul\s*\d{1,2}(?:[\.:]\d{2})?\s*(pagi|siang|sore|malam)?',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(r'\b\d{1,2}[\.:]\d{2}\b', caseSensitive: false),
          ' ',
        );

    // 1. Matches with currency unit suffix (e.g. 25rb, 50 ribu, 6jt, 1.5jt, 500k)
    final unitMatch = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(jt|juta|rb|ribu|k)\b',
      caseSensitive: false,
    ).firstMatch(clean);
    if (unitMatch != null) {
      final numPart =
          double.tryParse(unitMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
      final unit = unitMatch.group(2)!.toLowerCase();
      if (unit.startsWith('j')) {
        return numPart * 1000000;
      } else {
        return numPart * 1000;
      }
    }

    // 2. Matches explicit Rp prefix (e.g. Rp 25.000, Rp25000, Rp 6.000.000)
    final rpMatch = RegExp(
      r'(?:rp\.?\s*|idr\s*)(\d{1,3}(?:[\.,]\d{3})+|\d+)',
      caseSensitive: false,
    ).firstMatch(clean);
    if (rpMatch != null) {
      final rawStr = rpMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
      final val = double.tryParse(rawStr) ?? 0.0;
      if (val > 0) return val;
    }

    // 3. Matches standalone number only if preceded/followed by finance words
    final hasStrongFinanceWord =
        clean.contains('beli') ||
        clean.contains('bayar') ||
        clean.contains('terima') ||
        clean.contains('gaji') ||
        clean.contains('beasiswa') ||
        clean.contains('transfer') ||
        clean.contains('uang') ||
        clean.contains('biaya') ||
        clean.contains('saldo');

    if (hasStrongFinanceWord) {
      final numMatch = RegExp(
        r'\b(\d{1,3}(?:[\.,]\d{3})+|\d{4,})\b',
        caseSensitive: false,
      ).firstMatch(clean);
      if (numMatch != null) {
        final rawStr = numMatch
            .group(1)!
            .replaceAll('.', '')
            .replaceAll(',', '');
        final val = double.tryParse(rawStr) ?? 0.0;
        if (val > 0) return val;
      }
    }

    return 0.0;
  }

  /// Extracts time e.g. 19:00, jam 7 malam -> 19:00, jam 7 pagi -> 07:00
  static String _extractTime(String lower, {String defaultTime = '19:00'}) {
    // Check "jam 7 malam", "jam 8 pagi", etc.
    final jamWaktu = RegExp(
      r'jam\s*(\d{1,2})(?:[\.:](\d{2}))?\s*(pagi|siang|sore|malam)?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (jamWaktu != null) {
      int hour = int.tryParse(jamWaktu.group(1)!) ?? 19;
      final minStr = jamWaktu.group(2) ?? '00';
      final period = jamWaktu.group(3)?.toLowerCase() ?? '';

      if ((period == 'malam' || period == 'sore') && hour < 12) {
        hour += 12;
      } else if (period == 'pagi' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:$minStr';
    }

    final rawTime = RegExp(r'\b(\d{1,2})[\.:](\d{2})\b').firstMatch(lower);
    if (rawTime != null) {
      final h = rawTime.group(1)!.padLeft(2, '0');
      final m = rawTime.group(2)!;
      return '$h:$m';
    }

    return defaultTime;
  }

  /// Extracts day name from text
  static String _extractDay(String lower) {
    if (lower.contains('senin')) return 'Senin';
    if (lower.contains('selasa')) return 'Selasa';
    if (lower.contains('rabu')) return 'Rabu';
    if (lower.contains('kamis')) return 'Kamis';
    if (lower.contains('jumat')) return 'Jumat';
    if (lower.contains('sabtu')) return 'Sabtu';
    if (lower.contains('minggu')) return 'Minggu';
    return 'Senin';
  }

  /// Extracts location e.g. "di CC", "di Laundry Hernes"
  static String _extractLocation(String text, {String defaultVal = ''}) {
    final match = RegExp(
      r'\bdi\s+([^,\.\n]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final loc = match.group(1)!.trim();
      return loc;
    }
    return defaultVal;
  }

  /// Adds minutes to time string HH:mm
  static String _addDurationToTime(String time, int minutesToAdd) {
    final parts = time.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 8;
      final m = int.tryParse(parts[1]) ?? 0;
      final totalM = h * 60 + m + minutesToAdd;
      final newH = (totalM ~/ 60) % 24;
      final newM = totalM % 60;
      return '${newH.toString().padLeft(2, '0')}:${newM.toString().padLeft(2, '0')}';
    }
    return '09:40';
  }

  /// Local bullet summary fallback for notes
  static String _localSummarizeFallback(String title, String body) {
    final lines = body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final buffer = StringBuffer();
    buffer.writeln('**Ringkasan Catatan: $title**\n');
    for (int i = 0; i < lines.length && i < 4; i++) {
      buffer.writeln('• ${lines[i]}');
    }
    buffer.writeln('\n*💡 Catatan tersimpan di Knowledge Base.*');
    return buffer.toString();
  }

  /// Local finance insights fallback
  static String _localFinanceFallback(
    double income,
    double expense,
    double balance,
    List<TransactionItem> transactions,
  ) {
    final savingsRatio = income > 0
        ? ((income - expense) / income * 100).round()
        : 0;
    return '''
📊 **Analisis Keuangan Cerdas SecBrain**

• **Total Pemasukan**: Rp ${income.round()}
• **Total Pengeluaran**: Rp ${expense.round()}
• **Sisa Saldo**: Rp ${balance.round()}
• **Tingkat Tabungan (Savings Rate)**: $savingsRatio%

💡 **3 Saran Penghematan Konkret**:
1. Terapkan alokasi anggaran 50/30/20 (50% Kebutuhan, 30% Keinginan, 20% Tabungan/Investasi).
2. Prioritaskan pelunasan tagihan rutin sebelum mengalokasikan untuk pengeluaran sekunder.
3. Tetapkan batas harian untuk pos jajan/makan di luar agar saldo tetap terjaga.
''';
  }

  /// Parses JSON response from Gemini API safely
  static AiActionResult _parseJsonResponse(String rawText) {
    try {
      var cleaned = rawText.trim();
      // Remove markdown ```json codeblocks if present
      if (cleaned.startsWith('```')) {
        final lines = cleaned.split('\n');
        if (lines.first.startsWith('```')) lines.removeAt(0);
        if (lines.isNotEmpty && lines.last.trim() == '```') lines.removeLast();
        cleaned = lines.join('\n').trim();
      }

      // Try finding json substring if there are surrounding characters
      final startIdx = cleaned.indexOf('{');
      final endIdx = cleaned.lastIndexOf('}');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        cleaned = cleaned.substring(startIdx, endIdx + 1);
      }

      final Map<String, dynamic> json = jsonDecode(cleaned);
      final action = json['action']?.toString().toLowerCase() ?? 'chat';
      final reply =
          json['reply']?.toString() ?? 'Permintaan Anda telah diproses.';

      return AiActionResult(
        action: action,
        reply: reply,
        actionData: json,
        rawResponse: rawText,
      );
    } catch (e) {
      debugPrint('JSON Parse Error: $e on raw response: $rawText');
      // If parsing fails, return as plain chat reply
      return AiActionResult(
        action: 'chat',
        reply: rawText.replaceAll(RegExp(r'^```(?:json)?\s*|\s*```$'), ''),
        rawResponse: rawText,
      );
    }
  }
}

class AiActionResult {
  AiActionResult({
    required this.reply,
    this.action = 'chat',
    this.actionData,
    this.executed = false,
    this.actionDescription,
    this.rawResponse,
  });

  final String reply;
  final String action;
  final Map<String, dynamic>? actionData;
  bool executed;
  String? actionDescription;
  final String? rawResponse;

  /// Helper to get the data map safely whether flat or nested under 'data'
  Map<String, dynamic> get data {
    if (actionData == null) return {};
    if (actionData!['data'] is Map<String, dynamic>) {
      return actionData!['data'] as Map<String, dynamic>;
    }
    return actionData!;
  }
}
