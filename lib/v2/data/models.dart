// Lightweight models for the public 365scores web API.
// ignore_for_file: public_member_api_docs

double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
int _i(dynamic v, [int def = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? def;
List<Map<String, dynamic>> _l(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

class Team {
  final int id;
  final String name;
  final String shortName;
  final int countryId;
  final double? score;
  final String? color;
  const Team({required this.id, required this.name, this.shortName = '', this.countryId = 0, this.score, this.color});
  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: _i(j['id']),
        name: '${j['name'] ?? ''}',
        shortName: '${j['shortName'] ?? j['symbolicName'] ?? j['name'] ?? ''}',
        countryId: _i(j['countryId']),
        score: _d(j['score']),
        color: j['color'] as String?,
      );
  String get display => shortName.isNotEmpty && name.length > 16 ? shortName : name;
  /// Compact name for tight rows.
  String get compact => shortName.isNotEmpty && name.length > 13 ? shortName : name;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'shortName': shortName, 'countryId': countryId};
}

class League {
  final int id;
  final String name;
  final int countryId;
  final String countryName;
  final bool hasStandings;
  final int popularity;
  final bool isInternational;
  const League({required this.id, required this.name, this.countryId = 0, this.countryName = '', this.hasStandings = false, this.popularity = 0, this.isInternational = false});
  /// FotMob-like header title: 'Country - League'.
  String get title => countryName.isEmpty || isInternational ? name : '$countryName - $name';
  factory League.fromJson(Map<String, dynamic> j, [Map<int, String> countries = const {}]) => League(
        id: _i(j['id']),
        name: '${j['name'] ?? ''}',
        countryId: _i(j['countryId']),
        countryName: countries[_i(j['countryId'])] ?? '',
        hasStandings: j['hasStandings'] == true,
        popularity: _i(j['popularityRank']),
        isInternational: j['isInternational'] == true,
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'countryId': countryId};
}

/// statusGroup: 2 scheduled, 3 live, 4 ended/other.
class Game {
  final int id;
  final int competitionId;
  final String competitionName;
  final DateTime startTime;
  final int statusGroup;
  final String statusText;
  final String shortStatus;
  final double gameTime;
  final String gameTimeDisplay;
  final Team home;
  final Team away;
  final int seasonNum;
  final int stageNum;
  final String roundName;
  final int roundNum;
  final int? redHome;
  final int? redAway;
  final bool hasTv;
  const Game({
    required this.id,
    required this.competitionId,
    required this.competitionName,
    required this.startTime,
    required this.statusGroup,
    required this.statusText,
    required this.shortStatus,
    required this.gameTime,
    required this.gameTimeDisplay,
    required this.home,
    required this.away,
    this.seasonNum = 0,
    this.stageNum = 0,
    this.roundName = '',
    this.roundNum = 0,
    this.redHome,
    this.redAway,
    this.hasTv = false,
  });
  factory Game.fromJson(Map<String, dynamic> j) {
    final h = Map<String, dynamic>.from(j['homeCompetitor'] ?? {});
    final a = Map<String, dynamic>.from(j['awayCompetitor'] ?? {});
    return Game(
      id: _i(j['id']),
      competitionId: _i(j['competitionId']),
      competitionName: '${j['competitionDisplayName'] ?? ''}',
      startTime: DateTime.tryParse('${j['startTime']}')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0),
      statusGroup: _i(j['statusGroup']),
      statusText: '${j['statusText'] ?? ''}',
      shortStatus: '${j['shortStatusText'] ?? ''}',
      gameTime: _d(j['gameTime']) ?? -1,
      gameTimeDisplay: '${j['gameTimeDisplay'] ?? ''}',
      home: Team.fromJson(h),
      away: Team.fromJson(a),
      seasonNum: _i(j['seasonNum']),
      stageNum: _i(j['stageNum']),
      roundName: '${j['roundName'] ?? ''}',
      roundNum: _i(j['roundNum']),
      redHome: h['redCards'] == null ? null : _i(h['redCards']),
      redAway: a['redCards'] == null ? null : _i(a['redCards']),
      hasTv: j['hasTVNetworks'] == true || (j['tvNetworks'] is List && (j['tvNetworks'] as List).isNotEmpty),
    );
  }
  bool get isLive => statusGroup == 3;
  bool get isScheduled => statusGroup == 2;
  bool get isEnded => statusGroup == 4;
  bool get hasScore => (home.score ?? -1) >= 0 && !isScheduled;
  String get scoreText => hasScore ? '${home.score!.toInt()} - ${away.score!.toInt()}' : '';
  /// Badge text for a live match: minute (e.g. 67') or HT.
  String get liveBadge {
    if (shortStatus == 'HT') return 'HT';
    if (gameTimeDisplay.isNotEmpty) return gameTimeDisplay;
    if (gameTime >= 0) return "${gameTime.toInt()}'";
    return shortStatus;
  }
}

/// Event types: 1 goal, 2 yellow, 3 red, 1000 substitution, others ignored/shown generic.
class MatchEvent {
  final int teamId;
  final int typeId;
  final String typeName;
  final String subType;
  final double minute;
  final int addedTime;
  final String timeDisplay;
  final int? playerId;
  final List<int> extraPlayers;
  final int order;
  const MatchEvent({required this.teamId, required this.typeId, required this.typeName, this.subType = '', required this.minute, this.addedTime = 0, this.timeDisplay = '', this.playerId, this.extraPlayers = const [], this.order = 0});
  factory MatchEvent.fromJson(Map<String, dynamic> j) {
    final t = Map<String, dynamic>.from(j['eventType'] ?? {});
    return MatchEvent(
      teamId: _i(j['competitorId']),
      typeId: _i(t['id']),
      typeName: '${t['name'] ?? ''}',
      subType: '${t['subTypeName'] ?? ''}',
      minute: _d(j['gameTime']) ?? 0,
      addedTime: _i(j['addedTime']),
      timeDisplay: '${j['gameTimeDisplay'] ?? ''}',
      playerId: j['playerId'] == null ? null : _i(j['playerId']),
      extraPlayers: (j['extraPlayers'] is List) ? (j['extraPlayers'] as List).map((e) => _i(e)).toList() : const [],
      order: _i(j['order']),
    );
  }
  bool get isGoal => typeId == 1;
  bool get isYellow => typeId == 2;
  bool get isRed => typeId == 3;
  bool get isSub => typeId == 1000;
}

class LineupPlayer {
  final int memberId;
  final int athleteId;
  final String name;
  final String shortName;
  final int number;
  final bool starting;
  final String position;
  final double? rating;
  final bool topRated;
  /// yard position, 0..100 (fieldLine: depth from own goal, fieldSide: across).
  final double? fieldLine;
  final double? fieldSide;
  final int line;
  final Map<String, String> stats;
  const LineupPlayer({required this.memberId, required this.athleteId, required this.name, required this.shortName, required this.number, required this.starting, this.position = '', this.rating, this.topRated = false, this.fieldLine, this.fieldSide, this.line = 0, this.stats = const {}});
}

class TeamLineup {
  final String formation;
  final String status;
  final List<LineupPlayer> players;
  const TeamLineup({required this.formation, required this.status, required this.players});
  List<LineupPlayer> get starters => players.where((p) => p.starting).toList();
  List<LineupPlayer> get bench => players.where((p) => !p.starting).toList();
  bool get hasPositions => starters.isNotEmpty && starters.every((p) => p.fieldLine != null);
  bool get hasRatings => players.any((p) => p.rating != null);
}

class Member {
  final int id;
  final int athleteId;
  final int teamId;
  final String name;
  final String shortName;
  final int number;
  const Member(this.id, this.athleteId, this.teamId, this.name, this.shortName, this.number);
}

class StatLine {
  final int id;
  final String name;
  final String category;
  final String home;
  final String away;
  final double homeShare; // 0..1
  const StatLine({required this.id, required this.name, required this.category, required this.home, required this.away, required this.homeShare});
}

class MatchDetails {
  final Game game;
  final List<MatchEvent> events;
  final Map<int, Member> members;
  final TeamLineup? homeLineup;
  final TeamLineup? awayLineup;
  final String venue;
  final String? referee;
  final bool hasStandings;
  final List<Map<String, dynamic>> stages;
  final int? capacity;
  final List<String> tvNetworks;
  final Prediction? prediction;
  final List<Injury> injuries;
  final String lineupStatus;
  const MatchDetails({required this.game, required this.events, required this.members, this.homeLineup, this.awayLineup, this.venue = '', this.referee, this.hasStandings = false, this.stages = const [], this.capacity, this.tvNetworks = const [], this.prediction, this.injuries = const [], this.lineupStatus = ''});

  factory MatchDetails.fromJson(Map<String, dynamic> root) {
    final g = Map<String, dynamic>.from(root['game'] ?? {});
    final members = <int, Member>{};
    for (final m in _l(g['members'])) {
      members[_i(m['id'])] = Member(_i(m['id']), _i(m['athleteId']), _i(m['competitorId']), '${m['name'] ?? ''}', '${m['shortName'] ?? m['name'] ?? ''}', _i(m['jerseyNumber'], -1));
    }
    final injuries0 = <Injury>[];
    TeamLineup? lu(Map? comp) {
      final injuries = injuries0;
      final l = comp?['lineups'];
      if (l is! Map) return null;
      final players = <LineupPlayer>[];
      for (final p in _l(l['members']).where((p) => _i(p['status']) == 1 || _i(p['status']) == 2)) {
        final id = _i(p['id']);
        final mem = members[id];
        final yard = p['yardFormation'] is Map ? Map<String, dynamic>.from(p['yardFormation']) : null;
        final st = <String, String>{};
        for (final s in _l(p['stats'])) {
          st['${s['name']}'] = '${s['value']}';
        }
        players.add(LineupPlayer(
          memberId: id,
          athleteId: mem?.athleteId ?? _i(p['athleteId']),
          name: mem?.name ?? '',
          shortName: mem?.shortName ?? '',
          number: mem?.number ?? -1,
          starting: _i(p['status']) == 1,
          position: '${(p['formation'] ?? p['position'] ?? {})['shortName'] ?? (p['position'] ?? {})['name'] ?? ''}',
          rating: _i(g['statusGroup']) == 2 ? null : _d(p['ranking']),
          topRated: p['hasHighestRanking'] == true,
          fieldLine: yard == null ? null : _d(yard['fieldLine']),
          fieldSide: yard == null ? null : _d(yard['fieldSide']),
          line: yard == null ? 0 : _i(yard['line']),
          stats: st,
        ));
      }
      for (final p in _l(l['members'])) {
        final st = _i(p['status']);
        if (st == 3 || st == 5) {
          final mem = members[_i(p['id'])];
          final inj = p['injury'] is Map ? Map<String, dynamic>.from(p['injury']) : (p['suspension'] is Map ? Map<String, dynamic>.from(p['suspension']) : <String, dynamic>{});
          injuries.add(Injury(teamId: _i(comp?['id']), athleteId: mem?.athleteId ?? 0, name: mem?.name ?? '', doubtful: st == 5,
              reason: '${inj['reason'] ?? p['statusText'] ?? ''}', expectedReturn: '${inj['expectedReturn'] ?? ''}'));
        }
      }
      if (players.isEmpty) return null;
      return TeamLineup(formation: '${l['formation'] ?? ''}', status: '${l['status'] ?? ''}', players: players);
    }

    final hl = lu(g['homeCompetitor'] as Map?);
    final al = lu(g['awayCompetitor'] as Map?);
    final officials = _l(g['officials']);
    final venue = g['venue'] is Map ? '${g['venue']['name'] ?? ''}' : '';
    return MatchDetails(
      game: Game.fromJson(g),
      events: _l(g['events']).map(MatchEvent.fromJson).toList()..sort((a, b) => a.order.compareTo(b.order)),
      members: members,
      homeLineup: hl,
      awayLineup: al,
      capacity: g['venue'] is Map && g['venue']['capacity'] != null ? _i(g['venue']['capacity']) : null,
      tvNetworks: _l(g['tvNetworks']).map((t) => '${t['name'] ?? ''}').where((t) => t.isNotEmpty).toSet().toList(),
      prediction: Prediction.parse(g['promotedPredictions']),
      injuries: injuries0,
      lineupStatus: '${(g['homeCompetitor']?['lineups'] ?? {})['status'] ?? ''}',
      venue: venue,
      referee: officials.isEmpty ? null : '${officials.first['name'] ?? ''}',
      hasStandings: g['hasStandings'] == true,
      stages: _l(g['stages']),
    );
  }
  String playerName(int? memberId) => memberId == null ? '' : (members[memberId]?.shortName ?? '');
}

/// Parses /game/stats/ into home/away comparison lines.
List<StatLine> parseStats(Map<String, dynamic> root, int homeId, int awayId) {
  final all = _l(root['statistics']);
  final byId = <int, Map<int, Map<String, dynamic>>>{};
  final order = <int>[];
  for (final s in all) {
    final id = _i(s['id']);
    if (!byId.containsKey(id)) order.add(id);
    byId.putIfAbsent(id, () => {})[_i(s['competitorId'])] = s;
  }
  final out = <StatLine>[];
  for (final id in order) {
    final m = byId[id]!;
    final h = m[homeId];
    final a = m[awayId];
    final any = h ?? a!;
    final hv = '${h?['value'] ?? '0'}';
    final av = '${a?['value'] ?? '0'}';
    double share;
    final hp = _d(h?['valuePercentage']);
    if (hp != null && a != null && _d(a['valuePercentage']) != null) {
      final ap = _d(a['valuePercentage'])!;
      share = (hp + ap) == 0 ? .5 : hp / (hp + ap);
    } else {
      final hn = _num(hv), an = _num(av);
      share = (hn + an) == 0 ? .5 : hn / (hn + an);
    }
    out.add(StatLine(id: id, name: '${any['name'] ?? ''}', category: '${any['categoryName'] ?? 'General'}', home: hv, away: av, homeShare: share));
  }
  return out;
}

double _num(String v) => double.tryParse(RegExp(r'[\d.]+').firstMatch(v)?.group(0) ?? '') ?? 0;

class StandingRow {
  final Team team;
  final int position;
  final int played, won, drawn, lost, goalsFor, goalsAgainst;
  final double points;
  final String group;
  final List<int> form; // 1 win, 2 draw, 0 loss; oldest -> newest
  final int? destination;
  const StandingRow({this.destination, required this.team, required this.position, required this.played, required this.won, required this.drawn, required this.lost, required this.goalsFor, required this.goalsAgainst, required this.points, this.group = '', this.form = const []});
  int get goalDiff => goalsFor - goalsAgainst;
}

class Destination {
  final int num;
  final String name;
  final int type;
  final String color;
  const Destination(this.num, this.name, this.type, this.color);
}

class StandingsTable {
  final int competitionId;
  final String name;
  final List<StandingRow> rows;
  final Map<int, Destination> destinations;
  final List<(int, String)> filters;
  const StandingsTable(this.competitionId, this.name, this.rows, {this.destinations = const {}, this.filters = const []});
}

List<StandingsTable> parseStandings(Map<String, dynamic> root) {
  return _l(root['standings']).map((s) {
    final groups = <int, String>{for (final g in _l(s['groups'])) _i(g['num']): '${g['name'] ?? ''}'};
    final rows = _l(s['rows']).map((r) {
      return StandingRow(
        team: Team.fromJson(Map<String, dynamic>.from(r['competitor'] ?? {})),
        position: _i(r['position']),
        played: _i(r['gamePlayed']),
        won: _i(r['gamesWon']),
        drawn: _i(r['gamesEven']),
        lost: _i(r['gamesLost']),
        goalsFor: _i(r['for']),
        goalsAgainst: _i(r['against']),
        points: _d(r['points']) ?? 0,
        group: groups[_i(r['groupNum'])] ?? '',
        form: _form(r),
        destination: r['destinationNum'] == null ? null : _i(r['destinationNum']),
      );
    }).toList();
    return StandingsTable(_i(s['competitionId']), '${s['displayName'] ?? ''}', rows,
        destinations: {for (final d in _l(s['destinations'])) _i(d['num']): Destination(_i(d['num']), '${d['name'] ?? ''}', _i(d['type']), '${d['color'] ?? ''}')},
        filters: _l(s['filterTypes']).map((f) => (_i(f['type']), '${f['name'] ?? ''}')).toList());
  }).toList();
}

class GamesResult {
  final List<Game> games;
  final Map<int, League> leagues;
  const GamesResult(this.games, this.leagues);
}

Map<int, String> parseCountries(Map<String, dynamic> root) =>
    {for (final c in _l(root['countries'])) _i(c['id']): '${c['name'] ?? ''}'};

GamesResult parseGames(Map<String, dynamic> root, {String key = 'games'}) {
  final countries = parseCountries(root);
  final leagues = {for (final c in _l(root['competitions'])) _i(c['id']): League.fromJson(c, countries)};
  final games = _l(root[key]).where((g) => g['sportId'] == null || _i(g['sportId']) == 1).map(Game.fromJson).toList();
  return GamesResult(games, leagues);
}

class SquadPlayer {
  final int id;
  final String name;
  final int number;
  final String position;
  final int age;
  const SquadPlayer(this.id, this.name, this.number, this.position, this.age);
}

List<SquadPlayer> parseSquad(Map<String, dynamic> root) {
  final sq = _l(root['squads']);
  if (sq.isEmpty) return [];
  return _l(sq.first['athletes'])
      .map((a) => SquadPlayer(_i(a['id']), '${a['name'] ?? ''}', _i(a['jerseyNum'], -1), '${(a['position'] ?? {})['name'] ?? ''}', _i(a['age'])))
      .toList();
}

class StatGroup {
  final String title;
  final List<MapEntry<String, String>> stats;
  const StatGroup(this.title, this.stats);
}

class Athlete {
  final int id;
  final String name;
  final String position;
  final int age;
  final int? number;
  final String nationality;
  final String bio;
  final int? clubId;
  final String clubName;
  final List<MapEntry<String, String>> details;
  final List<StatGroup> seasonStats;
  const Athlete({required this.id, required this.name, this.position = '', this.age = 0, this.number, this.nationality = '', this.bio = '', this.clubId, this.clubName = '', this.details = const [], this.seasonStats = const []});
}

Athlete? parseAthlete(Map<String, dynamic> root) {
  final list = _l(root['athletes']);
  if (list.isEmpty) return null;
  final a = list.first;
  final comps = {for (final c in _l(root['competitors'])) _i(c['id']): '${c['name'] ?? ''}'};
  return Athlete(
    id: _i(a['id']),
    name: '${a['name'] ?? ''}',
    position: '${(a['formationPosition'] ?? a['position'] ?? {})['name'] ?? ''}',
    age: _i(a['age']),
    number: a['jerseyNum'] == null ? null : _i(a['jerseyNum']),
    nationality: '${a['nationalityName'] ?? ''}',
    bio: '${a['shortBio'] ?? ''}',
    clubId: a['clubId'] == null ? null : _i(a['clubId']),
    clubName: comps[_i(a['clubId'])] ?? '',
    details: _l(a['playerDetails']).map((d) => MapEntry('${d['title'] ?? ''}', '${d['value'] ?? ''}')).toList(),
    seasonStats: _l(a['highlightStats'])
        .map((h) => StatGroup('${h['name'] ?? ''}', _l(h['stats']).map((s) => MapEntry('${s['name'] ?? ''}', '${s['value'] ?? ''}')).toList()))
        .where((g) => g.stats.isNotEmpty)
        .toList(),
  );
}

class SearchResult {
  final List<Team> teams;
  final List<League> leagues;
  const SearchResult(this.teams, this.leagues);
}

SearchResult parseSearch(Map<String, dynamic> root) {
  final countries = parseCountries(root);
  return SearchResult(
    _l(root['competitors']).where((c) => c['sportId'] == null || _i(c['sportId']) == 1).map(Team.fromJson).toList(),
    _l(root['competitions']).where((c) => c['sportId'] == null || _i(c['sportId']) == 1).map((c) => League.fromJson(c, countries)).toList(),
  );
}

class Injury {
  final int teamId;
  final int athleteId;
  final String name;
  final bool doubtful;
  final String reason;
  final String expectedReturn;
  const Injury({required this.teamId, required this.athleteId, required this.name, required this.doubtful, required this.reason, required this.expectedReturn});
}

/// 'Who will win?' poll from promotedPredictions (type 1).
class Prediction {
  final int id;
  final int totalVotes;
  final bool showVotes;
  /// percentages for home / draw / away (may be null when not provided).
  final List<int?> percentages;
  const Prediction(this.id, this.totalVotes, this.showVotes, this.percentages);
  static Prediction? parse(dynamic root) {
    if (root is! Map) return null;
    final p = _l(root['predictions']).where((p) => _i(p['type']) == 1).firstOrNull;
    if (p == null) return null;
    final opts = _l(p['options']);
    if (opts.length != 3) return null;
    return Prediction(_i(p['id']), _i(p['totalVotes']), p['showVotes'] == true,
        opts.map((o) => o['vote'] is Map && o['vote']['percentage'] != null ? _i(o['vote']['percentage']) : null).toList());
  }
}

class NewsItem {
  final int id;
  final String title;
  final String image;
  final String url;
  final String source;
  final DateTime published;
  const NewsItem(this.id, this.title, this.image, this.url, this.source, this.published);
}

List<NewsItem> parseNews(Map<String, dynamic> root) {
  final src = {for (final s in _l(root['newsSources'])) _i(s['id']): '${s['name'] ?? ''}'};
  return _l(root['news'])
      .map((n) => NewsItem(_i(n['id']), '${n['title'] ?? ''}', '${n['image'] ?? ''}', '${n['url'] ?? ''}', src[_i(n['sourceId'])] ?? '',
          DateTime.tryParse('${n['publishDate']}')?.toLocal() ?? DateTime.now()))
      .where((n) => n.title.isNotEmpty)
      .toList();
}

/// recentForm ordered oldest -> newest (uses detailedRecentForm dates when present).
List<int> _form(Map<String, dynamic> r) {
  final f = r['recentForm'] is List ? (r['recentForm'] as List).map((e) => _i(e)).toList() : <int>[];
  final d = _l(r['detailedRecentForm']);
  if (d.length >= 2) {
    final a = DateTime.tryParse('${d.first['startTime']}');
    final b = DateTime.tryParse('${d.last['startTime']}');
    if (a != null && b != null && a.isAfter(b)) return f.reversed.toList();
  }
  return f;
}
