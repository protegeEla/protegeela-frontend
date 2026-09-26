import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/authentication/data/demo_session_repository.dart';
import 'protegeela_brand.dart';

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell({super.key, required this.child});

  final Widget child;

  static const destinations = [
    _Destination('Início', Icons.home_outlined, Icons.home_rounded, '/home'),
    _Destination(
        'Mapa e apoio', Icons.map_outlined, Icons.map_rounded, '/mapa'),
    _Destination(
      'Rede de apoio',
      Icons.people_outline_rounded,
      Icons.people_rounded,
      '/contatos',
    ),
    _Destination(
      'Perfil',
      Icons.person_outline_rounded,
      Icons.person_rounded,
      '/perfil',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final location = GoRouterState.of(context).uri.path;
    final index = destinations.indexWhere(
      (item) => location.startsWith(item.path),
    );
    final selectedIndex = index < 0 ? 0 : index;

    if (width >= 900) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopNavigation(
              selectedIndex: selectedIndex,
              onSelected: (value) => context.go(destinations[value].path),
              onSignOut: () => _signOut(context, ref),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _MobileNavigation(
        selectedIndex: selectedIndex,
        onSelected: (value) => context.go(destinations[value].path),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final demoActive = await ref.read(demoSessionProvider.future);
    if (demoActive) {
      await ref.read(demoSessionRepositoryProvider).end();
      ref.invalidate(demoSessionProvider);
    } else {
      await ref.read(authRepositoryProvider).signOut();
    }
    if (context.mounted) context.go('/login');
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selectedIndex,
    required this.onSelected,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProtegeElaBrand(compact: true),
              const SizedBox(height: 38),
              for (var index = 0;
                  index < ResponsiveShell.destinations.length;
                  index++) ...[
                _DesktopNavigationItem(
                  destination: ResponsiveShell.destinations[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
                const SizedBox(height: 7),
              ],
              const Spacer(),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: onSignOut,
                  borderRadius: BorderRadius.circular(11),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.textMuted,
                          size: 21,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Sair',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Mais mulheres\nmais seguras  ♡',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigationItem extends StatelessWidget {
  const _DesktopNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Material(
      color: selected ? AppColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
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

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 72,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: [
        for (final item in ResponsiveShell.destinations)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label == 'Rede de apoio' ? 'Rede' : item.label,
          ),
      ],
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.path);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
