import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/clock.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/search_picker.dart';
import 'league_screen.dart';
import 'more_screen.dart';

/// Our own wordmark (not any third-party logo).
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(color: AppPalette.accent, shape: BoxShape.circle),
        child: const Icon(Icons.bolt_rounded, size: 17, color: Colors.black),
      ),
      const SizedBox(width: 7),
      Text('LIVE SCORE', style: TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800, letterSpacing: -.3, color: fg, height: 1)),
    ]);
  }
}

class MatchesScreen extends StatefulWidget {
  final DateTime? today;
  const MatchesScreen({super.key, this.today});
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with TickerProviderStateMixin {
  static const _span = 30;
  late DateTime _today;
  late DateTime _day;
  late Future<GamesResult> _f;
  late TabController _tabs;
  Timer? _timer;
  bool _liveOnly = false;

  @override
  void initState() {
    super.initState();
    final n = widget.today ?? Clock.now();
    _today = DateTime(n.year, n.month, n.day);
    _day = _today;
    _tabs = TabController(length: _span * 2 + 1, initialIndex: _span, vsync: this)..addListener(_onTab);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _day == _today) setState(_load);
    });
  }

  void _onTab() {
    if (_tabs.indexIsChanging) return;
    final d = _today.add(Duration(days: _tabs.index - _span));
    if (d != _day) {
      setState(() {
        _day = d;
        _load();
      });
    }
  }

  void _load() => _f = ScoresApi.instance.gamesOn(_day);

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  String _label(DateTime d) {
    final diff = d.difference(_today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} ${d.day}';
    return dayMonth(d);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: _today.subtract(const Duration(days: _span)), lastDate: _today.add(const Duration(days: _span)));
    if (d != null) _tabs.animateTo(d.difference(_today).inDays + _span);
  }

  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    final fg = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: Column(children: [
        Container(
          color: s.bar,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              SizedBox(
                height: 58,
                child: Row(children: [
                  const SizedBox(width: 16),
                  const Wordmark(),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _liveOnly = !_liveOnly),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: _liveOnly ? AppPalette.live : s.chip, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: _liveOnly ? Colors.white : const Color(0xFF8A8A8A), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Live', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _liveOnly ? Colors.white : fg)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_today_outlined, size: 24)),
                  IconButton(onPressed: () => showSearchPicker(context), icon: const Icon(Icons.search, size: 27)),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      final st = AppScope.read(context);
                      if (v == 'theme') st.setTheme(st.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
                      if (v == 'settings') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoreScreen()));
                      if (v == 'refresh') setState(_load);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                      PopupMenuItem(value: 'theme', child: Text('Toggle light/dark')),
                      PopupMenuItem(value: 'settings', child: Text('Settings')),
                    ],
                  ),
                ]),
              ),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                labelPadding: const EdgeInsets.symmetric(horizontal: 13),
                tabs: [for (var i = -_span; i <= _span; i++) Tab(height: 50, text: _label(_today.add(Duration(days: i))))],
              ),
            ]),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _f;
            },
            child: Loader<GamesResult>(
              future: _f,
              onRetry: () => setState(_load),
              builder: (c, r) => _MatchList(result: r, liveOnly: _liveOnly),
            ),
          ),
        ),
      ]),
    );
  }
}

class _MatchList extends StatelessWidget {
  final GamesResult result;
  final bool liveOnly;
  const _MatchList({required this.result, required this.liveOnly});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    var games = result.games;
    if (liveOnly) games = games.where((g) => g.isLive).toList();
    final followed = games.where((g) => store.matches.contains(g.id) || store.isTeam(g.home.id) || store.isTeam(g.away.id)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final byLeague = <int, List<Game>>{};
    for (final g in games) {
      byLeague.putIfAbsent(g.competitionId, () => []).add(g);
    }
    int rank(int id) => store.isLeague(id) ? 1 << 40 : (result.leagues[id]?.popularity ?? 0);
    final ids = byLeague.keys.toList()..sort((a, b) => rank(b).compareTo(rank(a)));
    if (games.isEmpty) {
      return ListView(children: [EmptyNote(liveOnly ? 'No live matches right now' : 'No matches on this day')]);
    }
    List<Widget> rows(List<Game> g) => [
          for (var i = 0; i < g.length; i++) ...[if (i > 0) const Divider(indent: 12, endIndent: 12), MatchTile(g[i])],
        ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      children: [
        if (followed.isNotEmpty)
          LeagueCard(leading: const Icon(Icons.star_rounded, size: 21), title: 'Following', children: rows(followed)),
        for (final id in ids)
          Builder(builder: (context) {
            final l = result.leagues[id] ?? League(id: id, name: byLeague[id]!.first.competitionName);
            return LeagueCard(
              key: ValueKey('league-$id'),
              leading: l.isInternational || l.countryId == 0 ? Logo.league(l.id, l.name, size: 20) : Logo.country(l.countryId, l.countryName, size: 20),
              title: l.title,
              onTitleTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeagueScreen(league: l))),
              children: rows(byLeague[id]!..sort((a, b) => a.startTime.compareTo(b.startTime))),
            );
          }),
      ],
    );
  }
}
