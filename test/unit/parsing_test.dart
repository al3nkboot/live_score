import 'package:flutter_test/flutter_test.dart';
import 'package:live_score/v2/data/models.dart';

import '../helpers.dart';

void main() {
  test('allscores games parse with leagues and live badge', () {
    final r = parseGames(fixture('games.json'));
    expect(r.games, isNotEmpty);
    expect(r.leagues, isNotEmpty);
    final g = r.games.first;
    expect(g.home.name, isNotEmpty);
    expect(g.id, greaterThan(0));
    for (final x in r.games.where((g) => g.isLive)) {
      expect(x.liveBadge, isNotEmpty);
    }
  });

  test('game details: events, lineups with positions and ratings', () {
    final d = MatchDetails.fromJson(fixture('game.json'));
    expect(d.game.home.name, 'Como');
    expect(d.events.any((e) => e.isSub), isTrue);
    final sub = d.events.firstWhere((e) => e.isSub);
    expect(d.playerName(sub.playerId), isNotEmpty);
    expect(d.homeLineup!.starters, hasLength(11));
    expect(d.homeLineup!.formation, '4-1-4-1');
    expect(d.homeLineup!.hasPositions, isTrue);
    expect(d.homeLineup!.hasRatings, isTrue);
    expect(d.homeLineup!.starters.first.number, greaterThanOrEqualTo(0));
    expect(d.venue, isNotEmpty);
  });

  test('stats pair home/away and compute share', () {
    final d = MatchDetails.fromJson(fixture('game.json'));
    final s = parseStats(fixture('stats.json'), d.game.home.id, d.game.away.id);
    final poss = s.firstWhere((x) => x.name == 'Possession');
    expect(poss.home, '66%');
    expect(poss.homeShare, closeTo(.66, .02));
    expect(s.any((x) => x.name == 'Expected Goals'), isTrue);
  });

  test('standings, squad, athlete, search', () {
    final t = parseStandings(fixture('standings.json'));
    expect(t.first.rows.first.position, 1);
    expect(t.first.rows.first.points, greaterThan(0));
    expect(parseSquad(fixture('squad.json')), isNotEmpty);
    final a = parseAthlete(fixture('athlete.json'))!;
    expect(a.name, 'Jean Butez');
    expect(a.seasonStats, isNotEmpty);
    final s = parseSearch(fixture('search.json'));
    expect(s.teams.any((t) => t.name.contains('Arsenal')), isTrue);
  });

  test('team results/fixtures parse', () {
    expect(parseGames(fixture('team_results.json')).games.every((g) => g.isEnded || g.statusGroup != 2), isTrue);
    expect(parseGames(fixture('team_fixtures.json')).games, isNotEmpty);
  });
}
