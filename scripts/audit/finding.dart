// scripts/audit/finding.dart
// Schema lock for every audit shard. Mirrors .planning/audit/SCHEMA.md.

class Finding {
  final String? id; // null until merge_findings stamps it
  final String
  category; // 'layer_violation' | 'provider_hygiene' | 'dead_code' | 'redundant_code'
  final String severity; // 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  final String filePath; // e.g. 'lib/features/family_sync/use_cases/foo.dart'
  final int lineStart;
  final int lineEnd;
  final String description;
  final String rationale;
  final String suggestedFix;
  final String
  toolSource; // 'import_guard' | 'riverpod_lint' | 'dart_code_linter' | 'agent:layer' | ...
  final String confidence; // 'high' | 'medium' | 'low'
  final String status; // 'open' | 'closed' (Phase 1 emits 'open')
  final String? closedInPhase; // null in Phase 1
  final String? closedCommit; // null in Phase 1

  const Finding({
    this.id,
    required this.category,
    required this.severity,
    required this.filePath,
    required this.lineStart,
    required this.lineEnd,
    required this.description,
    required this.rationale,
    required this.suggestedFix,
    required this.toolSource,
    required this.confidence,
    this.status = 'open',
    this.closedInPhase,
    this.closedCommit,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'category': category,
    'severity': severity,
    'file_path': filePath,
    'line_start': lineStart,
    'line_end': lineEnd,
    'description': description,
    'rationale': rationale,
    'suggested_fix': suggestedFix,
    'tool_source': toolSource,
    'confidence': confidence,
    'status': status,
    if (closedInPhase != null) 'closed_in_phase': closedInPhase,
    if (closedCommit != null) 'closed_commit': closedCommit,
  };

  factory Finding.fromJson(Map<String, dynamic> j) => Finding(
    id: j['id'] as String?,
    category: j['category'] as String,
    severity: j['severity'] as String,
    filePath: j['file_path'] as String,
    lineStart: j['line_start'] as int,
    lineEnd: j['line_end'] as int,
    description: j['description'] as String,
    rationale: j['rationale'] as String,
    suggestedFix: j['suggested_fix'] as String,
    toolSource: j['tool_source'] as String,
    confidence: j['confidence'] as String,
    status: (j['status'] as String?) ?? 'open',
    closedInPhase: j['closed_in_phase']?.toString(),
    closedCommit: j['closed_commit'] as String?,
  );
}
