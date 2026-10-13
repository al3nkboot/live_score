import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:live_score/v2/data/api.dart';

Map<String, dynamic> fixture(String name) => jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

/// API backed by recorded real 365scores responses.
ScoresApi fixtureApi() => ScoresApi(fetcher: (path, q) async {
      final f = switch (path) {
        '/games/allscores/' => q['startDate'] == '12/10/2026' ? 'games_oct12.json' : 'games.json',
        '/game/' => switch (q['gameId']) { 4750836 => 'game_sched.json', 4817270 => 'game_nassr.json', _ => 'game.json' },
        '/game/stats/' => 'stats.json',
        '/games/h2h/' => q['gameId'] == 4750836 ? 'h2h_sched.json' : 'h2h.json',
        '/standings/' => q['competitions'] == 11 ? (q['type'] == 2 ? 'standings_laliga_home.json' : 'standings_laliga.json') : 'standings.json',
        '/games/results/' => 'team_results.json',
        '/games/fixtures/' => 'team_fixtures.json',
        '/squads/' => 'squad.json',
        '/competitors/' => 'competitor.json',
        '/athletes/' => 'athlete.json',
        '/search/' => 'search.json',
        '/news/' => 'news.json',
        _ => throw Exception('no fixture for $path'),
      };
      return fixture(f);
    });

final _imgRe = RegExp(r'/(Competitors|Competitions|Countries|Athletes)/(\d+)$');

/// Offline image bytes for recorded logos (test/fixtures/img).
Uint8List? fixtureImage(String url) {
  String? path;
  if (url.startsWith('news:')) {
    path = 'test/fixtures/img/News_${url.substring(5)}.jpg';
  } else {
    final m = _imgRe.firstMatch(url);
    if (m != null) path = 'test/fixtures/img/${m.group(1)}_${m.group(2)}.png';
  }
  if (path == null) return null;
  final f = File(path);
  return f.existsSync() ? f.readAsBytesSync() : null;
}

Future<void> loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    inter.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Inter-$w.ttf').readAsBytesSync())));
  }
  await inter.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}
