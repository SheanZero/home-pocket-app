import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/provider_contract.dart';
import '../../scripts/audit/providers.dart' as providers;

void main() {
  test(
    'provider audit reports the owned contract rather than riverpod_lint',
    () {
      final envelope = providers.buildProviderAuditEnvelope(
        const ProviderContractReport([]),
        generatedAt: DateTime.utc(2026, 8, 6),
      );

      expect(envelope['tool_source'], 'owned_provider_contract');
      expect(envelope['scan_state'], 'ran');
      expect(envelope['findings'], isEmpty);
    },
  );
}
