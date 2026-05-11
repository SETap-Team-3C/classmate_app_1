import 'package:flutter/material.dart';
import '../services/hashtag_service.dart';
import '../screens/hashtag_browser_screen.dart';

class TrendingHashtagsWidget extends StatelessWidget {
  const TrendingHashtagsWidget({
    super.key,
    this.feedType = 'class',
    this.limit = 10,
    this.compact = false,
  });

  final String feedType;
  final int limit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hashtagService = HashtagService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: hashtagService.getTrendingHashtags(limit: limit),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final trendingHashtags = snapshot.data!;

        if (trendingHashtags.isEmpty) {
          return const SizedBox.shrink();
        }

        if (compact) {
          // Horizontal scrollable chips
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: trendingHashtags.map((hashtag) {
                  final tag = hashtag['tag'] as String;
                  final count = hashtag['count'] as int? ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('#$tag'),
                      onSelected: (_) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HashtagBrowserScreen(
                              hashtag: tag,
                              feedType: feedType,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }

        // Full list view
        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Trending',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trendingHashtags.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final hashtag = trendingHashtags[index];
                  final tag = hashtag['tag'] as String;
                  final count = hashtag['count'] as int? ?? 0;

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HashtagBrowserScreen(
                            hashtag: tag,
                            feedType: feedType,
                          ),
                        ),
                      );
                    },
                    title: Text('#$tag'),
                    subtitle: Text('$count ${count == 1 ? 'post' : 'posts'}'),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
