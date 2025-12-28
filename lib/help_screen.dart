import 'package:flutter/material.dart';
import 'webview_screen.dart'; // Import your WebViewScreen here

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define URLs for Feature Request and Bug Report
    const featureRequestUrl = 'https://forms.gle/yWgLvBr2vMagmFbQ8';
    const bugReportUrl = 'https://forms.gle/vmdA2oyWtLtDu8jA8';

    // List items for the screen
    final List<Map<String, String>> items = [
      {'title': 'Feature Request', 'url': featureRequestUrl},
      {'title': 'Bug Report', 'url': bugReportUrl},
    ];

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Help and Feedback')),
        body: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item['title']!),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to WebViewScreen with the selected URL
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(url: item['url']!),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
