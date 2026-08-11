import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'operations.dart';
import 'screens.dart';
import 'theme.dart';

final localeProvider = StateProvider<Locale>((_) => const Locale('en'));

class SeatRestaurantApp extends ConsumerWidget {
  const SeatRestaurantApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'SEAT Restaurant',
      debugShowCheckedModeBanner: false,
      theme: seatTheme(),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router(ref),
    );
  }
}

GoRouter _router(WidgetRef ref) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/otp',
      builder: (_, s) => OtpScreen(phone: s.uri.queryParameters['phone'] ?? ''),
    ),
    GoRoute(
      path: '/branches',
      builder: (_, __) => const BranchSelectionScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => OperationalShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (_, __) => const InboxScreen(),
              routes: [
                GoRoute(
                  path: 'request/:id',
                  builder: (_, s) =>
                      RequestDetailsScreen(id: s.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'suggest',
                      builder: (_, s) =>
                          SuggestTimeScreen(id: s.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (_, __) => const TodayScreen(),
              routes: [
                GoRoute(
                  path: 'reservation/:id',
                  builder: (_, s) =>
                      OperationalDetailsScreen(id: s.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'policy',
                  builder: (_, __) => const PolicyScreen(),
                ),
                GoRoute(
                  path: 'profile',
                  builder: (_, __) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class OperationalShell extends ConsumerStatefulWidget {
  const OperationalShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  ConsumerState<OperationalShell> createState() => _OperationalShellState();
}

class _OperationalShellState extends ConsumerState<OperationalShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(operationsProvider).refresh();
      if (widget.shell.currentIndex == 0)
        ref.read(operationsProvider).startPolling();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = ref.read(operationsProvider);
    if (state == AppLifecycleState.resumed && widget.shell.currentIndex == 0)
      c.startPolling();
    else
      c.stopPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(operationsProvider).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final labels = ar
        ? ['الطلبات', 'اليوم', 'الإعدادات']
        : ['Inbox', 'Today', 'Settings'];
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) {
          final c = ref.read(operationsProvider);
          i == 0 ? c.startPolling() : c.stopPolling();
          widget.shell.goBranch(
            i,
            initialLocation: i == widget.shell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: labels[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: labels[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: labels[2],
          ),
        ],
      ),
    );
  }
}
