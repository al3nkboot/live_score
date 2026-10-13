import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../screens/league_screen.dart';
import '../screens/team_screen.dart';
import 'common.dart';

Future<void> showSearchPicker(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchPickerScreen()));

/// Search teams & leagues with star toggles (used by onboarding and Leagues tab).
class SearchPicker extends StatefulWidget {
  final bool openOnTap;
  const SearchPicker({super.key, this.openOnTap = true});
  @override
  State<SearchPicker> createState() => _SearchPickerState();
}

class _SearchPickerState extends State<SearchPicker> {
  final _c = TextEditingController();
  Timer? _deb;
  Future<SearchResult>? _f;

  void _changed(String q) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _f = q.trim().length < 2 ? null : ScoresApi.instance.search(q.trim()));
    });
  }

  @override
  void dispose() {
    _deb?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: TextField(
          controller: _c,
          onChanged: _changed,
          decoration: InputDecoration(
            hintText: 'Search teams or leagues',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: _f == null
            ? ListView(children: [
                for (final t in store.teams.values)
                  ListTile(leading: Logo.team(t, size: 26), title: Text(t.name), trailing: StarButton(on: true, onTap: () => store.toggleTeam(t))),
                for (final l in store.leagues.values)
                  ListTile(leading: Logo.league(l.id, l.name, size: 26), title: Text(l.name), trailing: StarButton(on: true, onTap: () => store.toggleLeague(l))),
                if (store.teams.isEmpty && store.leagues.isEmpty) const EmptyNote('Type at least 2 letters', icon: Icons.search),
              ])
            : Loader<SearchResult>(
                future: _f!,
                builder: (c, r) => ListView(children: [
                  for (final l in r.leagues)
                    ListTile(
                      leading: Logo.league(l.id, l.name, size: 26),
                      title: Text(l.name),
                      subtitle: Text(l.countryName.isEmpty ? 'League' : 'League · ${l.countryName}'),
                      onTap: widget.openOnTap ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeagueScreen(league: l))) : () => store.toggleLeague(l),
                      trailing: StarButton(on: store.isLeague(l.id), onTap: () => store.toggleLeague(l)),
                    ),
                  for (final t in r.teams)
                    ListTile(
                      leading: Logo.team(t, size: 26),
                      title: Text(t.name),
                      subtitle: const Text('Team'),
                      onTap: widget.openOnTap ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamScreen(team: t))) : () => store.toggleTeam(t),
                      trailing: StarButton(on: store.isTeam(t.id), onTap: () => store.toggleTeam(t)),
                    ),
                  if (r.leagues.isEmpty && r.teams.isEmpty) const EmptyNote('No results'),
                ]),
              ),
      ),
    ]);
  }
}

class SearchPickerScreen extends StatelessWidget {
  const SearchPickerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Search')), body: const SearchPicker());
}

