import '../data/models.dart';

/// Minimal persisted state of a match used to detect changes between polls.
class GameSnapshot {
  final int id;
  final int statusGroup;
  final String status;
  final int home;
  final int away;
  final int redHome;
  final int redAway;
  const GameSnapshot(this.id, this.statusGroup, this.status, this.home, this.away, this.redHome, this.redAway);

  factory GameSnapshot.of(Game g) => GameSnapshot(g.id, g.statusGroup, g.shortStatus, (g.home.score ?? 0).clamp(0, 999).toInt(),
      (g.away.score ?? 0).clamp(0, 999).toInt(), g.redHome ?? 0, g.redAway ?? 0);

  Map<String, dynamic> toJson() => {'i': id, 'g': statusGroup, 's': status, 'h': home, 'a': away, 'rh': redHome, 'ra': redAway};
  factory GameSnapshot.fromJson(Map<String, dynamic> j) =>
      GameSnapshot(j['i'] as int, j['g'] as int, j['s'] as String, j['h'] as int, j['a'] as int, j['rh'] as int? ?? 0, j['ra'] as int? ?? 0);
}

enum AlertKind { kickoff, goal, halftime, fulltime, red }

class MatchAlert {
  final AlertKind kind;
  final Game game;
  final String title;
  final String body;
  const MatchAlert(this.kind, this.game, this.title, this.body);
  String get key => switch (kind) { AlertKind.kickoff => 'kickoff', AlertKind.goal => 'goal', AlertKind.halftime => 'halftime', AlertKind.fulltime => 'fulltime', AlertKind.red => 'red' };
}

/// Compares the previous snapshot with the current game and returns alerts.
/// No previous snapshot => no alerts (avoid spamming on first sight), except
/// nothing. Pure function; unit tested.
List<MatchAlert> diffGame(GameSnapshot? prev, Game now) {
  if (prev == null) return const [];
  final cur = GameSnapshot.of(now);
  final out = <MatchAlert>[];
  final h = now.home.name, a = now.away.name;
  final score = '$h ${cur.home} - ${cur.away} $a';
  if (prev.statusGroup == 2 && cur.statusGroup == 3) {
    out.add(MatchAlert(AlertKind.kickoff, now, 'Kick-off', '$h vs $a has started'));
  }
  if (cur.home > prev.home) {
    out.add(MatchAlert(AlertKind.goal, now, 'GOAL! $h', score));
  }
  if (cur.away > prev.away) {
    out.add(MatchAlert(AlertKind.goal, now, 'GOAL! $a', score));
  }
  if (cur.home < prev.home || cur.away < prev.away) {
    out.add(MatchAlert(AlertKind.goal, now, 'Goal disallowed', score));
  }
  if (cur.redHome > prev.redHome) out.add(MatchAlert(AlertKind.red, now, 'Red card – $h', score));
  if (cur.redAway > prev.redAway) out.add(MatchAlert(AlertKind.red, now, 'Red card – $a', score));
  if (prev.status != 'HT' && cur.status == 'HT') {
    out.add(MatchAlert(AlertKind.halftime, now, 'Half-time', score));
  }
  if (prev.statusGroup == 3 && cur.statusGroup == 4) {
    out.add(MatchAlert(AlertKind.fulltime, now, 'Full-time', score));
  }
  return out;
}
