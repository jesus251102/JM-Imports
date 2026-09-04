import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/core/services/biometric_service.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/features/auth/data/firebase_auth_repository.dart';
import 'package:jm_imports/features/auth/presentation/auth_provider.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptBiometric();
    });
  }

  Future<void> _promptBiometric() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final isAvailable = await BiometricService.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          ref.read(isBiometricUnlockedProvider.notifier).state = true;
        }
        return;
      }

      final success = await BiometricService.authenticate();
      if (success && mounted) {
        ref.read(isBiometricUnlockedProvider.notifier).state = true;
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'JM IMPORTS',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sesión guardada para ${user?.displayName ?? user?.email ?? user?.phoneNumber ?? 'Usuario'}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLightGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                InkWell(
                  onTap: _promptBiometric,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue, width: 2),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 64,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Toca para escanear tu huella digital',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentLightBlue),
                ),
                const SizedBox(height: 48),

                TextButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    ref.read(isBiometricUnlockedProvider.notifier).state = false;
                  },
                  child: Text(
                    'Cerrar sesión / Ingresar con otra cuenta',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
