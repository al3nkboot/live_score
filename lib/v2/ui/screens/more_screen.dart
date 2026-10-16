import 'package:flutter/material.dart';

import '../../core/scope.dart';
import '../../notify/notifier.dart';
import 'onboarding_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const kinds = {'goal': 'Goals', 'kickoff': 'Kick-off', 'halftime': 'Half-time', 'fulltime': 'Full-time', 'red': 'Red cards'};
    Widget h(String t) => Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 6), child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)));
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        h('Appearance'),
        RadioGroup<ThemeMode>(
          groupValue: s.themeMode,
          onChanged: (v) => s.setTheme(v!),
          child: const Column(children: [
            RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
            RadioListTile(value: ThemeMode.light, title: Text('Light')),
            RadioListTile(value: ThemeMode.system, title: Text('System')),
          ]),
        ),
        h('Data language'),
        RadioGroup<String>(
          groupValue: s.dataLang,
          onChanged: (v) => s.setDataLang(v!),
          child: const Column(children: [
            RadioListTile(value: 'en', title: Text('English')),
            RadioListTile(value: 'ar', title: Text('العربية (team & league names)')),
          ]),
        ),
        h('Notifications'),
        for (final k in kinds.entries) SwitchListTile(title: Text(k.value), value: s.notifTypes.contains(k.key), onChanged: (v) => s.setNotifType(k.key, v)),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Allow notifications'),
          subtitle: const Text('Required on Android 13+'),
          onTap: () async {
            final ok = await Notifier.requestPermission();
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Notifications enabled' : 'Permission not granted')));
          },
        ),
        const ListTile(
          leading: Icon(Icons.battery_alert_outlined),
          title: Text('About alerts'),
          subtitle: Text('Alerts come from on-device checks (about every 15 min in the background, every minute while the app is open during a live match). '
              'Android may delay background checks (Doze/battery saver), so alerts are not instant. For best results, exclude Mi5G Score from battery optimisation.'),
        ),
        h('Following'),
        ListTile(
          leading: const Icon(Icons.star_outline_rounded),
          title: const Text('Pick teams & leagues'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingScreen(fromSettings: true))),
        ),
        h('About'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Mi5G Score 2.2.1'),
          subtitle: Text('Mi5G Score by Midroid5G, based on the open-source Live Score app by Rady Haggag (MIT License). '
              'Match data from the public 365scores web API. Not affiliated with 365scores or FotMob.'),
        ),
        ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Open-source licenses'), onTap: () => showLicensePage(context: context, applicationName: 'Mi5G Score', applicationVersion: '2.2.1 (12)', applicationLegalese: 'Based on Live Score © 2026 Rady Haggag. MIT License.')),
      ]),
    );
  }
}
