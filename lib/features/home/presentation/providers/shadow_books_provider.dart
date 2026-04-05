import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../accounting/domain/models/book.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../analytics/domain/models/monthly_report.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../family_sync/presentation/providers/active_group_provider.dart';

part 'shadow_books_provider.g.dart';

class ShadowBookInfo {
  const ShadowBookInfo({
    required this.book,
    required this.memberDisplayName,
    required this.memberAvatarEmoji,
  });

  final Book book;
  final String memberDisplayName;
  final String memberAvatarEmoji;
}

@riverpod
Future<List<ShadowBookInfo>> shadowBooks(Ref ref) async {
  final group = ref.watch(activeGroupProvider).valueOrNull;
  if (group == null) return const [];

  final bookRepo = ref.watch(bookRepositoryProvider);
  final books = await bookRepo.findShadowBooksByGroupId(group.groupId);

  return books.map((book) {
    final member = group.members.firstWhereOrNull(
      (m) => m.deviceId == book.ownerDeviceId,
    );
    return ShadowBookInfo(
      book: book,
      memberDisplayName: member?.displayName ?? book.ownerDeviceName ?? '',
      memberAvatarEmoji: member?.avatarEmoji ?? '',
    );
  }).toList();
}

/// Aggregate monthly report across all shadow books.
///
/// Returns total expenses, previous month total, and per-book reports
/// for rendering individual shadow book ledger rows.
class ShadowAggregate {
  const ShadowAggregate({
    required this.totalExpenses,
    required this.prevTotalExpenses,
    required this.perBookReports,
  });

  const ShadowAggregate.empty()
      : totalExpenses = 0,
        prevTotalExpenses = 0,
        perBookReports = const {};

  final int totalExpenses;
  final int prevTotalExpenses;
  final Map<String, MonthlyReport> perBookReports;
}

@riverpod
Future<ShadowAggregate> shadowAggregate(
  Ref ref, {
  required int year,
  required int month,
}) async {
  final shadowBookList = await ref.watch(shadowBooksProvider.future);
  if (shadowBookList.isEmpty) return const ShadowAggregate.empty();

  final reportUseCase = ref.watch(getMonthlyReportUseCaseProvider);

  var totalExpenses = 0;
  var prevTotalExpenses = 0;
  final perBookReports = <String, MonthlyReport>{};

  for (final shadow in shadowBookList) {
    final report = await reportUseCase.execute(
      bookId: shadow.book.id,
      year: year,
      month: month,
    );
    totalExpenses += report.totalExpenses;
    prevTotalExpenses +=
        report.previousMonthComparison?.previousExpenses ?? 0;
    perBookReports[shadow.book.id] = report;
  }

  return ShadowAggregate(
    totalExpenses: totalExpenses,
    prevTotalExpenses: prevTotalExpenses,
    perBookReports: perBookReports,
  );
}
