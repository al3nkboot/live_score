import 'package:flutter_test/flutter_test.dart';
import 'package:live_score/v2/data/models.dart';
import 'package:live_score/v2/ui/widgets/standings_table.dart';
import 'package:live_score/v2/core/theme.dart';

import '../helpers.dart';

void main() {
  test('scheduled game: venue, capacity, TV, poll, injuries, predicted lineup without ratings', () {
    final d = MatchDetails.fromJson(fixture('game_sched.json'));
    expect(d.game.isScheduled, isTrue);
    expect(d.venue, 'Estadio Ciudad de Valencia');
    expect(d.capacity, 25534);
    expect(d.tvNetworks, contains('beIN Sports 5 HD'));
    expect(d.prediction, isNotNull);
    expect(d.prediction!.percentages.whereType<int>().fold<int>(0, (a, b) => a + b), inInclusiveRange(98, 102));
    expect(d.injuries, isNotEmpty);
    expect(d.injuries.first.reason, isNotEmpty);
    expect(d.lineupStatus, isNot('Confirmed'));
    expect(d.homeLineup!.starters, hasLength(11));
    expect(d.homeLineup!.hasRatings, isFalse);
  });

  test('allscores TV flag and league title', () {
    final r = parseGames(fixture('games_oct12.json'));
    expect(r.games.any((g) => g.hasTv), isTrue);
    expect(r.leagues[7]!.title, 'England - Premier League');
    expect(r.leagues[623]!.isInternational, isTrue);
  });

  test('standings destinations, filters and form order (oldest -> newest)', () {
    final t = parseStandings(fixture('standings_laliga.json')).first;
    expect(t.filters.map((f) => f.$2), ['Overall', 'Home', 'Away']);
    expect(t.destinations, isNotEmpty);
    final top = t.rows.first;
    expect(zoneColor(t.destinations[top.destination]), AppPalette.ucl);
    final rm = t.rows.firstWhere((r) => r.team.name == 'Real Madrid');
    expect(rm.form, [0, 1, 1, 0, 1]); // API newest-first [1,0,1,1,0] reversed
    final rel = t.rows.last;
    expect(zoneColor(t.destinations[rel.destination]), AppPalette.relegation);
  });

  test('news parse', () {
    final n = parseNews(fixture('news.json'));
    expect(n, hasLength(3));
    expect(n.first.source, '365Scores Magazine');
    expect(n.first.url, startsWith('https://'));
  });
}
