import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/connectivity_provider.dart';

/// Thin, unobtrusive banner shown at the top of any screen when the
/// device is offline. Reassures the user the app still works (per the
/// offline-first promise) rather than looking broken.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: AppColors.offline.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 14, color: AppColors.offline),
                  const SizedBox(width: 6),
                  Text(
                    'Offline mode — searching local dictionary',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.offline,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
    );
  }
}