import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/supabase_providers.dart';
import '../core/widgets/responsive_shell.dart';
import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/alerts_map/presentation/alerts_map_page.dart';
import '../features/authentication/data/demo_session_repository.dart';
import '../features/authentication/presentation/email_confirmation_page.dart';
import '../features/authentication/presentation/login_page.dart';
import '../features/authentication/presentation/reset_password_page.dart';
import '../features/authentication/presentation/update_password_page.dart';
import '../features/emergency/presentation/active_alert_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/onboarding/presentation/location_intro_page.dart';
import '../features/onboarding/presentation/neutral_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/privacy_intro_page.dart';
import '../features/onboarding/presentation/splash_page.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/profile_setup_page.dart';
import '../features/safety_content/presentation/safety_content_page.dart';
import '../features/support_points/presentation/anonymous_report_page.dart';
import '../features/support_points/presentation/women_police_page.dart';
import '../features/trusted_contacts/presentation/first_contact_page.dart';
import '../features/trusted_contacts/presentation/trusted_contacts_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refresh = GoRouterRefreshStream(client.auth.onAuthStateChange);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final path = state.uri.path;
      final isPublic = _publicPaths.contains(path);
      final user = client.auth.currentUser;
      final demoActive = await ref.read(demoSessionProvider.future);

      if (user == null && !demoActive) return isPublic ? null : '/login';
      if (path == '/atualizar-senha') return null;
      if (isPublic && path != '/neutral') return '/home';
      if (demoActive) return null;

      final profile = await ref.read(currentProfileProvider.future);
      final profileFlow = path == '/criar-perfil' ||
          path == '/editar-perfil' ||
          path == '/primeiro-contato';
      if (profile == null && !profileFlow) return '/criar-perfil';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(
          path: '/apresentacao', builder: (_, __) => const OnboardingPage()),
      GoRoute(
          path: '/privacidade', builder: (_, __) => const PrivacyIntroPage()),
      GoRoute(
        path: '/privacidade-conta',
        builder: (_, __) => const PrivacyIntroPage(inSettings: true),
      ),
      GoRoute(
          path: '/localizacao', builder: (_, __) => const LocationIntroPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/cadastro',
        builder: (_, __) => const LoginPage(
          initialView: AuthenticationView.register,
        ),
      ),
      GoRoute(
          path: '/recuperar-senha',
          builder: (_, __) => const ResetPasswordPage()),
      GoRoute(
        path: '/atualizar-senha',
        builder: (_, __) => const UpdatePasswordPage(),
      ),
      GoRoute(
          path: '/confirmar-email',
          builder: (_, __) => const EmailConfirmationPage()),
      GoRoute(path: '/neutral', builder: (_, __) => const NeutralPage()),
      GoRoute(
          path: '/criar-perfil', builder: (_, __) => const ProfileSetupPage()),
      GoRoute(
        path: '/editar-perfil',
        builder: (_, __) => const ProfileSetupPage(editing: true),
      ),
      GoRoute(
          path: '/primeiro-contato',
          builder: (_, __) => const FirstContactPage()),
      ShellRoute(
        builder: (_, __, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/mapa',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AlertsMapPage()),
          ),
          GoRoute(
            path: '/contatos',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: TrustedContactsPage()),
          ),
          GoRoute(
            path: '/perfil',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      GoRoute(
          path: '/alerta-ativo', builder: (_, __) => const ActiveAlertPage()),
      GoRoute(path: '/apoio', redirect: (_, __) => '/mapa'),
      GoRoute(
          path: '/denuncia-anonima',
          builder: (_, __) => const AnonymousReportPage()),
      GoRoute(
          path: '/delegacia-da-mulher',
          builder: (_, __) => const WomenPolicePage()),
      GoRoute(
          path: '/orientacoes', builder: (_, __) => const SafetyContentPage()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardPage()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

const _publicPaths = {
  '/',
  '/apresentacao',
  '/privacidade',
  '/localizacao',
  '/login',
  '/cadastro',
  '/recuperar-senha',
  '/atualizar-senha',
  '/confirmar-email',
  '/neutral',
};

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
          // Auth refresh failures must not become unhandled asynchronous errors.
          // The router reevaluates using the last session known by the SDK.
          onError: (_, __) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
