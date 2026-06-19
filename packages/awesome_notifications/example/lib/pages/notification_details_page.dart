import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Fullscreen page that "opens" a notification: big picture, large icon, title,
/// body and — at the base — the notification payload and raw details. Mirrors
/// the original example's notification details page (simplified).
class NotificationDetailsPage extends StatelessWidget {
  final ReceivedNotification received;

  const NotificationDetailsPage(this.received, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ImageProvider? bigPicture = received.bigPictureImage;
    final ImageProvider? largeIcon = received.largeIconImage;
    final Map<String, String?> payload = received.payload ?? {};

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              // Big picture header (or a colored placeholder header).
              if (bigPicture != null)
                Image(
                  image: bigPicture,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                Container(height: 120, color: theme.colorScheme.primaryContainer),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (largeIcon != null) ...[
                      CircleAvatar(radius: 28, backgroundImage: largeIcon),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            received.titleWithoutHtml ?? '(no title)',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (!(received.body?.isEmpty ?? true)) ...[
                            const SizedBox(height: 8),
                            Text(
                              received.bodyWithoutHtml ?? '',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Payload at the base.
              _Section(
                title: 'Payload',
                child: payload.isEmpty
                    ? Text('(empty)', style: theme.textTheme.bodyMedium)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: payload.entries
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('${e.key}: ${e.value}'),
                                ))
                            .toList(),
                      ),
              ),

              _Section(
                title: 'Notification details',
                child: Text(
                  received.toString(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),

          // Floating back button.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
