import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import 'team_screen.dart';

class PlayerScreen extends StatefulWidget {
  final int athleteId;
  final String name;
  const PlayerScreen({super.key, required this.athleteId, required this.name});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late Future<Athlete?> _f = ScoresApi.instance.athlete(widget.athleteId);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Loader<Athlete?>(
        future: _f,
        onRetry: () => setState(() => _f = ScoresApi.instance.athlete(widget.athleteId)),
        builder: (c, a) {
          if (a == null) return const EmptyNote('Player not found');
          return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Logo.player(a.id, a.name, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    if (a.clubId != null && a.clubName.isNotEmpty)
                      InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamScreen(team: Team(id: a.clubId!, name: a.clubName)))),
                        child: Row(children: [Logo.team(Team(id: a.clubId!, name: a.clubName), size: 18), const SizedBox(width: 6), Text(a.clubName, style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w600))]),
                      ),
                  ]),
                ),
              ]),
            ),
            SectionCard(padding: const EdgeInsets.all(12), children: [
              Wrap(spacing: 24, runSpacing: 12, children: [
                if (a.position.isNotEmpty) _kv('Position', a.position),
                if (a.number != null && a.number! >= 0) _kv('Shirt', '${a.number}'),
                if (a.age > 0) _kv('Age', '${a.age}'),
                if (a.nationality.isNotEmpty) _kv('Country', a.nationality),
                for (final d in a.details) _kv(d.key, d.value),
              ]),
              if (a.bio.isNotEmpty) ...[const SizedBox(height: 12), Text(a.bio, style: TextStyle(color: t.hintColor))],
            ]),
            for (final g in a.seasonStats)
              SectionCard(
                padding: const EdgeInsets.all(12),
                header: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Season · ${g.title}', style: const TextStyle(fontWeight: FontWeight.w800))),
                children: [
                  for (final s in g.stats)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [Expanded(child: Text(s.key)), Text(s.value, style: const TextStyle(fontWeight: FontWeight.w800))]),
                    ),
                ],
              ),
          ]);
        },
      ),
    );
  }

  Widget _kv(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        Text(k, style: const TextStyle(fontSize: 12)),
      ]);
}
