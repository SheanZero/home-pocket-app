import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/initialization/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create provider container for initialization
  final container = ProviderContainer();

  try {
    // Initialize core services
    await AppInitializer.initialize(container);

    // Run app with initialized container
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const HomePocketApp(),
      ),
    );
  } catch (e) {
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
