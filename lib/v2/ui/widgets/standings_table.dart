import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../screens/team_screen.dart';
import 'common.dart';

enum TableMode { short, full, form }

Color? zoneColor(Destination? d) {
  if (d == null) return null;
  final n = d.name.toLowerCase();
  if (d.type == 3 || n.contains('relegat')) return AppPalette.relegation;
  if (n.contains('conference')) return AppPalette.uecl;
  if (n.contains('europa')) return AppPalette.uel;
  if (n.contains('champions')) return AppPalette.ucl;
  final hex = d.color.replaceAll('#', '');
  final v = int.tryParse(hex, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

/// Table with Short / Full / Form segments and Overall/Home/Away filter.
class StandingsView extends StatefulWidget {
  final int competitionId;
  final List<StandingsTable> initial;
  final Set<int> highlight;
  const StandingsView({super.key, required this.competitionId, required this.initial, this.highlight = const {}});
  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  TableMode _mode = TableMode.full;
  int _type = 1;
  late Future<List<StandingsTable>> _f = Future.value(widget.initial);

  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    final fg = Theme.of(context).colorScheme.onSurface;
    final filters = widget.initial.isNotEmpty && widget.initial.first.filters.isNotEmpty ? widget.initial.first.filters : const <(int, String)>[];
    Widget seg(String t, TableMode m) => GestureDetector(
          onTap: () => setState(() => _mode = m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _mode == m ? s.outline : Colors.transparent, borderRadius: BorderRadius.circular(20)),
            child: Text(t, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: fg)),
          ),
        );
    return ListView(padding: const EdgeInsets.only(top: 10, bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: s.card, borderRadius: BorderRadius.circular(22)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [seg('Short', TableMode.short), seg('Full', TableMode.full), seg('Form', TableMode.form)]),
          ),
          const Spacer(),
          if (filters.length > 1)
            Container(
              height: 40,
              padding: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(color: s.card, borderRadius: BorderRadius.circular(22)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _type,
                  icon: const Icon(Icons.arrow_drop_down),
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: s.card,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w600, color: fg),
                  items: [for (final f in filters) DropdownMenuItem(value: f.$1, child: Text(f.$2))],
                  onChanged: (v) => setState(() {
                    _type = v!;
                    _f = v == 1 ? Future.value(widget.initial) : ScoresApi.instance.standings(widget.competitionId, type: v);
                  }),
                ),
              ),
            ),
        ]),
      ),
      FutureBuilder<List<StandingsTable>>(
        future: _f,
        builder: (c, snap) {
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
          return Column(children: [for (final t in snap.data!) StandingsCard(table: t, highlight: widget.highlight, mode: _mode)]);
        },
      ),
    ]);
  }
}

class StandingsCard extends StatelessWidget {
  final StandingsTable table;
  final Set<int> highlight;
  final TableMode mode;
  const StandingsCard({super.key, required this.table, this.highlight = const {}, this.mode = TableMode.full});

  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    final groups = <String, List<StandingRow>>{};
    for (final r in table.rows) {
      groups.putIfAbsent(r.group, () => []).add(r);
    }
    final hs = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: s.secondary);
    const cs = TextStyle(fontSize: 14, fontFeatures: tabular);
    Widget cell(String t, {double w = 22, TextStyle? st}) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: st ?? cs));
    List<Widget> cols(StandingRow? r) {
      String v(String Function(StandingRow) f, String h) => r == null ? h : f(r);
      final st = r == null ? hs : null;
      switch (mode) {
        case TableMode.short:
          return [
            cell(v((r) => '${r.played}', 'Pl'), w: 32, st: st),
            cell(v((r) => r.goalDiff > 0 ? '+${r.goalDiff}' : '${r.goalDiff}', 'GD'), w: 40, st: st),
            cell(v((r) => r.points.toStringAsFixed(0), 'Pts'), w: 36, st: st ?? cs.copyWith(fontWeight: FontWeight.w700)),
          ];
        case TableMode.full:
          return [
            cell(v((r) => '${r.played}', 'Pl'), st: st),
            cell(v((r) => '${r.won}', 'W'), st: st),
            cell(v((r) => '${r.drawn}', 'D'), st: st),
            cell(v((r) => '${r.lost}', 'L'), st: st),
            cell(v((r) => '${r.goalsFor}-${r.goalsAgainst}', '+/-'), w: 50, st: st),
            cell(v((r) => r.goalDiff > 0 ? '+${r.goalDiff}' : '${r.goalDiff}', 'GD'), w: 36, st: st),
            cell(v((r) => r.points.toStringAsFixed(0), 'Pts'), w: 30, st: st ?? cs.copyWith(fontWeight: FontWeight.w700)),
          ];
        case TableMode.form:
          if (r == null) return [SizedBox(width: 5 * 30, child: Text('Form', textAlign: TextAlign.center, style: hs))];
          final f = r.form.length > 5 ? r.form.sublist(r.form.length - 5) : r.form;
          return [
            for (final x in f)
              Container(
                width: 26,
                height: 24,
                margin: const EdgeInsets.only(left: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: x == 1 ? const Color(0xFF00B05A) : x == 2 ? const Color(0xFF8A8A8A) : const Color(0xFFE5534B), borderRadius: BorderRadius.circular(6)),
                child: Text(x == 1 ? 'W' : x == 2 ? 'D' : 'L', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
          ];
      }
    }

    return Column(children: [
      for (final g in groups.entries)
        SectionCard(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(children: [
              Logo.league(table.competitionId, table.name, size: 24),
              const SizedBox(width: 16),
              Expanded(child: Text(g.key.isNotEmpty ? g.key : (table.name.isNotEmpty ? table.name : 'Table'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
            child: Row(children: [SizedBox(width: 26, child: Text('#', style: hs)), Expanded(child: Text('Team', style: hs)), ...cols(null)]),
          ),
          Divider(color: s.divider),
          for (final r in g.value)
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamScreen(team: r.team))),
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                color: highlight.contains(r.team.id) ? s.highlight : null,
                child: Row(children: [
                  Container(
                    width: 3,
                    height: 50,
                    decoration: BoxDecoration(color: zoneColor(table.destinations[r.destination]), borderRadius: const BorderRadius.horizontal(right: Radius.circular(2))),
                  ),
                  const SizedBox(width: 11),
                  SizedBox(width: 26, child: Text('${r.position}', style: cs)),
                  Logo.team(r.team, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.team.name.length > 16 ? r.team.compact : r.team.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5))),
                  ...cols(r),
                  const SizedBox(width: 10),
                ]),
              ),
            ),
          if (table.destinations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Wrap(spacing: 14, runSpacing: 6, children: [
                for (final d in table.destinations.values)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: zoneColor(d), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(d.name, style: TextStyle(fontSize: 12.5, color: s.secondary)),
                  ]),
              ]),
            ),
        ]),
    ]);
  }
}
