import 'package:flutter/material.dart';

/// Breakpoints for responsive layout
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  Breakpoints._();
}

/// Determines the device type based on screen width
enum DeviceType { mobile, tablet, desktop }

DeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < Breakpoints.mobile) return DeviceType.mobile;
  if (width < Breakpoints.tablet) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// Responsive layout widget that builds different UIs
/// for mobile, tablet, and desktop.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// A scaffold that adapts between mobile (bottom nav) and desktop (side nav).
class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget body;
  final Widget? drawer;
  final bool isManager;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.drawer,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(context);

    if (deviceType == DeviceType.desktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TimeSheet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    if (deviceType == DeviceType.tablet) {
      return Scaffold(
        drawer: drawer,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.selected,
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Mobile - uses the existing BottomNavigationBar
    return Scaffold(
      drawer: drawer,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}

/// Helper extension for responsive values
extension ResponsiveExtension on BuildContext {
  DeviceType get deviceType => getDeviceType(this);

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Returns different values based on device type
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Returns responsive padding
  EdgeInsets get responsivePadding {
    switch (deviceType) {
      case DeviceType.desktop:
        return const EdgeInsets.all(24);
      case DeviceType.tablet:
        return const EdgeInsets.all(20);
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
    }
  }

  /// Returns responsive column count for grid layouts
  int get responsiveGridColumns {
    switch (deviceType) {
      case DeviceType.desktop:
        return 4;
      case DeviceType.tablet:
        return 3;
      case DeviceType.mobile:
        return 2;
    }
  }
}
