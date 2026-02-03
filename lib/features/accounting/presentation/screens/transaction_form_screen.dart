import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Transaction Form Screen
/// Create or edit transaction
class TransactionFormScreen extends ConsumerWidget {
  const TransactionFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save transaction
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: const Center(
        child: Text('TODO: Implement transaction form'),
      ),
    );
  }
}
