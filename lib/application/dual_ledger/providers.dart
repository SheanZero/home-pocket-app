import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'classification_service.dart';
import 'rule_engine.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
RuleEngine ruleEngine(Ref ref) {
  return RuleEngine();
}

@riverpod
ClassificationService classificationService(Ref ref) {
  final ruleEngine = ref.watch(ruleEngineProvider);
  return ClassificationService(ruleEngine: ruleEngine);
}
