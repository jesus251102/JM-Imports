import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jm_imports/core/theme/app_colors.dart';

/// Widget de carga tipo Shimmer adaptado a la paleta oscura de la aplicación
class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceBlue.withValues(alpha: 0.3),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Esqueleto Shimmer para tarjetas genéricas o del Dashboard
class AppCardSkeleton extends StatelessWidget {
  final double height;

  const AppCardSkeleton({
    super.key,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceBlue.withValues(alpha: 0.3),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }
}

/// Esqueleto Shimmer completo para simular el Dashboard cargando
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppShimmer(width: 46, height: 46, borderRadius: 12),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 140, height: 18, borderRadius: 4),
                  SizedBox(height: 6),
                  AppShimmer(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: AppCardSkeleton(height: 80)),
              SizedBox(width: 12),
              Expanded(child: AppCardSkeleton(height: 80)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: AppCardSkeleton(height: 80)),
              SizedBox(width: 12),
              Expanded(child: AppCardSkeleton(height: 80)),
            ],
          ),
          const SizedBox(height: 16),
          const AppCardSkeleton(height: 180),
          const SizedBox(height: 16),
          const AppCardSkeleton(height: 220),
        ],
      ),
    );
  }
}
