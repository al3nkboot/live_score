import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_score/v2/core/prefs.dart';
import 'package:live_score/v2/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Game _g(int id, int h, int a, int comp) => Game(
    id: id, competitionId: comp, competitionName: '', startTime: DateTime(2026), statusGroup: 2, statusText: '', shortStatus: '',
    gameTime: -1, gameTimeDisplay: '', home: Team(id: h, name: 'H'), away: Team(id: a, name: 'A'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('favorites persist across instances', () async {
    final p = await SharedPreferences.getInstance();
    final s = FavoritesStore(p);
    await s.toggleTeam(const Team(id: 104, name: 'Arsenal'));
    await s.toggleLeague(const League(id: 7, name: 'Premier League'));
    await s.toggleMatch(99);
    await s.setTheme(ThemeMode.light);
    await s.setDataLang('ar');
    await s.setTeamNotifs(104, false);
    final s2 = FavoritesStore(p);
    expect(s2.teams[104]!.name, 'Arsenal');
    expect(s2.isLeague(7), isTrue);
    expect(s2.isMatch(99), isTrue);
    expect(s2.themeMode, ThemeMode.light);
    expect(s2.dataLang, 'ar');
    expect(s2.teamNotifs(104), isFalse);
  });

  test('toggle removes; follows/wantsNotifs logic', () async {
    final s = FavoritesStore(await SharedPreferences.getInstance());
    await s.toggleTeam(const Team(id: 1, name: 'X'));
    expect(s.wantsNotifs(_g(5, 1, 2, 9)), isTrue);
    await s.setTeamNotifs(1, false);
    expect(s.wantsNotifs(_g(5, 1, 2, 9)), isFalse);
    expect(s.follows(_g(5, 1, 2, 9)), isTrue);
    await s.toggleMatch(5);
    expect(s.wantsNotifs(_g(5, 1, 2, 9)), isTrue);
    await s.toggleTeam(const Team(id: 1, name: 'X'));
    expect(s.isTeam(1), isFalse);
    await s.toggleLeague(const League(id: 9, name: 'L'));
    expect(s.follows(_g(6, 3, 4, 9)), isTrue);
    expect(s.wantsNotifs(_g(6, 3, 4, 9)), isFalse);
  });
}
