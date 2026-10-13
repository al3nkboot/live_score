import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/pitch.dart';
import '../widgets/standings_table.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/clock.dart';
import 'player_screen.dart';
import 'team_screen.dart';

class MatchScreen extends StatefulWidget {
  final int gameId;
  final Game? initial;
  final int initialTab;
  const MatchScreen({super.key, required this.gameId, this.initial, this.initialTab = 0});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _Data {
  final MatchDetails d;
  final List<StatLine> stats;
  final List<StandingsTable> table;
  final List<Game> h2h;
  _Data(this.d, this.stats, this.table, this.h2h);
}

class _MatchScreenState extends State<MatchScreen> {
  late Future<_Data> _f;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  Future<_Data> _load() async {
    final api = ScoresApi.instance;
    final d = await api.game(widget.gameId);
    final started = !d.game.isScheduled;
    final results = await Future.wait<Object>([
      (started ? api.gameStatsRaw(widget.gameId).then((r) => parseStats(r, d.game.home.id, d.game.away.id)) : Future.value(<StatLine>[])).catchError((_) => <StatLine>[]),
      (d.hasStandings ? api.standings(d.game.competitionId) : Future.value(<StandingsTable>[])).catchError((_) => <StandingsTable>[]),
      api.h2h(widget.gameId).catchError((_) => <Game>[]),
    ]);
    _t?.cancel();
    if (d.game.isLive) {
      _t = Timer(const Duration(seconds: 30), () {
        if (mounted) setState(() => _f = _load());
      });
    }
    return _Data(d, results[0] as List<StatLine>, results[1] as List<StandingsTable>, results[2] as List<Game>);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    return FutureBuilder<_Data>(
      future: _f,
      builder: (c, snap) {
        if (!snap.hasData) {
          return Scaffold(
            body: Column(children: [
              Container(color: s.bar, child: SafeArea(bottom: false, child: Column(children: [_TopBar(game: widget.initial), if (widget.initial != null) _Header(widget.initial!)]))),
              Expanded(child: snap.hasError ? Center(child: TextButton(onPressed: () => setState(() => _f = _load()), child: const Text('Retry'))) : const Center(child: CircularProgressIndicator(strokeWidth: 2.5))),
            ]),
          );
        }
        final data = snap.data!;
        final d = data.d;
        final hasLineups = d.homeLineup != null || d.awayLineup != null;
        final hasRatings = (d.homeLineup?.hasRatings ?? false) || (d.awayLineup?.hasRatings ?? false);
        final pre = d.game.isScheduled;
        final tabs = <(String, Widget)>[
          (pre ? 'Preview' : 'Facts', _Overview(d)),
          if (data.stats.isNotEmpty) ('Stats', _Stats(data.stats)),
          if (hasLineups) ('Lineup', _Lineups(d)),
          if (!hasLineups && d.injuries.isNotEmpty) ('Injured', ListView(padding: const EdgeInsets.only(top: 12, bottom: 24), children: [InjuriesCard(d)])),
          if (hasRatings && !pre) ('Ratings', _Ratings(d)),
          if (data.table.isNotEmpty)
            ('Table', StandingsView(competitionId: d.game.competitionId, initial: data.table, highlight: {d.game.home.id, d.game.away.id})),
          if (data.h2h.isNotEmpty) ('H2H', _H2H(data.h2h, d.game)),
        ];
        return DefaultTabController(
          length: tabs.length,
          initialIndex: widget.initialTab.clamp(0, tabs.length - 1),
          child: Scaffold(
            body: Column(children: [
              Container(
                color: s.bar,
                child: SafeArea(
                  bottom: false,
                  child: Column(children: [
                    _TopBar(game: d.game),
                    _Header(d.game, details: d),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TabBar(isScrollable: true, padding: const EdgeInsets.only(left: 6), tabs: [for (final t in tabs) Tab(height: 48, text: t.$1)]),
                    ),
                  ]),
                ),
              ),
              Expanded(child: TabBarView(children: [for (final t in tabs) t.$2])),
            ]),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final Game? game;
  const _TopBar({this.game});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = game;
    return SizedBox(
      height: 56,
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
        const Spacer(),
        if (g != null) ...[
          IconButton(
            tooltip: 'Notify me',
            onPressed: () => store.toggleBell(g.id),
            icon: Icon(store.bellMatches.contains(g.id) ? Icons.notifications_active : Icons.notifications, size: 26),
          ),
          IconButton(
            tooltip: 'Follow match',
            onPressed: () => store.toggleMatch(g.id),
            icon: Icon(store.isMatch(g.id) ? Icons.star_rounded : Icons.star_border_rounded, size: 28, color: store.isMatch(g.id) ? const Color(0xFFFFC53D) : null),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamScreen(team: v == 0 ? g.home : g.away))),
            itemBuilder: (_) => [PopupMenuItem(value: 0, child: Text(g.home.name)), PopupMenuItem(value: 1, child: Text(g.away.name))],
          ),
        ],
      ]),
    );
  }
}

/// Live countdown to kick-off (HH:MM:SS), switching to the date when > 1 day.
class Countdown extends StatefulWidget {
  final DateTime kickoff;
  final TextStyle style;
  const Countdown(this.kickoff, {super.key, required this.style});
  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.kickoff.difference(Clock.now());
    if (d.isNegative) return Text('Starting soon', style: widget.style);
    if (d.inHours >= 24) return Text(shortDate(widget.kickoff), style: widget.style);
    String two(int n) => n.toString().padLeft(2, '0');
    return Text('${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}', style: widget.style.copyWith(fontFeatures: tabular));
  }
}

class _Header extends StatelessWidget {
  final Game g;
  final MatchDetails? details;
  const _Header(this.g, {this.details});
  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    final fg = Theme.of(context).colorScheme.onSurface;
    Widget team(Team x) => Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamScreen(team: x))),
            child: Column(children: [
              Logo.team(x, size: 52),
              const SizedBox(height: 14),
              Text(x.display, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ]),
          ),
        );
    final goals = details?.events.where((e) => e.isGoal).toList() ?? [];
    Widget scorers(int teamId) => Expanded(
          child: Column(children: [
            for (final e in goals.where((e) => e.teamId == teamId))
              Text('${details!.playerName(e.playerId)} ${e.timeDisplay}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: s.secondary)),
          ]),
        );
    final sub = TextStyle(fontSize: 15, color: fg.withValues(alpha: .9), fontWeight: FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          team(g.home),
          SizedBox(
            width: 130,
            child: Column(children: [
              const SizedBox(height: 6),
              Text(g.hasScore ? g.scoreText : hhmm(g.startTime), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w400, height: 1.1, fontFeatures: tabular)),
              const SizedBox(height: 12),
              if (g.isScheduled)
                Countdown(g.startTime, style: sub)
              else if (g.isLive)
                Text(g.liveBadge, style: sub.copyWith(color: AppPalette.accent, fontWeight: FontWeight.w600))
              else
                Text(g.shortStatus == 'Ended' ? 'Full time' : g.statusText, style: sub.copyWith(color: s.secondary)),
            ]),
          ),
          team(g.away),
        ]),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [scorers(g.home.id), Icon(Icons.sports_soccer, size: 14, color: s.secondary), scorers(g.away.id)]),
        ],
      ]),
    );
  }
}

class _Overview extends StatelessWidget {
  final MatchDetails d;
  const _Overview(this.d);
  @override
  Widget build(BuildContext context) {
    final ev = d.events.where((e) => e.isGoal || e.isYellow || e.isRed || e.isSub).toList();
    final ht = d.stages.where((s) => s['shortName'] == 'HT').firstOrNull;
    return ListView(padding: const EdgeInsets.only(bottom: 24, top: 12), children: [
      if (!d.game.isScheduled)
        SectionCard(children: [
          if (ev.isEmpty) const EmptyNote('No events yet', icon: Icons.timeline),
          for (var i = 0; i < ev.length; i++) ...[
            if (ht != null && i > 0 && ev[i - 1].minute <= 45 && ev[i].minute > 45)
              _StageDivider('HT ${(ht['homeCompetitorScore'] as num?)?.toInt() ?? 0} - ${(ht['awayCompetitorScore'] as num?)?.toInt() ?? 0}'),
            _EventRow(ev[i], d),
          ],
          if (d.game.isEnded && ev.isNotEmpty) _StageDivider('FT ${d.game.scoreText}'),
        ]),
      if (d.prediction != null || d.game.isScheduled) PollCard(d),
      if (d.venue.isNotEmpty) VenueCard(d),
      InfoCard(d),
    ]);
  }
}

/// 'Who will win?' poll. Percentages/total only when 365scores provides them.
class PollCard extends StatelessWidget {
  final MatchDetails d;
  const PollCard(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = Surfaces.of(context);
    final my = store.vote(d.game.id);
    final p = d.prediction;
    final canVote = d.game.isScheduled;
    final showPct = my != null && p != null && p.showVotes && p.percentages.every((x) => x != null);
    Widget btn(int v, Widget child) {
      final sel = my == v;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            onPressed: canVote ? () => store.setVote(d.game.id, v) : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: sel ? AppPalette.accent : s.outline, width: sel ? 1.6 : 1),
              backgroundColor: sel ? AppPalette.accent.withValues(alpha: .12) : null,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              child,
              if (showPct) ...[const SizedBox(width: 8), Text('${p.percentages[v - 1]}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))],
            ]),
          ),
        ),
      );
    }

    return SectionCard(padding: const EdgeInsets.fromLTRB(14, 18, 14, 16), children: [
      Row(children: [
        const Expanded(child: Text('Who will win?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500))),
        if (p != null && p.showVotes && p.totalVotes > 0)
          Text('Total votes: ${_thousands(p.totalVotes)}', style: TextStyle(fontSize: 14, color: s.secondary, fontFeatures: tabular)),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        btn(1, Logo.team(d.game.home, size: 22)),
        btn(2, const Text('Draw', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        btn(3, Logo.team(d.game.away, size: 22)),
      ]),
      if (my != null && !showPct) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Your pick is saved on this device', style: TextStyle(fontSize: 12.5, color: s.secondary))),
    ]);
  }
}

String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class VenueCard extends StatelessWidget {
  final MatchDetails d;
  const VenueCard(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    return SectionCard(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Row(children: [
          const Icon(Icons.stadium_outlined, size: 24),
          const SizedBox(width: 18),
          Expanded(child: Text(d.venue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          Material(
            color: s.chip,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                final q = Uri.encodeComponent(d.venue);
                if (!await launchUrl(Uri.parse('geo:0,0?q=$q'))) {
                  await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'), mode: LaunchMode.externalApplication);
                }
              },
              child: const SizedBox(width: 44, height: 44, child: Icon(Icons.location_on, color: AppPalette.accent, size: 22)),
            ),
          ),
        ]),
      ),
      if (d.capacity != null && d.capacity! > 0) ...[
        Divider(indent: 16, endIndent: 16, color: s.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 15), children: [
            const TextSpan(text: 'Capacity  ', style: TextStyle(fontWeight: FontWeight.w500)),
            TextSpan(text: _thousands(d.capacity!), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .85))),
          ])),
        ),
      ],
    ]);
  }
}

class InfoCard extends StatelessWidget {
  final MatchDetails d;
  const InfoCard(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    Widget chip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: s.chip, borderRadius: BorderRadius.circular(12)),
          child: Text(t, style: const TextStyle(fontSize: 15)),
        );
    Widget row(Widget icon, Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [SizedBox(width: 24, child: Center(child: icon)), const SizedBox(width: 16), Expanded(child: Align(alignment: Alignment.centerLeft, child: child))]),
        );
    final g = d.game;
    final comp = g.competitionName.contains(', ') ? g.competitionName.split(', ').last : g.competitionName;
    final round = g.roundNum > 0 ? ' - ${g.roundName.isEmpty ? 'Round' : g.roundName} ${g.roundNum}' : '';
    return SectionCard(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), children: [
      if (d.tvNetworks.isNotEmpty) row(const Icon(Icons.live_tv_outlined, size: 22), Wrap(spacing: 6, runSpacing: 6, children: [chip(d.tvNetworks.join(', '))])),
      row(const Icon(Icons.event_outlined, size: 22), chip(longDate(g.startTime))),
      row(Logo.league(g.competitionId, comp, size: 22), chip('$comp$round')),
      if ((d.referee ?? '').isNotEmpty) row(const Icon(Icons.sports, size: 22), chip(d.referee!)),
    ]);
  }
}

class InjuriesCard extends StatelessWidget {
  final MatchDetails d;
  const InjuriesCard(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    Widget team(Team t) {
      final list = d.injuries.where((i) => i.teamId == t.id).toList();
      if (list.isEmpty) return const SizedBox();
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(children: [Logo.team(t, size: 20), const SizedBox(width: 10), Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))]),
        ),
        for (final i in list)
          ListTile(
            leading: Logo.player(i.athleteId, i.name, size: 36),
            title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text([i.reason, if (i.expectedReturn.isNotEmpty) i.expectedReturn].join(' · '), style: TextStyle(color: s.secondary)),
            trailing: Icon(i.doubtful ? Icons.help_outline : Icons.add_box_rounded, color: i.doubtful ? const Color(0xFFF5A623) : AppPalette.live, size: 20),
          ),
      ]);
    }

    return SectionCard(children: [team(d.game.home), team(d.game.away), const SizedBox(height: 8)]);
  }
}

class _StageDivider extends StatelessWidget {
  final String text;
  const _StageDivider(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(children: [
          const Expanded(child: Divider()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).hintColor, fontSize: 12))),
          const Expanded(child: Divider()),
        ]),
      );
}

class _EventRow extends StatelessWidget {
  final MatchEvent e;
  final MatchDetails d;
  const _EventRow(this.e, this.d);
  @override
  Widget build(BuildContext context) {
    final home = e.teamId == d.game.home.id;
    final t = Theme.of(context);
    Widget icon;
    final main = d.playerName(e.playerId);
    String? sub;
    if (e.isGoal) {
      icon = const Icon(Icons.sports_soccer, size: 18);
      if (e.extraPlayers.isNotEmpty) sub = 'Assist: ${d.playerName(e.extraPlayers.first)}';
      if (e.subType.isNotEmpty) sub = [e.subType, if (sub != null) sub].join(' · ');
    } else if (e.isSub) {
      icon = const Icon(Icons.swap_vert_rounded, size: 18, color: AppPalette.accent);
      sub = e.extraPlayers.isNotEmpty ? 'Out: ${d.playerName(e.extraPlayers.first)}' : null;
    } else {
      icon = Container(width: 11, height: 15, decoration: BoxDecoration(color: e.isRed ? AppPalette.live : const Color(0xFFFFC53D), borderRadius: BorderRadius.circular(2)));
    }
    final text = Column(crossAxisAlignment: home ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
      Text(main.isEmpty ? e.typeName : main, style: const TextStyle(fontWeight: FontWeight.w600)),
      if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: t.hintColor)),
    ]);
    final minute = SizedBox(width: 48, child: Text(e.timeDisplay, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: home
          ? [minute, icon, const SizedBox(width: 10), Expanded(child: text)]
          : [Expanded(child: text), const SizedBox(width: 10), icon, minute]),
    );
  }
}

class _Stats extends StatelessWidget {
  final List<StatLine> stats;
  const _Stats(this.stats);
  @override
  Widget build(BuildContext context) {
    final cats = <String, List<StatLine>>{};
    for (final s in stats) {
      cats.putIfAbsent(s.category, () => []).add(s);
    }
    return ListView(padding: const EdgeInsets.only(bottom: 24, top: 6), children: [
      for (final c in cats.entries)
        SectionCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          header: Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(c.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          children: [for (final s in c.value) StatBar(s)],
        ),
    ]);
  }
}

class StatBar extends StatelessWidget {
  final StatLine s;
  const StatBar(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final hb = s.homeShare > .5, ab = s.homeShare < .5;
    Widget pill(String v, bool lead, Color col) => Container(
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: lead ? col : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(v, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: lead ? Colors.black : null)),
        );
    const hc = AppPalette.accent;
    const ac = Color(0xFF6EA8FE);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(children: [
        Row(children: [pill(s.home, hb, hc), Expanded(child: Text(s.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))), pill(s.away, ab, ac)]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(children: [
              Expanded(flex: (s.homeShare * 1000).round().clamp(1, 999), child: Container(color: hb ? hc : t.dividerColor)),
              const SizedBox(width: 3),
              Expanded(flex: ((1 - s.homeShare) * 1000).round().clamp(1, 999), child: Container(color: ab ? ac : t.dividerColor)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Lineups extends StatelessWidget {
  final MatchDetails d;
  const _Lineups(this.d);
  @override
  Widget build(BuildContext context) {
    final h = d.homeLineup, a = d.awayLineup;
    void open(LineupPlayer p) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(athleteId: p.athleteId, name: p.name)));
    final subsOn = {for (final e in d.events.where((e) => e.isSub)) e.playerId: e};
    Widget bench(String title, TeamLineup? l) => l == null
        ? const SizedBox()
        : SectionCard(
            header: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
            children: [
              for (final p in l.bench)
                ListTile(
                  dense: true,
                  onTap: () => open(p),
                  leading: Logo.player(p.athleteId, p.name, size: 32),
                  title: Text('${p.number >= 0 ? '${p.number}  ' : ''}${p.name}'),
                  subtitle: subsOn[p.memberId] != null
                      ? Text('On ${subsOn[p.memberId]!.timeDisplay} for ${d.playerName(subsOn[p.memberId]!.extraPlayers.firstOrNull)}', style: const TextStyle(color: AppPalette.accent))
                      : Text(p.position),
                  trailing: p.rating != null ? RatingBadge(p.rating!, top: p.topRated) : null,
                ),
            ],
          );
    return ListView(padding: const EdgeInsets.only(bottom: 24, top: 6), children: [
      if (d.lineupStatus.isNotEmpty && d.lineupStatus != 'Confirmed')
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text('Predicted lineup', style: TextStyle(color: Surfaces.of(context).secondary, fontWeight: FontWeight.w500))),
      if (h != null && a != null && h.hasPositions && a.hasPositions)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: PitchView(home: h, away: a, homeName: d.game.home.name, awayName: d.game.away.name, subbedOff: {for (final e in d.events.where((e) => e.isSub)) ...e.extraPlayers}, onTap: open),
        )
      else
        for (final (n, l) in [(d.game.home.name, h), (d.game.away.name, a)])
          if (l != null)
            SectionCard(
              header: Padding(padding: const EdgeInsets.all(12), child: Text('$n  ${l.formation}', style: const TextStyle(fontWeight: FontWeight.w800))),
              children: [for (final p in l.starters) ListTile(dense: true, onTap: () => open(p), title: Text('${p.number}  ${p.name}'), subtitle: Text(p.position), trailing: p.rating != null ? RatingBadge(p.rating!) : null)],
            ),
      bench('Substitutes – ${d.game.home.name}', h),
      bench('Substitutes – ${d.game.away.name}', a),
      if (d.injuries.isNotEmpty) InjuriesCard(d),
    ]);
  }
}

class _Ratings extends StatelessWidget {
  final MatchDetails d;
  const _Ratings(this.d);
  @override
  Widget build(BuildContext context) {
    final all = <(LineupPlayer, Team)>[
      for (final p in d.homeLineup?.players ?? <LineupPlayer>[]) if (p.rating != null) (p, d.game.home),
      for (final p in d.awayLineup?.players ?? <LineupPlayer>[]) if (p.rating != null) (p, d.game.away),
    ]..sort((a, b) => b.$1.rating!.compareTo(a.$1.rating!));
    return ListView(padding: const EdgeInsets.only(bottom: 24, top: 6), children: [
      SectionCard(children: [
        for (final (p, team) in all)
          ListTile(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(athleteId: p.athleteId, name: p.name))),
            leading: Logo.player(p.athleteId, p.name, size: 36),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Row(children: [Logo.team(team, size: 14), const SizedBox(width: 6), Flexible(child: Text('${team.display} · ${p.position}', overflow: TextOverflow.ellipsis))]),
            trailing: RatingBadge(p.rating!, top: p.topRated),
          ),
      ]),
    ]);
  }
}

class _H2H extends StatelessWidget {
  final List<Game> games;
  final Game g;
  const _H2H(this.games, this.g);
  @override
  Widget build(BuildContext context) {
    var hw = 0, aw = 0, dr = 0;
    for (final x in games) {
      final hs = x.home.score ?? 0, as = x.away.score ?? 0;
      final homeIsG = x.home.id == g.home.id;
      if (hs == as) {
        dr++;
      } else if ((hs > as) == homeIsG) {
        hw++;
      } else {
        aw++;
      }
    }
    Widget n(String v, String l, Color c) => Expanded(child: Column(children: [Text(v, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c)), Text(l, style: const TextStyle(fontSize: 12))]));
    return ListView(padding: const EdgeInsets.only(bottom: 24, top: 6), children: [
      SectionCard(padding: const EdgeInsets.all(16), children: [
        Row(children: [n('$hw', g.home.display, AppPalette.accent), n('$dr', 'Draws', Colors.grey), n('$aw', g.away.display, const Color(0xFF6EA8FE))]),
      ]),
      SectionCard(children: [for (final x in games) MatchTile(x, showDate: true)]),
    ]);
  }
}
