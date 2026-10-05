import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/network_status_overlay.dart';
import '../features/check_in/presentation/check_in_location_tracker.dart';
import 'router.dart';
import 'theme.dart';

class ProtegeElaApp extends ConsumerWidget {
  const ProtegeElaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ProtegeEla',
      debugShowCheckedModeBanner: false,
      theme: buildProtegeElaTheme(),
      builder: (context, child) => CheckInLocationTracker(
        child: NetworkStatusOverlay(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
