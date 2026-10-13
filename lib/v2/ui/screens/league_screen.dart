import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/standings_table.dart';

class LeagueScreen extends StatefulWidget {
  final League league;
  const LeagueScreen({super.key, required this.league});
  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  late final _table = ScoresApi.instance.standings(widget.league.id);
  late final _fx = ScoresApi.instance.leagueFixtures(widget.league.id);
  late final _rs = ScoresApi.instance.leagueResults(widget.league.id);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l = widget.league;
    Widget games(Future<GamesResult> f, bool desc) => Loader<GamesResult>(
          future: f,
          builder: (c, r) {
            final g = [...r.games]..sort((a, b) => desc ? b.startTime.compareTo(a.startTime) : a.startTime.compareTo(b.startTime));
            return g.isEmpty ? const EmptyNote('No matches') : ListView(padding: const EdgeInsets.only(top: 6, bottom: 24), children: [SectionCard(children: [for (final x in g) MatchTile(x, showDate: true)])]);
          },
        );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [Logo.league(l.id, l.name, size: 26), const SizedBox(width: 10), Expanded(child: Text(l.name, overflow: TextOverflow.ellipsis))]),
          actions: [StarButton(on: store.isLeague(l.id), onTap: () => store.toggleLeague(l))],
          bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Table'), Tab(text: 'Fixtures'), Tab(text: 'Results')]),
        ),
        body: TabBarView(children: [
          Loader<List<StandingsTable>>(
            future: _table,
            builder: (c, t) => t.isEmpty ? const EmptyNote('No table for this competition') : StandingsView(competitionId: widget.league.id, initial: t, highlight: store.teams.keys.toSet()),
          ),
          games(_fx, false),
          games(_rs, true),
        ]),
      ),
    );
  }
}
