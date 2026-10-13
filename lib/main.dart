import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'v2/app.dart';
import 'v2/core/prefs.dart';
import 'v2/notify/notifier.dart';

/// Live Score 2.0 entry point. The v1 code under lib/src is kept for reference
/// (original MIT-licensed app by Rady Haggag) but is no longer the entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = FavoritesStore(prefs);
  try {
    await Notifier.init();
  } catch (_) {}
  runApp(LiveScoreApp(store: store));
}
