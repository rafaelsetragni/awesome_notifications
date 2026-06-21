import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Fullscreen page that "opens" a notification — big picture header, large icon,
/// title/body and, at the base, the payload and the raw received details.
/// Follows the original example's notification details page style.
class NotificationDetailsPage extends StatelessWidget {
  final ReceivedNotification receivedNotification;

  String get results => receivedNotification.toString();

  const NotificationDetailsPage(this.receivedNotification, {super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final themeData = Theme.of(context);

    ImageProvider? largeIcon = receivedNotification.largeIconImage;
    final ImageProvider? bigPicture = receivedNotification.bigPictureImage;
    if (largeIcon == bigPicture) largeIcon = null;

    final double maxSize =
        max(mediaQueryData.size.width, mediaQueryData.size.height);

    final DateTime? date =
        receivedNotification.displayedDate ?? receivedNotification.createdDate;
    final String? dateText = date == null
        ? null
        : AwesomeDateUtils.parseDateToString(date, format: 'dd/MM/yyyy HH:mm');

    final Map<String, String?> payload = receivedNotification.payload ?? {};

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: bigPicture == null
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: Stack(
          children: <Widget>[
            ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        // Header: big picture (faded) or a gradient placeholder.
                        if (bigPicture == null)
                          Container(
                            height: mediaQueryData.padding.top + 120,
                            width: mediaQueryData.size.width,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black12, Colors.transparent],
                                stops: [0.0, 1.0],
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: maxSize * 0.4 + mediaQueryData.padding.top,
                            width: mediaQueryData.size.width,
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black,
                                    Colors.black,
                                    Colors.transparent
                                  ],
                                  stops: [0.0, 0.75, 0.98],
                                ).createShader(
                                    Rect.fromLTRB(0, 0, rect.width, rect.height));
                              },
                              blendMode: BlendMode.dstIn,
                              child: Image(
                                image: bigPicture,
                                width: mediaQueryData.size.width,
                                height: maxSize * 0.4 +
                                    mediaQueryData.padding.top -
                                    2,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const SizedBox(),
                              ),
                            ),
                          ),

                        // Large icon overlapping, with the yellow ring.
                        if (largeIcon != null)
                          Positioned(
                            left: bigPicture == null
                                ? mediaQueryData.size.width / 2 - 60
                                : 20,
                            top: mediaQueryData.padding.top +
                                (bigPicture == null ? 30 : maxSize * 0.25),
                            child: CircleAvatar(
                              radius: maxSize * 0.08,
                              backgroundColor: const Color(0xffFDCF09),
                              child: CircleAvatar(
                                radius: maxSize * 0.075,
                                backgroundColor: Colors.white,
                                backgroundImage: largeIcon,
                              ),
                            ),
                          ),

                        // Title + date overlay.
                        Container(
                          width: mediaQueryData.size.width,
                          padding: EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            bottom: 10,
                            top: bigPicture == null
                                ? (largeIcon == null ? 130 : 240)
                                : maxSize * 0.48,
                          ),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: receivedNotification.titleWithoutHtml ??
                                    (receivedNotification.bodyWithoutHtml ?? ''),
                                style: TextStyle(
                                  fontSize:
                                      (receivedNotification.title?.isEmpty ??
                                              true)
                                          ? 22
                                          : 32,
                                  height: 1.2,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (dateText != null)
                                TextSpan(
                                  text: '\n$dateText',
                                  style: themeData.textTheme.titleSmall
                                      ?.copyWith(color: Colors.black26),
                                ),
                            ]),
                          ),
                        ),
                      ],
                    ),

                    // Body.
                    if (!(receivedNotification.title?.isEmpty ?? true) &&
                        !(receivedNotification.body?.isEmpty ?? true))
                      Container(
                        width: mediaQueryData.size.width,
                        padding: const EdgeInsets.only(
                            top: 10, left: 20, right: 20, bottom: 25),
                        child: Text(
                          receivedNotification.bodyWithoutHtml ?? '',
                          style: themeData.textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),

                // Footer: payload + raw received details.
                Container(
                  width: mediaQueryData.size.width,
                  color: themeData.disabledColor,
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 30, bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Payload:',
                        style: themeData.textTheme.titleMedium?.copyWith(
                            color: themeData.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        payload.isEmpty
                            ? '(empty)'
                            : payload.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n'),
                        style: themeData.textTheme.bodyMedium?.copyWith(
                            color: themeData.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ReceivedNotification details:',
                        style: themeData.textTheme.titleMedium?.copyWith(
                            color: themeData.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        results,
                        style: themeData.textTheme.bodySmall?.copyWith(
                            color: themeData.colorScheme.onSurface,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Rounded back button.
            Positioned(
              top: mediaQueryData.padding.top + 10,
              left: 10,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  alignment: Alignment.center,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
