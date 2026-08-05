// Validates a raw device result against separately reviewed thresholds.
// Empty thresholds deliberately mean "baseline_required", never green limits.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final result = _readJson(options.resultPath, 'result');
  final thresholds = _readJson(options.thresholdsPath, 'thresholds');
  try {
    final evaluation = evaluatePerformanceGate(
      result: result,
      thresholds: thresholds,
      baselineId: options.baselineId,
      requireBaseline: options.requireBaseline,
    );
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        ...evaluation.toJson(),
        'result': options.resultPath,
        'thresholds': options.thresholdsPath,
      }),
    );
    exitCode = evaluation.exitCode;
  } on FormatException catch (error) {
    _fail(error.message);
  }
}

/// Pure evaluation seam for tests and CI integrations. I/O and process exit
/// are deliberately confined to [main].
PerformanceGateResult evaluatePerformanceGate({
  required Map<String, dynamic> result,
  required Map<String, dynamic> thresholds,
  required String baselineId,
  bool requireBaseline = false,
}) {
  final baselines = thresholds['baselines'];
  if (thresholds['schema_version'] != 1 || baselines is! List) {
    throw const FormatException(
      'thresholds must contain schema_version: 1 and baselines: []',
    );
  }

  Map<String, dynamic>? baseline;
  for (final candidate in baselines) {
    if (candidate is Map && candidate['id'] == baselineId) {
      baseline = Map<String, dynamic>.from(candidate);
      break;
    }
  }
  if (baseline == null) {
    return PerformanceGateResult(
      status: 'baseline_required',
      baselineId: baselineId,
      exitCode: requireBaseline ? 3 : 0,
    );
  }

  final metrics = result['metrics'];
  final limits = baseline['metrics'];
  if (metrics is! Map || limits is! Map) {
    throw const FormatException('result/baseline metrics missing');
  }
  final failures = <String>[];
  for (final entry in limits.entries) {
    final metric = metrics[entry.key];
    final limit = entry.value;
    if (metric is! Map || limit is! Map) {
      failures.add('${entry.key}: missing metric or limit');
      continue;
    }
    final p95 = metric['p95_ms'];
    final p95Max = limit['p95_max_ms'];
    if (p95 is! num || p95Max is! num) {
      failures.add('${entry.key}: p95_ms/p95_max_ms missing');
    } else if (p95 > p95Max) {
      failures.add('${entry.key}: p95 ${p95}ms exceeds ${p95Max}ms');
    }
  }
  return PerformanceGateResult(
    status: failures.isEmpty ? 'passed' : 'failed',
    baselineId: baselineId,
    failures: failures,
    exitCode: failures.isEmpty ? 0 : 1,
  );
}

class PerformanceGateResult {
  const PerformanceGateResult({
    required this.status,
    required this.baselineId,
    required this.exitCode,
    this.failures = const [],
  });

  final String status;
  final String baselineId;
  final int exitCode;
  final List<String> failures;

  Map<String, Object> toJson() => {
    'schema_version': 1,
    'baseline_id': baselineId,
    'status': status,
    'failures': failures,
  };
}

class _Options {
  _Options(
    this.resultPath,
    this.thresholdsPath,
    this.baselineId,
    this.requireBaseline,
  );

  final String resultPath;
  final String thresholdsPath;
  final String baselineId;
  final bool requireBaseline;

  static _Options parse(List<String> args) {
    String? result;
    var thresholds = 'performance/thresholds.json';
    String? baseline;
    var requireBaseline = false;
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (arg == '--require-baseline') {
        requireBaseline = true;
      } else if (arg == '--result' ||
          arg == '--thresholds' ||
          arg == '--baseline') {
        if (++index >= args.length) _fail('$arg requires a value');
        final value = args[index];
        if (arg == '--result') result = value;
        if (arg == '--thresholds') thresholds = value;
        if (arg == '--baseline') baseline = value;
      } else {
        _fail('unknown argument: $arg');
      }
    }
    if (result == null || baseline == null) {
      _fail(
        'usage: --result FILE --baseline ID [--thresholds FILE] [--require-baseline]',
      );
    }
    return _Options(result, thresholds, baseline, requireBaseline);
  }
}

Map<String, dynamic> _readJson(String path, String label) {
  final file = File(path);
  if (!file.existsSync()) _fail('$label file not found: $path');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) _fail('$label is not a JSON object: $path');
  return Map<String, dynamic>.from(decoded);
}

Never _fail(String message) {
  stderr.writeln('[performance-gate] ERROR: $message');
  exit(2);
}
