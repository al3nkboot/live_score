import 'package:flutter/material.dart';

/// Palette sampled from the reference dark UI (original naming/brand).
class AppPalette {
  static const accent = Color(0xFF2BD572);
  static const live = Color(0xFFFF4D4F);
  static const pitch = Color(0xFF1F6B3F);
  static const ucl = Color(0xFF2BD572);
  static const uel = Color(0xFF2F6BFF);
  static const uecl = Color(0xFF02CCF0);
  static const relegation = Color(0xFFE5534B);
}

/// Surface colours for dark / light, exposed as a theme extension.
@immutable
class Surfaces extends ThemeExtension<Surfaces> {
  final Color bg, bar, card, cardHeader, chip, divider, secondary, nav, highlight, outline;
  const Surfaces({required this.bg, required this.bar, required this.card, required this.cardHeader, required this.chip, required this.divider, required this.secondary, required this.nav, required this.highlight, required this.outline});

  static const dark = Surfaces(
    bg: Color(0xFF000000),
    bar: Color(0xFF1A1A1A),
    card: Color(0xFF1D1D1D),
    cardHeader: Color(0xFF2C2C2C),
    chip: Color(0xFF333333),
    divider: Color(0xFF2A2A2A),
    secondary: Color(0xFF9E9E9E),
    nav: Color(0xFF141414),
    highlight: Color(0xFF2E2E2E),
    outline: Color(0xFF4A4A4A),
  );
  static const light = Surfaces(
    bg: Color(0xFFF0F1F3),
    bar: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardHeader: Color(0xFFF5F6F7),
    chip: Color(0xFFEDEEF0),
    divider: Color(0xFFE4E5E7),
    secondary: Color(0xFF6B6F75),
    nav: Color(0xFFFFFFFF),
    highlight: Color(0xFFE9F8EF),
    outline: Color(0xFFD0D3D7),
  );

  static Surfaces of(BuildContext c) => Theme.of(c).extension<Surfaces>()!;

  @override
  Surfaces copyWith() => this;
  @override
  Surfaces lerp(covariant Surfaces? other, double t) => t < .5 ? this : (other ?? this);
}

const tabular = [FontFeature.tabularFigures()];

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final s = dark ? Surfaces.dark : Surfaces.light;
  final fg = dark ? Colors.white : const Color(0xFF111111);
  final scheme = ColorScheme.fromSeed(seedColor: AppPalette.accent, brightness: b).copyWith(
    primary: dark ? AppPalette.accent : const Color(0xFF00A35A),
    onPrimary: Colors.black,
    surface: s.card,
    onSurface: fg,
    outlineVariant: s.divider,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    fontFamily: 'Inter',
    extensions: [s],
    hintColor: s.secondary,
    scaffoldBackgroundColor: s.bg,
    splashFactory: InkRipple.splashFactory,
    textTheme: Typography.material2021(platform: TargetPlatform.android).white.apply(fontFamily: 'Inter', bodyColor: fg, displayColor: fg),
    appBarTheme: AppBarTheme(
      backgroundColor: s.bar,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: fg),
    ),
    cardTheme: CardThemeData(
      color: s.card,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: s.divider, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: s.nav,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith((st) => IconThemeData(size: 26, color: st.contains(WidgetState.selected) ? scheme.primary : s.secondary)),
      labelTextStyle: WidgetStateProperty.resolveWith((st) => TextStyle(
          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: st.contains(WidgetState.selected) ? scheme.primary : s.secondary)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: fg,
      unselectedLabelColor: s.secondary,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 4, color: scheme.primary),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
      labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    listTileTheme: ListTileThemeData(iconColor: s.secondary),
  );
}
