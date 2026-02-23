import 'dart:math';

/// Computes the Levenshtein edit distance between two strings.
///
/// Uses O(min(n,m)) space via a rolling single-row DP approach.
int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Ensure a is the shorter string for O(min(n,m)) space
  if (a.length > b.length) {
    final tmp = a;
    a = b;
    b = tmp;
  }

  final aLen = a.length;
  final bLen = b.length;
  var prev = List<int>.generate(aLen + 1, (i) => i);
  var curr = List<int>.filled(aLen + 1, 0);

  for (var j = 1; j <= bLen; j++) {
    curr[0] = j;
    for (var i = 1; i <= aLen; i++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[i] = min(
        min(curr[i - 1] + 1, prev[i] + 1),
        prev[i - 1] + cost,
      );
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }

  return prev[aLen];
}

/// Returns a similarity score between 0.0 (completely different) and
/// 1.0 (identical), computed as `1 - (editDistance / maxLength)`.
double normalizedSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final dist = levenshteinDistance(a, b);
  return 1.0 - (dist / max(a.length, b.length));
}
