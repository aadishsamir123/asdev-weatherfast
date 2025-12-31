import 'package:flutter/material.dart';
import 'package:weatherfast/help_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: const Text('Open-Source Licenses'),
                          subtitle: FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              return Text(
                                  "View licenses for open-source packages"
                                  "${snapshot.hasData ? ' used in WeatherFast ${snapshot.data!.version}' : ''}.");
                            },
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Theme(
                                  data: Theme.of(context),
                                  child: const LicensePage(
                                    applicationName: 'WeatherFast',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Support Section
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
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.help_outline_rounded,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: const Text('Help & Feedback'),
                          subtitle: const Text('Get help or send feedback'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Footer
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
                        const SizedBox(height: 4),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            );
                          },
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
