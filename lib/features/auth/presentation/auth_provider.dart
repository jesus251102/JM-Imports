import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/auth/data/firebase_auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

// StateProvider to track if biometric unlock has passed for the current session
final isBiometricUnlockedProvider = StateProvider<bool>((ref) => false);
