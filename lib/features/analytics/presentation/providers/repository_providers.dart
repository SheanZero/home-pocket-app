import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/daos/analytics_dao.dart';
import '../../../../data/repositories/analytics_repository_impl.dart';
import '../../../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../../../infrastructure/security/providers.dart';

part 'repository_providers.g.dart';

/// AnalyticsDao provider — single source of truth.
@riverpod
AnalyticsDao analyticsDao(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return AnalyticsDao(database);
}

/// AnalyticsRepository provider.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(dao: ref.watch(analyticsDaoProvider));
});
