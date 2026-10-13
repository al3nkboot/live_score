import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';

/// Locally persisted favorites (teams, leagues, matches) and settings.
class FavoritesStore extends ChangeNotifier {
  static const _kTeams = 'v2.fav.teams';
  static const _kLeagues = 'v2.fav.leagues';
  static const _kMatches = 'v2.fav.matches';
  static const _kMuted = 'v2.notif.mutedTeams';
  static const _kTheme = 'v2.theme';
  static const _kLang = 'v2.dataLang';
  static const _kOnboarded = 'v2.onboarded';
  static const _kNotif = 'v2.notif.types';
  static const _kBell = 'v2.notif.matches';

  final SharedPreferences prefs;
  FavoritesStore(this.prefs) {
    _load();
  }

  final Map<int, Team> teams = {};
  final Map<int, League> leagues = {};
  final Set<int> matches = {};
  final Set<int> mutedTeams = {};
  final Set<int> bellMatches = {};
  ThemeMode themeMode = ThemeMode.dark;
  String dataLang = 'en';
  bool onboarded = false;
  /// Enabled notification kinds: goal, kickoff, halftime, fulltime, red.
  Set<String> notifTypes = {'goal', 'kickoff', 'halftime', 'fulltime', 'red'};

  void _load() {
    teams.clear();
    leagues.clear();
    for (final s in prefs.getStringList(_kTeams) ?? const <String>[]) {
      final t = Team.fromJson(jsonDecode(s));
      teams[t.id] = t;
    }
    for (final s in prefs.getStringList(_kLeagues) ?? const <String>[]) {
      final l = League.fromJson(jsonDecode(s));
      leagues[l.id] = l;
    }
    matches
      ..clear()
      ..addAll((prefs.getStringList(_kMatches) ?? const []).map(int.parse));
    mutedTeams
      ..clear()
      ..addAll((prefs.getStringList(_kMuted) ?? const []).map(int.parse));
    bellMatches
      ..clear()
      ..addAll((prefs.getStringList(_kBell) ?? const []).map(int.parse));
    themeMode = switch (prefs.getString(_kTheme)) { 'light' => ThemeMode.light, 'system' => ThemeMode.system, _ => ThemeMode.dark };
    dataLang = prefs.getString(_kLang) ?? 'en';
    onboarded = prefs.getBool(_kOnboarded) ?? false;
    final n = prefs.getStringList(_kNotif);
    if (n != null) notifTypes = n.toSet();
  }

  Future<void> _save() async {
    await prefs.setStringList(_kTeams, teams.values.map((t) => jsonEncode(t.toJson())).toList());
    await prefs.setStringList(_kLeagues, leagues.values.map((l) => jsonEncode(l.toJson())).toList());
    await prefs.setStringList(_kMatches, matches.map((e) => '$e').toList());
    await prefs.setStringList(_kMuted, mutedTeams.map((e) => '$e').toList());
    await prefs.setStringList(_kNotif, notifTypes.toList());
    await prefs.setStringList(_kBell, bellMatches.map((e) => '$e').toList());
    notifyListeners();
  }

  bool isTeam(int id) => teams.containsKey(id);
  bool isLeague(int id) => leagues.containsKey(id);
  bool isMatch(int id) => matches.contains(id);

  Future<void> toggleTeam(Team t) {
    teams.containsKey(t.id) ? teams.remove(t.id) : teams[t.id] = Team(id: t.id, name: t.name, shortName: t.shortName, countryId: t.countryId);
    return _save();
  }

  Future<void> toggleLeague(League l) {
    leagues.containsKey(l.id) ? leagues.remove(l.id) : leagues[l.id] = l;
    return _save();
  }

  Future<void> toggleMatch(int id) {
    matches.contains(id) ? matches.remove(id) : matches.add(id);
    return _save();
  }

  Future<void> toggleBell(int id) {
    bellMatches.contains(id) ? bellMatches.remove(id) : bellMatches.add(id);
    return _save();
  }

  /// Local 'Who will win?' vote: 1 home, 2 draw, 3 away.
  int? vote(int gameId) => prefs.getInt('v2.vote.$gameId');
  Future<void> setVote(int gameId, int v) async {
    await prefs.setInt('v2.vote.$gameId', v);
    notifyListeners();
  }

  bool teamNotifs(int id) => !mutedTeams.contains(id);
  Future<void> setTeamNotifs(int id, bool on) {
    on ? mutedTeams.remove(id) : mutedTeams.add(id);
    return _save();
  }

  Future<void> setNotifType(String k, bool on) {
    notifTypes = {...notifTypes};
    on ? notifTypes.add(k) : notifTypes.remove(k);
    return _save();
  }

  Future<void> setTheme(ThemeMode m) async {
    themeMode = m;
    await prefs.setString(_kTheme, m.name);
    notifyListeners();
  }

  Future<void> setDataLang(String l) async {
    dataLang = l;
    await prefs.setString(_kLang, l);
    notifyListeners();
  }

  Future<void> setOnboarded() async {
    onboarded = true;
    await prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  /// Whether a game involves something the user follows.
  bool follows(Game g) => matches.contains(g.id) || teams.containsKey(g.home.id) || teams.containsKey(g.away.id) || leagues.containsKey(g.competitionId);

  /// Whether the user should be notified about a game.
  bool wantsNotifs(Game g) =>
      matches.contains(g.id) ||
      bellMatches.contains(g.id) ||
      (teams.containsKey(g.home.id) && teamNotifs(g.home.id)) ||
      (teams.containsKey(g.away.id) && teamNotifs(g.away.id));
}
