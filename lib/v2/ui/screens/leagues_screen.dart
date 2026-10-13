import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/search_picker.dart';
import 'league_screen.dart';

/// Suggested top competitions (365scores ids, from the original app).
const suggestedLeagueIds = [7, 11, 17, 25, 35, 572, 573, 5930, 649, 552, 73, 57];

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});
  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  late Future<List<League>> _f = ScoresApi.instance.popularLeagues();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Leagues'), actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => showSearchPicker(context)),
      ]),
      body: Loader<List<League>>(
        future: _f,
        onRetry: () => setState(() => _f = ScoresApi.instance.popularLeagues()),
        builder: (c, all) {
          final top = all.take(60).toList();
          Widget tile(League l) => ListTile(
                leading: Logo.league(l.id, l.name, size: 26),
                title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: l.countryName.isEmpty ? null : Text(l.countryName),
                trailing: StarButton(on: store.isLeague(l.id), onTap: () => store.toggleLeague(l)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeagueScreen(league: l))),
              );
          return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            if (store.leagues.isNotEmpty)
              SectionCard(header: const _H('Following'), children: [for (final l in store.leagues.values) tile(l)]),
            SectionCard(header: const _H('Popular'), children: [for (final l in top) tile(l)]),
          ]);
        },
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)));
}
