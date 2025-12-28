import 'package:flutter/material.dart';
import 'package:weatherfast/about_screen.dart';
import 'package:weatherfast/help_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 50, color: Colors.blue),
          const SizedBox(height: 10),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.info_rounded),
                title: const Text('About App'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.question_answer_rounded),
                title: const Text('Help and Feedback'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
