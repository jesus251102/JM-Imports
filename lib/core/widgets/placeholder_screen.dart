import 'package:flutter/material.dart';
import 'package:jm_imports/core/theme/app_colors.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textLightGray,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
