import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/prefs.dart';
import '../data/api.dart';
import '../data/models.dart';
import 'diff.dart';

const _task = 'livescore.poll';
const _kSnap = 'v2.notif.snapshots';
final _plugin = FlutterLocalNotificationsPlugin();

/// Background entry point for WorkManager (runs in a separate isolate).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Notifier.initPlugin();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      await Notifier.poll(FavoritesStore(prefs), prefs);
    } catch (e) {
      debugPrint('poll failed: $e');
    }
    return true;
  });
}

/// On-device polling notifications (no push backend).
class Notifier {
  static Timer? _fg;
  static int _tick = 0;

  static Future<void> initPlugin() async {
    await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/launcher_icon')));
  }

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await initPlugin();
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(_task, _task,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep);
  }

  static Future<bool> requestPermission() async {
    final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await a?.requestNotificationsPermission() ?? false;
  }

  /// While the app is open, poll every 60s if a followed match is live/near.
  static void startForeground(FavoritesStore store) {
    _fg?.cancel();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _fg = Timer.periodic(const Duration(seconds: 60), (_) => poll(store, store.prefs, onlyIfLive: true));
  }

  static void stopForeground() => _fg?.cancel();

  static Future<void> poll(FavoritesStore store, SharedPreferences prefs, {bool onlyIfLive = false}) async {
    if (store.teams.isEmpty && store.matches.isEmpty) return;
    final snaps = <int, GameSnapshot>{};
    final raw = prefs.getString(_kSnap);
    if (raw != null) {
      for (final e in (jsonDecode(raw) as List)) {
        final s = GameSnapshot.fromJson(Map<String, dynamic>.from(e));
        snaps[s.id] = s;
      }
    }
    // Foreground: poll every minute while something is live, otherwise every 5 minutes.
    if (onlyIfLive && !snaps.values.any((s) => s.statusGroup == 3) && (_tick++ % 5 != 0)) return;
    ScoresApi.instance.langId = store.dataLang == 'ar' ? 27 : 1;
    final now = DateTime.now();
    final games = <Game>[];
    for (final d in [now.subtract(const Duration(hours: 6)), now]) {
      try {
        games.addAll((await ScoresApi.instance.gamesOn(d)).games);
      } catch (_) {}
    }
    final mine = {for (final g in games.where(store.wantsNotifs)) g.id: g};
    final next = <GameSnapshot>[];
    for (final g in mine.values) {
      for (final a in diffGame(snaps[g.id], g)) {
        if (!store.notifTypes.contains(a.key)) continue;
        await _show(a);
      }
      next.add(GameSnapshot.of(g));
    }
    await prefs.setString(_kSnap, jsonEncode(next.map((e) => e.toJson()).toList()));
  }

  static Future<void> _show(MatchAlert a) => _plugin.show(
        id: a.game.id * 10 + a.kind.index,
        title: a.title,
        body: a.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('match_events', 'Match events',
              channelDescription: 'Goals, kick-off, half-time, full-time and red cards', importance: Importance.high, priority: Priority.high),
        ),
      );
}
