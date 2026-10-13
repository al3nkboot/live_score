import 'package:dio/dio.dart';

import 'models.dart';

/// Fetches raw JSON for a path + query. Swappable in tests (fixtures).
typedef JsonFetcher = Future<Map<String, dynamic>> Function(String path, Map<String, dynamic> query);

/// Client for the public 365scores web API (https://webws.365scores.com/web).
class ScoresApi {
  static ScoresApi instance = ScoresApi();

  static const baseUrl = 'https://webws.365scores.com/web';
  static const img = 'https://imagecache.365scores.com/image/upload/';

  /// 1 = English, 27 = Arabic.
  int langId = 1;

  /// Country used by 365scores for TV listings (117 = Oman).
  int userCountryId = 117;
  final JsonFetcher _fetch;
  final Map<String, (DateTime, Map<String, dynamic>)> _cache = {};

  ScoresApi({JsonFetcher? fetcher}) : _fetch = fetcher ?? _dioFetcher();

  static JsonFetcher _dioFetcher() {
    final dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20)));
    return (path, q) async {
      final r = await dio.get<Map<String, dynamic>>(path, queryParameters: q);
      return r.data ?? {};
    };
  }

  static String tzName() {
    final h = DateTime.now().timeZoneOffset.inMinutes;
    const m = {
      -600: 'Pacific/Honolulu', -480: 'America/Los_Angeles', -420: 'America/Denver', -360: 'America/Chicago',
      -300: 'America/New_York', -240: 'America/Halifax', -180: 'America/Argentina/Buenos_Aires', 0: 'UTC',
      60: 'Europe/Paris', 120: 'Africa/Cairo', 180: 'Asia/Riyadh', 240: 'Asia/Dubai', 270: 'Asia/Kabul',
      300: 'Asia/Karachi', 330: 'Asia/Kolkata', 360: 'Asia/Dhaka', 420: 'Asia/Bangkok', 480: 'Asia/Singapore',
      540: 'Asia/Tokyo', 600: 'Australia/Sydney', 720: 'Pacific/Auckland',
    };
    return m[h] ?? 'UTC';
  }

  Future<Map<String, dynamic>> get(String path, Map<String, dynamic> q, {Duration ttl = const Duration(seconds: 20)}) async {
    final query = {'appTypeId': 5, 'langId': langId, 'timezoneName': tzName(), 'userCountryId': userCountryId, ...q};
    final key = '$path?$query';
    final c = _cache[key];
    if (c != null && DateTime.now().difference(c.$1) < ttl) return c.$2;
    final data = await _fetch(path, query);
    _cache[key] = (DateTime.now(), data);
    return data;
  }

  static String _d(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// All football games on a local day.
  Future<GamesResult> gamesOn(DateTime day) async =>
      parseGames(await get('/games/allscores/', {'sports': 1, 'startDate': _d(day), 'endDate': _d(day), 'showOdds': false}));

  Future<MatchDetails> game(int id) async => MatchDetails.fromJson(await get('/game/', {'gameId': id}, ttl: const Duration(seconds: 15)));

  Future<Map<String, dynamic>> gameStatsRaw(int id) => get('/game/stats/', {'games': id});

  /// Head-to-head games (from /games/h2h/).
  Future<List<Game>> h2h(int gameId) async {
    final r = await get('/games/h2h/', {'gameId': gameId}, ttl: const Duration(minutes: 30));
    final g = r['game'];
    if (g is! Map || g['h2hGames'] is! List) return [];
    return (g['h2hGames'] as List).whereType<Map>().map((e) => Game.fromJson(Map<String, dynamic>.from(e))).where((x) => x.isEnded).toList();
  }

  /// type: 1 overall, 2 home, 3 away.
  Future<List<StandingsTable>> standings(int competitionId, {int type = 1}) async =>
      parseStandings(await get('/standings/', {'competitions': competitionId, if (type != 1) 'type': type}, ttl: const Duration(minutes: 5)));

  Future<List<NewsItem>> news() async => parseNews(await get('/news/', {'sports': 1}, ttl: const Duration(minutes: 10)));

  Future<GamesResult> teamResults(int teamId) async => parseGames(await get('/games/results/', {'competitors': teamId}, ttl: const Duration(minutes: 5)));
  Future<GamesResult> teamFixtures(int teamId) async => parseGames(await get('/games/fixtures/', {'competitors': teamId}, ttl: const Duration(minutes: 5)));
  Future<GamesResult> leagueResults(int id) async => parseGames(await get('/games/results/', {'competitions': id}, ttl: const Duration(minutes: 5)));
  Future<GamesResult> leagueFixtures(int id) async => parseGames(await get('/games/fixtures/', {'competitions': id}, ttl: const Duration(minutes: 5)));

  Future<List<SquadPlayer>> squad(int teamId) async => parseSquad(await get('/squads/', {'competitors': teamId}, ttl: const Duration(hours: 6)));

  Future<Map<String, dynamic>> teamInfoRaw(int teamId) => get('/competitors/', {'competitors': teamId}, ttl: const Duration(hours: 6));

  Future<Athlete?> athlete(int id) async => parseAthlete(await get('/athletes/', {'athletes': id, 'fullDetails': true}, ttl: const Duration(hours: 1)));

  Future<SearchResult> search(String q) async => parseSearch(await get('/search/', {'query': q, 'filter': 'all'}, ttl: const Duration(minutes: 10)));

  Future<List<League>> popularLeagues() async {
    final r = await get('/competitions/', {'sports': 1}, ttl: const Duration(hours: 12));
    final c = parseCountries(r);
    final l = ((r['competitions'] as List?) ?? []).whereType<Map>().map((e) => League.fromJson(Map<String, dynamic>.from(e), c)).toList();
    l.sort((a, b) => b.popularity.compareTo(a.popularity));
    return l;
  }

  static String teamLogo(int id, {int size = 64}) =>
      '${img}f_png,w_$size,h_$size,c_limit,q_auto:eco,dpr_2,d_Competitors:default1.png/Competitors/$id';
  static String leagueLogo(int id, {int size = 64}) =>
      '${img}f_png,w_$size,h_$size,c_limit,q_auto:eco,dpr_2,d_Countries:default1.png/Competitions/$id';
  static String countryFlag(int id, {int size = 64}) =>
      '${img}f_png,w_$size,h_$size,c_limit,q_auto:eco,dpr_2,d_Countries:default1.png/Countries/$id';
  static String playerPhoto(int id, {int size = 96}) =>
      '${img}f_png,w_$size,h_$size,c_limit,q_auto:eco,dpr_2,d_Athletes:default1.png/Athletes/$id';
}
