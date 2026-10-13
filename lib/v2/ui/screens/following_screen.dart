import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/search_picker.dart';
import 'league_screen.dart';
import 'team_screen.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});
  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  late Future<List<Game>> _f;
  Set<int> _loadedFor = {};

  Future<List<Game>> _load(Set<int> teams) async {
    final out = <int, Game>{};
    for (final id in teams.take(12)) {
      try {
        for (final g in (await ScoresApi.instance.teamFixtures(id)).games.where((g) => !g.isEnded).take(1)) {
          out[g.id] = g;
        }
      } catch (_) {}
    }
    return out.values.toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final ids = store.teams.keys.toSet();
    if (ids.length != _loadedFor.length || !ids.containsAll(_loadedFor)) {
      _loadedFor = ids;
      _f = _load(ids);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Following'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => showSearchPicker(context))]),
      body: store.teams.isEmpty && store.leagues.isEmpty
          ? ListView(children: [
              const EmptyNote('Follow teams and leagues to see them here', icon: Icons.star_outline_rounded),
              Center(child: FilledButton.icon(onPressed: () => showSearchPicker(context), icon: const Icon(Icons.search), label: const Text('Find teams'))),
            ])
          : ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              if (store.teams.isNotEmpty)
                SectionCard(header: const _H('Teams'), children: [
                  SizedBox(
                    height: 104,
                    child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), children: [
                      for (final t in store.teams.values)
                        InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamScreen(team: t))),
                          child: SizedBox(
                            width: 84,
                            child: Column(children: [
                              const SizedBox(height: 8),
                              Logo.team(t, size: 44),
                              const SizedBox(height: 6),
                              Text(t.display, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ]),
              if (store.teams.isNotEmpty)
                Loader<List<Game>>(
                  future: _f,
                  builder: (c, g) => g.isEmpty ? const SizedBox() : SectionCard(header: const _H('Next matches'), children: [for (final x in g) MatchTile(x, showDate: true)]),
                ),
              if (store.leagues.isNotEmpty)
                SectionCard(header: const _H('Leagues'), children: [
                  for (final l in store.leagues.values)
                    ListTile(
                      leading: Logo.league(l.id, l.name, size: 26),
                      title: Text(l.name),
                      trailing: StarButton(on: true, onTap: () => store.toggleLeague(l)),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeagueScreen(league: l))),
                    ),
                ]),
              if (store.teams.isNotEmpty)
                SectionCard(header: const _H('Team notifications'), children: [
                  for (final t in store.teams.values)
                    SwitchListTile(
                      secondary: Logo.team(t, size: 24),
                      title: Text(t.name),
                      value: store.teamNotifs(t.id),
                      onChanged: (v) => store.setTeamNotifs(t.id, v),
                    ),
                ]),
            ]),
    );
  }
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)));
}
