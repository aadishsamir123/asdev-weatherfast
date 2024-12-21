import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    // Automatically open the URL when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchURL(context);
    });

    // Display a placeholder loading screen while opening the browser
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _launchURL(BuildContext context) async {
    try {
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: const CustomTabsOptions(
          showTitle: true,
        ),
      );

      // Close the screen after the URL is launched
      Navigator.pop(context);
    } catch (e) {
      // Show error if URL launch fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open URL: $e')),
      );
      print('Failed to open URL: $e');

      // Close the screen if launching fails
      Navigator.pop(context);
    }
  }
}
