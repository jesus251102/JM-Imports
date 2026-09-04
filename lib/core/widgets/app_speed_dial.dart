import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/features/clients/presentation/client_form_dialog.dart';

class SpeedDialItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SpeedDialItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class AppSpeedDial extends StatefulWidget {
  final List<SpeedDialItem>? customItems;

  const AppSpeedDial({super.key, this.customItems});

  @override
  State<AppSpeedDial> createState() => _AppSpeedDialState();
}

class _AppSpeedDialState extends State<AppSpeedDial> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    AppHaptics.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  List<SpeedDialItem> _getDefaultItems(BuildContext context) {
    return [
      SpeedDialItem(
        label: 'Reparación',
        icon: Icons.build_rounded,
        color: AppColors.primaryBlue,
        onTap: () {
          _close();
          context.push('/repairs/new');
        },
      ),
      SpeedDialItem(
        label: 'Venta (POS)',
        icon: Icons.point_of_sale_rounded,
        color: AppColors.success,
        onTap: () {
          _close();
          context.push('/sales/new');
        },
      ),
      SpeedDialItem(
        label: 'Repuesto',
        icon: Icons.inventory_2_rounded,
        color: AppColors.warning,
        onTap: () {
          _close();
          context.push('/inventory/new');
        },
      ),
      SpeedDialItem(
        label: 'Cliente',
        icon: Icons.person_add_rounded,
        color: AppColors.accentLightBlue,
        onTap: () {
          _close();
          showDialog(
            context: context,
            builder: (context) => const ClientFormDialog(),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.customItems ?? _getDefaultItems(context);

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Transparent barrier background when open to dismiss on outside tap
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

        // Floating menu items
        Padding(
          padding: const EdgeInsets.only(bottom: 72, right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return _buildSpeedDialRow(item, index, items.length);
            }),
          ),
        ),

        // Main FAB button
        Padding(
          padding: const EdgeInsets.only(bottom: 4, right: 4),
          child: FloatingActionButton(
            heroTag: 'app_speed_dial_main_fab',
            onPressed: _toggle,
            backgroundColor: AppColors.primaryBlue,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandAnimation.value * math.pi * 0.75, // 0 to 135 deg (+ to x)
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialRow(SpeedDialItem item, int index, int total) {
    final reverseIndex = total - 1 - index;
    final step = 1.0 / total;
    final start = reverseIndex * step;
    final end = (reverseIndex + 1) * step;

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: animation,
      alignment: Alignment.centerRight,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Label Pill Chip
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    item.onTap();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: item.color.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Action Mini FAB
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    item.onTap();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
