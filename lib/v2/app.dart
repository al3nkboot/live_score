import 'package:flutter/material.dart';

import 'core/prefs.dart';
import 'core/scope.dart';
import 'core/theme.dart';
import 'data/api.dart';
import 'notify/notifier.dart';
import 'ui/screens/following_screen.dart';
import 'ui/screens/leagues_screen.dart';
import 'ui/screens/matches_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/screens/news_screen.dart';
import 'ui/widgets/common.dart';
import 'ui/screens/onboarding_screen.dart';

class LiveScoreApp extends StatefulWidget {
  final FavoritesStore store;
  final bool skipOnboarding;
  const LiveScoreApp({super.key, required this.store, this.skipOnboarding = false});
  @override
  State<LiveScoreApp> createState() => _LiveScoreAppState();
}

class _LiveScoreAppState extends State<LiveScoreApp> with WidgetsBindingObserver {
  String _lang = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Notifier.startForeground(widget.store);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    s == AppLifecycleState.resumed ? Notifier.startForeground(widget.store) : Notifier.stopForeground();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Notifier.stopForeground();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: widget.store,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (c, _) {
          final s = widget.store;
          ScoresApi.instance.langId = s.dataLang == 'ar' ? 27 : 1;
          // Language switch => force a fresh tree so data reloads.
          final langChanged = _lang != s.dataLang;
          _lang = s.dataLang;
          return MaterialApp(
            key: langChanged ? ValueKey('lang-${s.dataLang}') : null,
            title: 'Live Score',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: s.themeMode,
            home: (s.onboarded || widget.skipOnboarding) ? const HomeShell() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final int initial;
  const HomeShell({super.key, this.initial = 0});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _i = widget.initial;
  static const _pages = [MatchesScreen(), NewsScreen(), LeaguesScreen(), FollowingScreen(), MoreScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: PitchIcon(), selectedIcon: PitchIcon(filled: true), label: 'Matches'),
          NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article), label: 'News'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Leagues'),
          NavigationDestination(icon: Icon(Icons.star_border_rounded), selectedIcon: Icon(Icons.star_rounded), label: 'Following'),
          NavigationDestination(icon: Icon(Icons.menu), selectedIcon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}

