import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../data/models.dart';
import '../../notify/notifier.dart';
import '../widgets/common.dart';
import '../widgets/search_picker.dart';

/// Suggested picks (365scores ids).
const _suggestTeams = [
  Team(id: 131, name: 'Real Madrid'), Team(id: 132, name: 'Barcelona'), Team(id: 110, name: 'Manchester City'),
  Team(id: 108, name: 'Liverpool'), Team(id: 104, name: 'Arsenal'), Team(id: 105, name: 'Manchester United'),
  Team(id: 331, name: 'Bayern Munich'), Team(id: 480, name: 'Paris Saint-Germain'), Team(id: 224, name: 'Inter Milan'),
  Team(id: 226, name: 'Juventus'), Team(id: 8200, name: 'Al Ahly'), Team(id: 5457, name: 'Al Hilal'),
];
const _suggestLeagues = [
  League(id: 7, name: 'Premier League'), League(id: 11, name: 'LaLiga'), League(id: 572, name: 'Champions League'),
  League(id: 17, name: 'Serie A'), League(id: 25, name: 'Bundesliga'), League(id: 35, name: 'Ligue 1'), League(id: 649, name: 'Saudi Pro League'),
];

class OnboardingScreen extends StatelessWidget {
  final bool fromSettings;
  const OnboardingScreen({super.key, this.fromSettings = false});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Follow your favourites')),
      body: Column(children: [
        SizedBox(
          height: 200,
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            const Text('Popular leagues', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final l in _suggestLeagues)
                FilterChip(avatar: Logo.league(l.id, l.name, size: 18), label: Text(l.name), selected: store.isLeague(l.id), onSelected: (_) => store.toggleLeague(l)),
            ]),
            const SizedBox(height: 10),
            const Text('Popular teams', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final t in _suggestTeams)
                FilterChip(avatar: Logo.team(t, size: 18), label: Text(t.name), selected: store.isTeam(t.id), onSelected: (_) => store.toggleTeam(t)),
            ]),
          ]),
        ),
        const Divider(),
        const Expanded(child: SearchPicker(openOnTap: false)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await store.setOnboarded();
                  if (store.teams.isNotEmpty) await Notifier.requestPermission();
                  if (fromSettings && context.mounted) Navigator.of(context).pop();
                },
                child: Text(fromSettings ? 'Done' : 'Continue (${store.teams.length + store.leagues.length} selected)'),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
