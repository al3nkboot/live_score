import 'package:flutter_test/flutter_test.dart';
import 'package:live_score/v2/data/models.dart';
import 'package:live_score/v2/notify/diff.dart';

Game g({int status = 3, String short = '1st Half', double h = 0, double a = 0, int rh = 0, int ra = 0}) => Game(
    id: 1, competitionId: 7, competitionName: 'PL', startTime: DateTime(2026), statusGroup: status, statusText: short, shortStatus: short,
    gameTime: 10, gameTimeDisplay: "10'", home: Team(id: 1, name: 'Home', score: h), away: Team(id: 2, name: 'Away', score: a), redHome: rh, redAway: ra);

List<AlertKind> kinds(GameSnapshot? p, Game n) => diffGame(p, n).map((e) => e.kind).toList();

void main() {
  test('first sight produces nothing', () => expect(kinds(null, g()), isEmpty));
  test('kick-off', () => expect(kinds(GameSnapshot.of(g(status: 2, short: 'Sched.', h: -1, a: -1)), g()), [AlertKind.kickoff]));
  test('goal home and away', () {
    final a = diffGame(GameSnapshot.of(g()), g(h: 1, a: 1));
    expect(a.map((e) => e.kind), [AlertKind.goal, AlertKind.goal]);
    expect(a.first.title, contains('Home'));
    expect(a.first.body, 'Home 1 - 1 Away');
  });
  test('disallowed goal', () => expect(diffGame(GameSnapshot.of(g(h: 1)), g()).single.title, 'Goal disallowed'));
  test('half-time once', () {
    expect(kinds(GameSnapshot.of(g()), g(short: 'HT')), [AlertKind.halftime]);
    expect(kinds(GameSnapshot.of(g(short: 'HT')), g(short: 'HT')), isEmpty);
  });
  test('full-time with late goal', () => expect(kinds(GameSnapshot.of(g(h: 1)), g(status: 4, short: 'Ended', h: 2)), [AlertKind.goal, AlertKind.fulltime]));
  test('red card', () => expect(kinds(GameSnapshot.of(g()), g(ra: 1)), [AlertKind.red]));
  test('snapshot json roundtrip', () {
    final s = GameSnapshot.of(g(h: 2, a: 1, rh: 1));
    final r = GameSnapshot.fromJson(s.toJson());
    expect([r.home, r.away, r.redHome, r.status], [2, 1, 1, '1st Half']);
  });
}
