import 'package:flutter/material.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  final String? message;
  
  const SplashScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.accentLightBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'JM IMPORTS',
                style: AppTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gestión de Reparaciones e Inventario',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLightGray,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                  strokeWidth: 2.5,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLightGray,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
