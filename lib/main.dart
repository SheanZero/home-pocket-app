import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  // await _initializeServices();

  runApp(
    const ProviderScope(
      child: HomePocketApp(),
    ),
  );
}

/// Initialize core services before app starts
Future<void> _initializeServices() async {
  // TODO: Initialize database
  // TODO: Initialize encryption
  // TODO: Initialize secure storage
  // TODO: Initialize device manager
}
