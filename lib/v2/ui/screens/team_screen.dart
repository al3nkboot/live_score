import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/standings_table.dart';
import 'player_screen.dart';

class TeamScreen extends StatefulWidget {
  final Team team;
  const TeamScreen({super.key, required this.team});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamData {
  final List<Game> fixtures, results;
  final List<StandingsTable> table;
  final List<SquadPlayer> squad;
  final int? mainLeague;
  _TeamData(this.fixtures, this.results, this.table, this.squad, this.mainLeague);
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<_TeamData> _f = _load();

  Future<_TeamData> _load() async {
    final api = ScoresApi.instance;
    final id = widget.team.id;
    final r = await Future.wait<Object>([
      api.teamFixtures(id).then((x) => x.games).catchError((_) => <Game>[]),
      api.teamResults(id).then((x) => x.games).catchError((_) => <Game>[]),
      api.squad(id).catchError((_) => <SquadPlayer>[]),
      api.teamInfoRaw(id).catchError((_) => <String, dynamic>{}),
    ]);
    final info = r[3] as Map<String, dynamic>;
    final comps = info['competitors'];
    final int? main = comps is List && comps.isNotEmpty ? (comps.first['mainCompetitionId'] as num?)?.toInt() : null;
    var table = <StandingsTable>[];
    if (main != null) {
      try {
        table = (await api.standings(main)).where((t) => t.rows.any((x) => x.team.id == id)).toList();
      } catch (_) {}
    }
    final fx = (r[0] as List<Game>)..sort((a, b) => a.startTime.compareTo(b.startTime));
    final rs = (r[1] as List<Game>)..sort((a, b) => b.startTime.compareTo(a.startTime));
    return _TeamData(fx, rs, table, r[2] as List<SquadPlayer>, main);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final team = widget.team;
    final followed = store.isTeam(team.id);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(team.name),
          actions: [
            if (followed)
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => store.setTeamNotifs(team.id, !store.teamNotifs(team.id)),
                icon: Icon(store.teamNotifs(team.id) ? Icons.notifications_active_rounded : Icons.notifications_off_outlined),
              ),
            StarButton(on: followed, onTap: () => store.toggleTeam(team)),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Logo.team(team, size: 56),
              const SizedBox(width: 14),
              Expanded(child: Text(team.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            ]),
          ),
          const TabBar(isScrollable: true, tabs: [Tab(text: 'Overview'), Tab(text: 'Fixtures'), Tab(text: 'Results'), Tab(text: 'Table'), Tab(text: 'Squad')]),
          const Divider(),
          Expanded(
            child: Loader<_TeamData>(
              future: _f,
              onRetry: () => setState(() => _f = _load()),
              builder: (c, d) => TabBarView(children: [
                _overview(d),
                _games(d.fixtures, 'No upcoming fixtures'),
                _games(d.results, 'No results'),
                d.table.isEmpty || d.mainLeague == null ? const EmptyNote('No table available') : StandingsView(competitionId: d.mainLeague!, initial: d.table, highlight: {team.id}),
                _squad(d.squad),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _games(List<Game> g, String empty) =>
      g.isEmpty ? EmptyNote(empty) : ListView(padding: const EdgeInsets.only(top: 6, bottom: 24), children: [SectionCard(children: [for (final x in g) MatchTile(x, showDate: true)])]);

  Widget _overview(_TeamData d) {
    final id = widget.team.id;
    final row = d.table.expand((t) => t.rows).where((r) => r.team.id == id).firstOrNull;
    final next = d.fixtures.where((g) => !g.isEnded).firstOrNull;
    final form = d.results.where((g) => g.isEnded && g.hasScore).take(5).toList();
    String res(Game g) {
      final mine = g.home.id == id ? g.home.score! : g.away.score!;
      final other = g.home.id == id ? g.away.score! : g.home.score!;
      return mine > other ? 'W' : mine == other ? 'D' : 'L';
    }

    Color col(String r) => r == 'W' ? const Color(0xFF2BB673) : r == 'D' ? Colors.grey : const Color(0xFFE5534B);
    Widget stat(String v, String l) => Expanded(child: Column(children: [Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(l, style: const TextStyle(fontSize: 12))]));
    return ListView(padding: const EdgeInsets.only(top: 6, bottom: 24), children: [
      if (next != null) SectionCard(header: const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 0), child: Text('Next match', style: TextStyle(fontWeight: FontWeight.w800))), children: [MatchTile(next, showDate: true)]),
      if (form.isNotEmpty)
        SectionCard(padding: const EdgeInsets.all(12), children: [
          const Text('Form', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            for (final g in form.reversed)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: col(res(g)), borderRadius: BorderRadius.circular(8)),
                child: Text(res(g), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
          ]),
        ]),
      if (row != null)
        SectionCard(padding: const EdgeInsets.all(12), children: [
          Text('Season stats · ${d.table.first.name.isNotEmpty ? d.table.first.name : 'League'}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [stat('#${row.position}', 'Position'), stat(row.points.toStringAsFixed(0), 'Points'), stat('${row.played}', 'Played')]),
          const SizedBox(height: 12),
          Row(children: [stat('${row.won}-${row.drawn}-${row.lost}', 'W-D-L'), stat('${row.goalsFor}', 'Scored'), stat('${row.goalsAgainst}', 'Conceded')]),
        ]),
    ]);
  }

  Widget _squad(List<SquadPlayer> s) {
    if (s.isEmpty) return const EmptyNote('Squad not available');
    final groups = <String, List<SquadPlayer>>{};
    for (final p in s) {
      groups.putIfAbsent(p.position.isEmpty ? 'Other' : p.position, () => []).add(p);
    }
    return ListView(padding: const EdgeInsets.only(top: 6, bottom: 24), children: [
      for (final g in groups.entries)
        SectionCard(
          header: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: Text(g.key, style: const TextStyle(fontWeight: FontWeight.w800))),
          children: [
            for (final p in g.value)
              ListTile(
                dense: true,
                leading: Logo.player(p.id, p.name, size: 34),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text([if (p.number >= 0) '#${p.number}', if (p.age > 0) '${p.age} yrs'].join(' · ')),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(athleteId: p.id, name: p.name))),
              ),
          ],
        ),
    ]);
  }
}
