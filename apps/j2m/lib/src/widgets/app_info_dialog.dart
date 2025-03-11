import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../assets.dart';

class AppInfoDialog extends StatefulWidget {
  const AppInfoDialog({super.key});

  @override
  State<AppInfoDialog> createState() => _AppInfoDialogState();
}

class _AppInfoDialogState extends State<AppInfoDialog> {
  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  PackageInfo? packageInfo;
  Future<void> _getPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => packageInfo = info);
  }

  static const _repoLink = 'https://github.com/albinpk/j2m';
  static const _linkedLink = 'https://www.linkedin.com/in/albinpk';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'J2M - JSON to Model',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (packageInfo != null) Text('v${packageInfo!.version}'),
              const SizedBox(height: 10),
              const Text(
                'J2M is a powerful and easy-to-use JSON-to-Model converter, '
                'designed for developers. '
                'Instantly transform JSON into structured model classes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // me
              Text(
                'Created & Maintained by',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Text('Albin', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'GitHub Repository',
                    onPressed: () => launchUrl(Uri.parse(_repoLink)),
                    icon: SizedBox.square(
                      dimension: 30,
                      child: Image.asset(Assets.icons.githubPNG),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'LinkedIn Profile',
                    onPressed: () => launchUrl(Uri.parse(_linkedLink)),
                    icon: SizedBox.square(
                      dimension: 30,
                      child: Image.asset(Assets.icons.linkedinPNG),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
