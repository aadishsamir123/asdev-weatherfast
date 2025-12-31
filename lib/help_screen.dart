import 'package:flutter/material.dart';
import 'webview_screen.dart'; // Import your WebViewScreen here

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const featureRequestUrl = 'https://forms.gle/yWgLvBr2vMagmFbQ8';
    const bugReportUrl = 'https://forms.gle/vmdA2oyWtLtDu8jA8';

    final List<Map<String, dynamic>> items = [
      {
        'title': 'Feature Request',
        'subtitle': 'Suggest a new feature for WeatherFast',
        'icon': Icons.lightbulb_outline,
        'color': colorScheme.primaryContainer,
        'iconColor': colorScheme.onPrimaryContainer,
        'url': featureRequestUrl,
      },
      {
        'title': 'Bug Report',
        'subtitle': 'Report a bug or issue',
        'icon': Icons.bug_report_outlined,
        'color': colorScheme.secondaryContainer,
        'iconColor': colorScheme.onSecondaryContainer,
        'url': bugReportUrl,
      },
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Help & Feedback'),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: items.map((item) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item['color'],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item['icon'],
                              color: item['iconColor'],
                            ),
                          ),
                          title: Text(item['title']),
                          subtitle: Text(item['subtitle']),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebViewScreen(url: item['url']),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_outlined,
                          size: 48,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'WeatherFast',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
