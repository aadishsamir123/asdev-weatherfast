import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  String pageTitle = "Loading..."; // Default title while loading

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(pageTitle),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onLoadStop: (controller, url) async {
          _updateTitle(controller);
        },
      ),
    );
  }

  void _updateTitle(InAppWebViewController controller) async {
    String? title = await controller.getTitle();
    if (title != null && title.isNotEmpty) {
      setState(() {
        pageTitle = title;
      });
    }
  }
}
