import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jm_imports/app.dart';
import 'package:jm_imports/core/services/app_error_logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // Capturar errores no controlados del framework de Flutter
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppErrorLogger.logError(
      details.exception,
      details.stack,
      context: 'Flutter Framework',
      fatal: true,
    );
  };

  // Capturar errores no controlados asíncronos de la plataforma
  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrorLogger.logError(
      error,
      stack,
      context: 'Platform Async',
      fatal: true,
    );
    return true;
  };

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
    // Enable instant local persistence for 0-latency offline/online writes
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e, stack) {
    AppErrorLogger.logError(e, stack, context: 'Firebase Initialization');
  }

  runApp(const ProviderScope(child: App()));
}
