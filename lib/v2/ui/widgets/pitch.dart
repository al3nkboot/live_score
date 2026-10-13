import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';

/// Rating chip coloured by value (original colour scale).
class RatingBadge extends StatelessWidget {
  final double rating;
  final bool top;
  final bool small;
  const RatingBadge(this.rating, {super.key, this.top = false, this.small = false});
  static Color color(double r) => r >= 8
      ? const Color(0xFF1E88E5)
      : r >= 7
          ? const Color(0xFF2BB673)
          : r >= 6.5
              ? const Color(0xFF9CCC65)
              : r >= 6
                  ? const Color(0xFFF5A623)
                  : const Color(0xFFE5534B);
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 4 : 6, vertical: small ? 1 : 2),
        decoration: BoxDecoration(color: top ? const Color(0xFF1E88E5) : color(rating), borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (top) Icon(Icons.star_rounded, size: small ? 9 : 12, color: Colors.white),
          Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.white, fontSize: small ? 10 : 12, fontWeight: FontWeight.w800)),
        ]),
      );
}

/// Both starting XIs drawn on one vertical pitch (home top, away bottom).
class PitchView extends StatelessWidget {
  final TeamLineup home;
  final TeamLineup away;
  final String homeName;
  final String awayName;
  final Set<int> subbedOff;
  final void Function(LineupPlayer) onTap;
  const PitchView({super.key, required this.home, required this.away, required this.homeName, required this.awayName, this.subbedOff = const {}, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _bar(homeName, home.formation),
      AspectRatio(
        aspectRatio: 0.66,
        child: LayoutBuilder(builder: (c, box) {
          final w = box.maxWidth, h = box.maxHeight;
          final kids = <Widget>[Positioned.fill(child: CustomPaint(painter: _PitchPainter()))];
          void place(TeamLineup l, bool top) {
            for (final p in l.starters) {
              final fl = (p.fieldLine ?? 0) / 100, fs = (p.fieldSide ?? 50) / 100;
              final y = top ? 0.05 + fl * 0.39 : 0.95 - fl * 0.39;
              final x = top ? 0.1 + fs * 0.8 : 0.9 - fs * 0.8;
              kids.add(Positioned(
                left: x * w - 36,
                top: y * h - 24,
                width: 72,
                child: _PlayerDot(p, top ? AppPalette.accent : const Color(0xFF6EA8FE), subbedOff.contains(p.memberId), () => onTap(p)),
              ));
            }
          }

          place(home, true);
          place(away, false);
          return ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(clipBehavior: Clip.none, children: kids));
        }),
      ),
      _bar(awayName, away.formation),
    ]);
  }

  Widget _bar(String n, String f) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [Expanded(child: Text(n, style: const TextStyle(fontWeight: FontWeight.w800))), Text(f, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );
}

class _PlayerDot extends StatelessWidget {
  final LineupPlayer p;
  final Color color;
  final bool off;
  final VoidCallback onTap;
  const _PlayerDot(this.p, this.color, this.off, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 40,
            height: 34,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 4,
                top: 2,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  child: Text(p.number >= 0 ? '${p.number}' : '', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
              if (p.rating != null) Positioned(right: -8, top: -4, child: RatingBadge(p.rating!, top: p.topRated, small: true)),
              if (off) const Positioned(left: -4, bottom: -2, child: Icon(Icons.south_rounded, size: 14, color: AppPalette.live)),
            ]),
          ),
          const SizedBox(height: 2),
          Text(p.shortName.isEmpty ? p.name : p.shortName,
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final bg = Paint()..color = AppPalette.pitch;
    c.drawRect(Offset.zero & s, bg);
    final stripe = Paint()..color = Colors.white.withValues(alpha: .035);
    for (var i = 0; i < 10; i += 2) {
      c.drawRect(Rect.fromLTWH(0, s.height * i / 10, s.width, s.height / 10), stripe);
    }
    final l = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const m = 8.0;
    c.drawRect(Rect.fromLTWH(m, m, s.width - 2 * m, s.height - 2 * m), l);
    c.drawLine(Offset(m, s.height / 2), Offset(s.width - m, s.height / 2), l);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .14, l);
    final bw = s.width * .55, bh = s.height * .13, gw = s.width * .26, gh = s.height * .05;
    c.drawRect(Rect.fromLTWH((s.width - bw) / 2, m, bw, bh), l);
    c.drawRect(Rect.fromLTWH((s.width - gw) / 2, m, gw, gh), l);
    c.drawRect(Rect.fromLTWH((s.width - bw) / 2, s.height - m - bh, bw, bh), l);
    c.drawRect(Rect.fromLTWH((s.width - gw) / 2, s.height - m - gh, gw, gh), l);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

