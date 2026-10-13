import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_score/v2/app.dart';
import 'package:live_score/v2/core/clock.dart';
import 'package:live_score/v2/core/prefs.dart';
import 'package:live_score/v2/core/scope.dart';
import 'package:live_score/v2/core/theme.dart';
import 'package:live_score/v2/data/api.dart';
import 'package:live_score/v2/data/models.dart';
import 'package:live_score/v2/ui/screens/match_screen.dart';
import 'package:live_score/v2/ui/screens/news_screen.dart';
import 'package:live_score/v2/ui/screens/team_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:live_score/v2/ui/widgets/common.dart';

import '../helpers.dart';

/// Renders screens from recorded real 365scores JSON + logos (test/fixtures)
/// at the reference phone resolution (1080x2392 @ 2.625).
void main() {
  late FavoritesStore store;
  setUpAll(() async {
    await loadFonts();
    Logo.offline = true;
    Logo.testBytes = fixtureImage;
    ScoresApi.instance = fixtureApi();
    Clock.now = () => DateTime(2026, 10, 12, 13, 23, 5);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = FavoritesStore(await SharedPreferences.getInstance());
    await store.toggleTeam(const Team(id: 7549, name: 'Al Nassr FC'));
    await store.toggleTeam(const Team(id: 225, name: 'AS Roma'));
  });

  Future<void> shot(WidgetTester t, Widget home, String name) async {
    t.view.physicalSize = const Size(1080, 2392);
    t.view.devicePixelRatio = 2.625;
    t.view.padding = const FakeViewPadding(top: 140, bottom: 50);
    t.view.viewPadding = const FakeViewPadding(top: 140, bottom: 50);
    addTearDown(t.view.reset);
    await t.pumpWidget(AppScope(
      store: store,
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(Brightness.light), darkTheme: buildTheme(Brightness.dark), themeMode: ThemeMode.dark, home: home),
    ));
    for (var i = 0; i < 4; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump(const Duration(milliseconds: 300));
    }
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await t.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 2));
  }

  testWidgets('home', (t) async => shot(t, const HomeShell(), 'home'));
  testWidgets('match preview levante', (t) async => shot(t, const MatchScreen(gameId: 4750836), 'match_preview'));
  testWidgets('match preview nassr', (t) async => shot(t, const MatchScreen(gameId: 4817270), 'match_preview_nassr'));
  testWidgets('match table', (t) async => shot(t, const MatchScreen(gameId: 4750836, initialTab: 2), 'match_table'));
  testWidgets('match lineup predicted', (t) async => shot(t, const MatchScreen(gameId: 4750836, initialTab: 1), 'match_lineup_predicted'));
  testWidgets('finished match facts', (t) async => shot(t, const MatchScreen(gameId: 4732688), 'finished_facts'));
  testWidgets('finished stats', (t) async => shot(t, const MatchScreen(gameId: 4732688, initialTab: 1), 'finished_stats'));
  testWidgets('finished lineups', (t) async => shot(t, const MatchScreen(gameId: 4732688, initialTab: 2), 'finished_lineups'));
  testWidgets('team', (t) async => shot(t, const TeamScreen(team: Team(id: 225, name: 'AS Roma')), 'team'));
  testWidgets('news', (t) async => shot(t, const Scaffold(body: NewsScreen()), 'news'));
}
