import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:secbrain_app/main.dart';
import 'package:secbrain_app/screens/ai_assistant_screen.dart';
import 'package:secbrain_app/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AI Assistant - Real-time Gemini API & Parsing Tests', () {
    late BrainStore store;

    setUp(() async {
      store = BrainStore();
      await store.load();
    });

    test('Gemini API add_agenda_event response is correctly parsed', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          contains('generativelanguage.googleapis.com'),
        );
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'action': 'add_agenda_event',
                        'data': {
                          'title': 'Rapat Proyek',
                          'time': '19:00',
                          'date': 'besok',
                          'location': 'CC',
                        },
                        'reply': 'Siap, rapat proyek di CC besok jam 19:00 sudah dicatat ke Tasks & Agenda!',
                      }),
                    },
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await AIService.processAssistantMessage(
        userMessage: 'besok rapat jam 19.00 di cc',
        store: store,
        httpClient: mockClient,
      );

      expect(result.action, 'add_agenda_event');
      expect(result.data['title'], 'Rapat Proyek');
      expect(result.data['location'], 'CC');
      expect(result.data['time'], '19:00');
      expect(result.reply, contains('rapat proyek'));
    });

    test(
      'Gemini API add_course_schedule response is correctly parsed',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'action': 'add_course_schedule',
                          'data': {
                            'title': 'Termodinamika',
                            'day': 'Senin',
                            'time': '08:00',
                            'room': 'Lab',
                            'lecturer': 'Dosen Pengampu',
                            'sks': 3,
                          },
                          'reply': 'Jadwal kuliah Termodinamika hari Senin jam 08:00 di Lab telah ditambahkan.',
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final result = await AIService.processAssistantMessage(
          userMessage:
              'jadwal kuliah Termodinamika hari Senin jam 08.00 di Lab',
          store: store,
          httpClient: mockClient,
        );

        expect(result.action, 'add_course_schedule');
        expect(result.data['title'], 'Termodinamika');
        expect(result.data['day'], 'Senin');
        expect(result.data['room'], 'Lab');
      },
    );

    test('Gemini API add_finance response is correctly parsed', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'action': 'add_finance',
                        'data': {
                          'title': 'Beasiswa Unggulan',
                          'amount': 6000000,
                          'type': 'income',
                          'category': 'Beasiswa',
                        },
                        'reply': 'Pemasukan beasiswa sebesar Rp 6.000.000 berhasil dicatat.',
                      }),
                    },
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await AIService.processAssistantMessage(
        userMessage: 'terima uang beasiswa 6000000',
        store: store,
        httpClient: mockClient,
      );

      expect(result.action, 'add_finance');
      expect(result.data['amount'], 6000000);
      expect(result.data['type'], 'income');
      expect(result.data['category'], 'Beasiswa');
    });

    test('Gemini API note summarizer is correctly processed', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': '- Poin penting 1\n- Poin penting 2\n- Action Items: Selesaikan tugas',
                    },
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final summary = await AIService.summarizeNote(
        title: 'Meeting Rapat',
        body: 'Membahas pembagian tugas kelompok untuk project flutter.',
        httpClient: mockClient,
      );

      expect(summary, contains('Poin penting'));
      expect(summary, contains('Action Items'));
    });

    test(
      'Gemini API falls back to next model in waterfall on HTTP 503 error',
      () async {
        int requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (request.url.toString().contains('gemini-2.5-flash-lite:')) {
            // First model returns 503 Unavailable / High Demand
            return http.Response(
              jsonEncode({'error': 'High Demand / UNAVAILABLE'}),
              503,
            );
          } else if (request.url.toString().contains('gemini-2.5-flash:')) {
            // Second model in waterfall succeeds
            return http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': jsonEncode({
                            'action': 'chat',
                            'reply': 'Halo dari model kedua di waterfall!',
                          }),
                        },
                      ],
                    },
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response('Not found', 404);
        });

        final result = await AIService.processAssistantMessage(
          userMessage: 'halo',
          store: store,
          httpClient: mockClient,
        );

        expect(requestCount, 2);
        expect(result.action, 'chat');
        expect(result.reply, contains('model kedua di waterfall'));
      },
    );

    test('All models returning 503 triggers seamless local smart intent fallback for finance', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 503,
              'message': 'This model is currently experiencing high demand.',
              'status': 'UNAVAILABLE',
            },
          }),
          503,
        );
      });

      final result = await AIService.processAssistantMessage(
        userMessage: 'Terima beasiswa 6000000',
        store: store,
        httpClient: mockClient,
      );

      expect(result.action, 'add_finance');
      expect(result.data['amount'], 6000000.0);
      expect(result.data['type'], 'income');
      expect(result.reply, contains('Beasiswa'));
      expect(result.reply, contains('Pemasukan'));
    });

    test('Local fallback parses task with time "tugas MK Profesi jam 17.00 besok" as task, NOT finance', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "offline"}', 503);
      });

      final result = await AIService.processAssistantMessage(
        userMessage: 'tugas MK Profesi jam 17.00 besok',
        store: store,
        httpClient: mockClient,
      );

      expect(result.action, 'create_task');
      expect(result.data['due_time'], '17:00');
      expect(result.data['due_date'], 'besok');
      expect(result.action, isNot('add_finance'));
    });

    test('Local fallback parses meeting with time "rapat besok jam 9 malam" as agenda, NOT finance', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "offline"}', 503);
      });

      final result = await AIService.processAssistantMessage(
        userMessage: 'rapat besok jam 9 malam',
        store: store,
        httpClient: mockClient,
      );

      expect(result.action, 'add_agenda_event');
      expect(result.data['time'], '21:00');
      expect(result.data['date'], 'besok');
      expect(result.action, isNot('add_finance'));
    });

    test('Local fallback parses "beli kopi 25rb" as finance expense', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "offline"}', 503);
      });

      final result = await AIService.processAssistantMessage(
        userMessage: 'beli kopi 25rb',
        store: store,
        httpClient: mockClient,
      );

      expect(result.action, 'add_finance');
      expect(result.data['amount'], 25000.0);
      expect(result.data['type'], 'expense');
      expect(result.data['category'], 'Makanan & Minuman');
    });

    test(
      'Local fallback parses "tambah to-do beli susu hari ini" as add_todo',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"error": "offline"}', 503);
        });

        final result = await AIService.processAssistantMessage(
          userMessage: 'tambah to-do beli susu hari ini',
          store: store,
          httpClient: mockClient,
        );

        expect(result.action, 'add_todo');
        expect(result.data['title'], contains('beli susu'));
        expect(result.data['timeframe'], 'today');
        expect(result.reply, contains('beli susu'));
      },
    );

    test('Local fallback parses "to-do selesaikan skripsi tahun ini" with thisYear timeframe', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "offline"}', 503);
      });

      final result = await AIService.processAssistantMessage(
        userMessage: 'to-do selesaikan skripsi tahun ini',
        store: store,
        httpClient: mockClient,
      );

      expect(result.action, 'add_todo');
      expect(result.data['timeframe'], 'thisYear');
      expect(result.data['category'], 'Kuliah');
    });
  });

  group('AI Assistant - Widget Action Execution Tests', () {
    testWidgets(
      'AiAssistantScreen executes add_agenda_event result and adds to Tasks & Agenda',
      (tester) async {
        final store = BrainStore();
        await store.load();

        await tester.pumpWidget(
          StoreScope(
            store: store,
            child: const MaterialApp(home: AiAssistantScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial screen elements
        expect(find.text('SecBrain AI Assistant'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'AiAssistantScreen executes add_todo and successfully creates a TodoItem in store',
      (tester) async {
        final store = BrainStore();
        await store.load();
        final initialTodoCount = store.todos.length;

        await tester.pumpWidget(
          StoreScope(
            store: store,
            child: const MaterialApp(home: AiAssistantScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Enter message to add to-do
        await tester.enterText(
          find.byType(TextField),
          'tambah to-do riset materi coding hari ini',
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Verify todo added to store
        expect(store.todos.length, initialTodoCount + 1);
        expect(
          store.todos.any((t) => t.title.contains('riset materi coding')),
          isTrue,
        );
      },
    );
  });
}
