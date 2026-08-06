// PERF-BASELINE: opt-in profile/release device benchmark. It only opens an
// isolated SQLCipher fixture and never changes app startup or user data.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../helpers/device_test_crypto.dart';
import 'performance_metrics.dart';

const _datasetSize = int.fromEnvironment(
  'PERF_DATASET_SIZE',
  defaultValue: 1000,
);
final _frameBudgetMs = double.parse(
  const String.fromEnvironment('PERF_FRAME_BUDGET_MS', defaultValue: '16.67'),
);
const _repetitions = int.fromEnvironment('PERF_REPETITIONS', defaultValue: 12);
const _deviceLabel = String.fromEnvironment('PERF_DEVICE_LABEL');
const _buildMode = String.fromEnvironment('PERF_BUILD_MODE');

class _Recorder {
  final Map<String, List<double>> samples = {};

  void add(String metric, num milliseconds) {
    samples.putIfAbsent(metric, () => []).add(milliseconds.toDouble());
  }

  Future<T> time<T>(String metric, Future<T> Function() operation) async {
    final watch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      watch.stop();
      add(
        metric,
        watch.elapsedMicroseconds / Duration.microsecondsPerMillisecond,
      );
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('emits reproducible performance measurements', (tester) async {
    if (!const {1000, 10000, 50000}.contains(_datasetSize)) {
      throw ArgumentError('PERF_DATASET_SIZE must be 1000, 10000, or 50000');
    }
    if (_repetitions < 3) {
      throw ArgumentError('PERF_REPETITIONS must be at least 3');
    }

    final recorder = _Recorder();
    var totalFrames = 0;
    var jankFrames = 0;
    void frameCallback(List<FrameTiming> timings) {
      for (final timing in timings) {
        totalFrames++;
        final buildMs =
            timing.buildDuration.inMicroseconds /
            Duration.microsecondsPerMillisecond;
        final rasterMs =
            timing.rasterDuration.inMicroseconds /
            Duration.microsecondsPerMillisecond;
        recorder
          ..add('frame.build_ms', buildMs)
          ..add('frame.raster_ms', rasterMs)
          ..add('frame.total_ms', buildMs + rasterMs);
        if (buildMs + rasterMs > _frameBudgetMs) {
          jankFrames++;
        }
      }
    }

    SchedulerBinding.instance.addTimingsCallback(frameCallback);

    final root = Directory(
      '${(await getTemporaryDirectory()).path}/home-pocket-performance-'
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    final databaseFile = File('${root.path}/performance.db');
    await root.create(recursive: true);
    final keys = DeviceTestMasterKeyRepository();
    final database = AppDatabase(
      await createDeviceTestEncryptedExecutor(keys, databaseFile),
    );
    try {
      final now = DateTime.now().toUtc();
      const bookCount = 5;
      await database.batch((batch) {
        for (var book = 0; book < bookCount; book++) {
          batch.insert(
            database.books,
            BooksCompanion.insert(
              id: 'perf-book-$book',
              name: 'Performance book $book',
              currency: 'JPY',
              deviceId: 'performance-device',
              createdAt: now,
            ),
          );
        }
        for (var index = 0; index < _datasetSize; index++) {
          final book = index % bookCount;
          batch.insert(
            database.transactions,
            TransactionsCompanion.insert(
              id: 'perf-tx-$index',
              bookId: 'perf-book-$book',
              deviceId: 'performance-device',
              amount: 1000 + index,
              type: 'expense',
              categoryId: 'performance-category',
              ledgerType: 'daily',
              timestamp: now.subtract(Duration(minutes: index)),
              currentHash: 'hash-$index',
              createdAt: now.subtract(Duration(minutes: index)),
              entrySource: const Value('manual'),
            ),
          );
        }
      });

      for (var iteration = 0; iteration < _repetitions; iteration++) {
        await recorder.time('sqlcipher.query_page_ms', () {
          return (database.select(database.transactions)
                ..where(
                  (row) =>
                      row.bookId.equals('perf-book-${iteration % bookCount}'),
                )
                ..orderBy([(row) => OrderingTerm.desc(row.timestamp)])
                ..limit(100))
              .get();
        });
        await recorder.time('sqlcipher.write_transaction_ms', () {
          return database
              .into(database.transactions)
              .insert(
                TransactionsCompanion.insert(
                  id: 'perf-write-$iteration',
                  bookId: 'perf-book-0',
                  deviceId: 'performance-device',
                  amount: iteration + 1,
                  type: 'expense',
                  categoryId: 'performance-category',
                  ledgerType: 'daily',
                  timestamp: now.add(Duration(seconds: iteration)),
                  currentHash: 'write-hash-$iteration',
                  createdAt: now.add(Duration(seconds: iteration)),
                  entrySource: const Value('manual'),
                ),
              );
        });
      }

      // Export-shaped materialization only; no backup file or restore is run.
      await recorder.time('backup.multibook_materialize_json_ms', () async {
        final books = await database.select(database.books).get();
        final rows = await database.select(database.transactions).get();
        jsonEncode({
          'books': books.map((book) => book.id).toList(),
          'transactions': rows
              .map(
                (row) => {
                  'id': row.id,
                  'book_id': row.bookId,
                  'amount': row.amount,
                },
              )
              .toList(),
        });
      });

      final perMessageBytes =
          (2 * 1024 * 1024 ~/ RelayPullResponse.maxMessagesPerPage);
      final nearLimitPage = <String, Object>{
        'hasMore': false,
        'messages': List.generate(
          RelayPullResponse.maxMessagesPerPage,
          (index) => {
            'id': 'perf-relay-$index',
            'payload': 'a' * perMessageBytes,
          },
        ),
      };
      for (var iteration = 0; iteration < _repetitions; iteration++) {
        await recorder.time('relay.near_limit_page_parse_ms', () async {
          RelayPullResponse.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(jsonEncode(nearLimitPage)) as Map,
            ),
          );
        });
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 500,
              itemBuilder: (context, index) => ListTile(
                title: Text('Performance row $index'),
                subtitle: Text('Synthetic fixture ${index * 7}'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var index = 0; index < 8; index++) {
        await tester.drag(find.byType(ListView), const Offset(0, -520));
        await tester.pumpAndSettle();
      }
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(frameCallback);
      await database.close();
      if (await root.exists()) await root.delete(recursive: true);
    }

    final package = await PackageInfo.fromPlatform();
    final report = PerformanceReport(
      metadata: {
        'workload': 'home-pocket-performance-baseline',
        'device_label': _deviceLabel,
        'build_mode': _buildMode,
        'app_package': package.packageName,
        'app_version': package.version,
        'app_build_number': package.buildNumber,
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'cpu_count': Platform.numberOfProcessors,
        'dataset_transactions': _datasetSize,
        'dataset_books': 5,
        'repetitions': _repetitions,
        'frame_budget_ms': _frameBudgetMs,
        'rss_bytes_after_workload': ProcessInfo.currentRss,
        'gc_metrics': 'unavailable_without_vm_service',
        'startup_metrics': 'not_observable_from_in_process_integration_test',
        'measurement_scope':
            'isolated SQLCipher fixture; synthetic UI scroll; no user data',
        'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
      },
      samples: recorder.samples,
      counters: {'total_frames': totalFrames, 'jank_frames': jankFrames},
      observations: {
        'total_frames': totalFrames,
        'jank_frames': jankFrames,
        'jank_percent': totalFrames == 0 ? 0.0 : jankFrames * 100 / totalFrames,
        'frame_budget_ms': _frameBudgetMs,
      },
      notes: [
        'Backup workload measures materialization/JSON only, not destructive restore.',
        'Startup/TTI needs a separate launcher trace and must not be inferred from this test.',
      ],
    );
    binding.reportData = report.toJson();
    // ignore: avoid_print
    print('PERFORMANCE_RESULT_JSON=${jsonEncode(report.toJson())}');
  });
}
