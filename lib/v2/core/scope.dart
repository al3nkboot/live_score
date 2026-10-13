import 'package:flutter/widgets.dart';

import 'prefs.dart';

/// Provides the [FavoritesStore] to the widget tree and rebuilds on change.
class AppScope extends InheritedNotifier<FavoritesStore> {
  const AppScope({super.key, required FavoritesStore store, required super.child}) : super(notifier: store);
  static FavoritesStore of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static FavoritesStore read(BuildContext c) => c.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
