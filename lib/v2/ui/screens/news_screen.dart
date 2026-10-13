import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/clock.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../widgets/common.dart';

/// Headlines from the public 365scores /news/ endpoint (opens in browser).
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsItem>> _f = ScoresApi.instance.news();

  static String ago(DateTime d) {
    final m = Clock.now().difference(d).inMinutes;
    if (m < 60) return '${m.clamp(1, 59)}m ago';
    if (m < 60 * 24) return '${m ~/ 60}h ago';
    return '${m ~/ (60 * 24)}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final s = Surfaces.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('News'), toolbarHeight: 64),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _f = ScoresApi.instance.news());
          await _f;
        },
        child: Loader<List<NewsItem>>(
          future: _f,
          onRetry: () => setState(() => _f = ScoresApi.instance.news()),
          builder: (c, items) {
            if (items.isEmpty) return ListView(children: const [EmptyNote('No news right now', icon: Icons.article_outlined)]);
            return ListView(padding: const EdgeInsets.only(top: 12, bottom: 24), children: [
              for (var i = 0; i < items.length; i++)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => launchUrl(Uri.parse(items[i].url), mode: LaunchMode.externalApplication),
                    child: i == 0
                        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            AspectRatio(aspectRatio: 16 / 9, child: _NewsImage(items[i])),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(items[i].title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3)),
                                const SizedBox(height: 8),
                                Text('${items[i].source} · ${ago(items[i].published)}', style: TextStyle(color: s.secondary, fontSize: 13)),
                              ]),
                            ),
                          ])
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(items[i].title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.3)),
                                  const SizedBox(height: 8),
                                  Text('${items[i].source} · ${ago(items[i].published)}', style: TextStyle(color: s.secondary, fontSize: 12.5)),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 104, height: 76, child: _NewsImage(items[i]))),
                            ]),
                          ),
                  ),
                ),
              Padding(padding: const EdgeInsets.all(12), child: Text('Headlines via 365scores', textAlign: TextAlign.center, style: TextStyle(color: s.secondary, fontSize: 12))),
            ]);
          },
        ),
      ),
    );
  }
}

class _NewsImage extends StatelessWidget {
  final NewsItem n;
  const _NewsImage(this.n);
  @override
  Widget build(BuildContext context) {
    if (Logo.offline) {
      final b = Logo.testBytes?.call('news:${n.id}');
      return b == null ? Container(color: Surfaces.of(context).chip) : Image.memory(b, fit: BoxFit.cover);
    }
    return CachedNetworkImage(imageUrl: n.image, fit: BoxFit.cover, errorWidget: (c, _, _) => Container(color: Surfaces.of(context).chip));
  }
}
