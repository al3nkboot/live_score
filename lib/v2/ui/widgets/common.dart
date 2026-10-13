import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../screens/match_screen.dart';

/// Network logo with disk cache; falls back to an initial badge.
class Logo extends StatelessWidget {
  /// Set true in tests/golden rendering to avoid network.
  static bool offline = false;

  /// Optional offline resolver (tests): url -> image bytes.
  static Uint8List? Function(String url)? testBytes;
  final String url;
  final String label;
  final double size;
  final bool circle;
  const Logo(this.url, this.label, {super.key, this.size = 22, this.circle = false});

  factory Logo.team(Team t, {double size = 22}) => Logo(ScoresApi.teamLogo(t.id, size: (size * 2).round()), t.name, size: size);
  factory Logo.league(int id, String name, {double size = 22}) => Logo(ScoresApi.leagueLogo(id, size: (size * 2).round()), name, size: size);
  factory Logo.country(int id, String name, {double size = 20}) => Logo(ScoresApi.countryFlag(id, size: (size * 2).round()), name, size: size, circle: true);
  factory Logo.player(int id, String name, {double size = 40}) => Logo(ScoresApi.playerPhoto(id, size: (size * 2).round()), name, size: size, circle: true);

  Widget _fallback(BuildContext c) {
    final hue = (label.hashCode % 360).abs().toDouble();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: HSLColor.fromAHSL(1, hue, .45, .42).toColor(), shape: BoxShape.circle),
      child: Text(label.isEmpty ? '?' : label.characters.first.toUpperCase(),
          style: TextStyle(color: Colors.white, fontSize: size * .5, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (offline) {
      final b = testBytes?.call(url);
      if (b == null) return _fallback(context);
      final im = Image.memory(b, width: size, height: size, fit: circle ? BoxFit.cover : BoxFit.contain, gaplessPlayback: true);
      return circle ? ClipOval(child: im) : im;
    }
    final img = CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (c, _) => SizedBox(width: size, height: size),
      errorWidget: (c, _, _) => _fallback(c),
    );
    return circle ? ClipOval(child: img) : img;
  }
}

class SectionCard extends StatelessWidget {
  final Widget? header;
  final List<Widget> children;
  final EdgeInsets padding;
  const SectionCard({super.key, this.header, required this.children, this.padding = EdgeInsets.zero});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (header != null) header!, ...children]),
        ),
      );
}

class LiveBadge extends StatelessWidget {
  final String text;
  const LiveBadge(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppPalette.live.withValues(alpha: .15), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(color: AppPalette.live, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

class StarButton extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  final double size;
  const StarButton({super.key, required this.on, required this.onTap, this.size = 22});
  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded,
              key: ValueKey(on), size: size, color: on ? const Color(0xFFFFC53D) : Theme.of(context).hintColor),
        ),
      );
}

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String shortDate(DateTime d) => '${_wd[d.weekday - 1]} ${d.day} ${_mon[d.month - 1]}';
String longDate(DateTime d) => '${_wd[d.weekday - 1]}, ${d.day} ${_mon[d.month - 1]}, ${d.year}, ${hhmm(d)}';
String dayMonth(DateTime d) => '${d.day} ${_mon[d.month - 1]}';

/// Match row in the reference layout: home name + logo | time/score | logo + away name.
class MatchTile extends StatelessWidget {
  final Game game;
  final bool showDate;
  const MatchTile(this.game, {super.key, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = Surfaces.of(context);
    final fg = Theme.of(context).colorScheme.onSurface;
    final g = game;
    const nameStyle = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.2);
    Widget center;
    if (g.isScheduled || !g.hasScore) {
      center = Column(mainAxisSize: MainAxisSize.min, children: [
        if (showDate) Text(dayMonth(g.startTime), style: TextStyle(fontSize: 11.5, color: s.secondary)),
        Text(hhmm(g.startTime), style: TextStyle(fontSize: 14.5, color: s.secondary, fontFeatures: tabular)),
        if (!g.isScheduled && g.shortStatus.isNotEmpty) Text(g.shortStatus, style: TextStyle(fontSize: 11, color: s.secondary)),
      ]);
    } else {
      center = Column(mainAxisSize: MainAxisSize.min, children: [
        if (showDate && !g.isLive) Text(dayMonth(g.startTime), style: TextStyle(fontSize: 11.5, color: s.secondary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: g.isLive ? BoxDecoration(color: AppPalette.accent, borderRadius: BorderRadius.circular(6)) : null,
          child: Text(g.scoreText,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: g.isLive ? Colors.black : fg, fontFeatures: tabular)),
        ),
        const SizedBox(height: 2),
        Text(g.isLive ? g.liveBadge : (g.shortStatus == 'Ended' ? 'FT' : g.shortStatus),
            style: TextStyle(fontSize: 11.5, fontWeight: g.isLive ? FontWeight.w600 : FontWeight.w400, color: g.isLive ? AppPalette.accent : s.secondary, fontFeatures: tabular)),
      ]);
    }
    Widget red(int? n) => (n ?? 0) > 0
        ? Container(width: 7, height: 10, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: AppPalette.live, borderRadius: BorderRadius.circular(1.5)))
        : const SizedBox();
    final bell = store.wantsNotifs(g);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchScreen(gameId: g.id, initial: g))),
      onLongPress: () => store.toggleMatch(g.id),
      child: SizedBox(
        height: 72,
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(child: Text(g.home.compact, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: nameStyle)),
              red(g.redHome),
              const SizedBox(width: 8),
              Logo.team(g.home, size: 24),
              SizedBox(width: 68, child: Center(child: center)),
              Logo.team(g.away, size: 24),
              const SizedBox(width: 8),
              red(g.redAway),
              Expanded(child: Text(g.away.compact, maxLines: 2, overflow: TextOverflow.ellipsis, style: nameStyle)),
            ]),
          ),
          if (g.hasTv || bell)
            Positioned(
              right: 10,
              bottom: 6,
              child: Row(children: [
                if (g.hasTv) Icon(Icons.live_tv_rounded, size: 13, color: s.secondary),
                if (bell) ...[const SizedBox(width: 4), Icon(Icons.notifications_rounded, size: 13, color: s.secondary)],
              ]),
            ),
        ]),
      ),
    );
  }
}

/// Rounded league card with header row (#2C2C2C) and collapse chevron.
class LeagueCard extends StatefulWidget {
  final Widget leading;
  final String title;
  final List<Widget> children;
  final VoidCallback? onTitleTap;
  final bool initiallyExpanded;
  const LeagueCard({super.key, required this.leading, required this.title, required this.children, this.onTitleTap, this.initiallyExpanded = true});
  @override
  State<LeagueCard> createState() => _LeagueCardState();
}

class _LeagueCardState extends State<LeagueCard> {
  late bool _open = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
          color: s.cardHeader,
          child: InkWell(
            onTap: widget.onTitleTap ?? () => setState(() => _open = !_open),
            child: SizedBox(
              height: 54,
              child: Row(children: [
                const SizedBox(width: 16),
                SizedBox(width: 20, height: 20, child: Center(child: widget.leading)),
                const SizedBox(width: 14),
                Expanded(child: Text(widget.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                IconButton(
                  onPressed: () => setState(() => _open = !_open),
                  icon: AnimatedRotation(turns: _open ? 0 : .5, duration: const Duration(milliseconds: 180), child: const Icon(Icons.keyboard_arrow_up_rounded, size: 26)),
                ),
                const SizedBox(width: 4),
              ]),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _open ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children) : const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }
}

/// Small football-pitch glyph for the Matches tab.
class PitchIcon extends StatelessWidget {
  final double size;
  final bool filled;
  const PitchIcon({super.key, this.size = 26, this.filled = false});
  @override
  Widget build(BuildContext context) {
    final c = IconTheme.of(context).color ?? Colors.white;
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _PitchGlyph(c, filled)));
  }
}

class _PitchGlyph extends CustomPainter {
  final Color c;
  final bool filled;
  _PitchGlyph(this.c, this.filled);
  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(1, s.height * .2, s.width - 2, s.height * .6);
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    if (filled) canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = c);
    final line = filled ? (Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.6) : p;
    if (!filled) canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), p);
    canvas.drawLine(Offset(s.width / 2, r.top), Offset(s.width / 2, r.bottom), line);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.height * .1, line);
    canvas.drawRect(Rect.fromLTWH(r.left, s.height * .38, s.width * .1, s.height * .24), line);
    canvas.drawRect(Rect.fromLTWH(r.right - s.width * .1, s.height * .38, s.width * .1, s.height * .24), line);
  }

  @override
  bool shouldRepaint(covariant _PitchGlyph o) => o.c != c || o.filled != filled;
}

class LeagueHeader extends StatelessWidget {
  final int id;
  final String name;
  final String? subtitle;
  final VoidCallback? onTap;
  const LeagueHeader({super.key, required this.id, required this.name, this.subtitle, this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(children: [
          Logo.league(id, name, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              if (subtitle != null && subtitle!.isNotEmpty) TextSpan(text: '  $subtitle', style: TextStyle(color: t.hintColor, fontSize: 12)),
            ]), overflow: TextOverflow.ellipsis),
          ),
          if (onTap != null) Icon(Icons.chevron_right, size: 18, color: t.hintColor),
        ]),
      ),
    );
  }
}

/// Generic async loader with retry + pull-to-refresh friendly error.
class Loader<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback? onRetry;
  const Loader({super.key, required this.future, required this.builder, this.onRetry});
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (c, s) {
          if (s.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 40),
                const SizedBox(height: 8),
                const Text('Could not load data'),
                if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
              ]),
            ));
          }
          if (!s.hasData) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2.5)));
          return builder(c, s.data as T);
        },
      );
}

class EmptyNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyNote(this.text, {super.key, this.icon = Icons.sports_soccer});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Icon(icon, size: 40, color: Theme.of(context).hintColor),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
        ]),
      );
}
