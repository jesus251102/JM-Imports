import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavItemData(
      icon: Icons.build_outlined,
      selectedIcon: Icons.build_rounded,
      label: 'Reparaciones',
    ),
    _NavItemData(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Inventario',
    ),
    _NavItemData(
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
      label: 'Ventas',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // Tablet layout
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.backgroundDark,
                  indicatorColor: AppColors.primaryBlue,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    AppHaptics.selection();
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  extended: false,
                  selectedLabelTextStyle: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  unselectedLabelTextStyle: const TextStyle(color: AppColors.textLightGray),
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedIconTheme: const IconThemeData(color: AppColors.textLightGray),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.build_rounded),
                      label: Text('Reparaciones'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_rounded),
                      label: Text('Inventario'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_rounded),
                      label: Text('Ventas'),
                    ),
                  ],
                ),
                Expanded(child: navigationShell),
              ],
            ),
          );
        } else {
          // Phone layout ultra moderno con resplandor neón y respuesta táctil
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isSelected = navigationShell.currentIndex == index;

                      return Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (!isSelected) {
                                AppHaptics.selection();
                              }
                              navigationShell.goBranch(
                                index,
                                initialLocation: index == navigationShell.currentIndex,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryBlue.withValues(alpha: 0.18)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryBlue.withValues(alpha: 0.4)
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: AppColors.primaryBlue.withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          ),
                                      ],
                                    ),
                                    child: Icon(
                                      isSelected ? item.selectedIcon : item.icon,
                                      color: isSelected ? AppColors.primaryBlue : AppColors.textLightGray,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AppColors.primaryBlue : AppColors.textLightGray,
                                    ),
                                    child: Text(item.label),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
