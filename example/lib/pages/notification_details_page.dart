import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationDetailsPage extends StatefulWidget {
  String get results => receivedNotification.toString();
  final ReceivedNotification receivedNotification;

  final String title = 'Notification Details';

  const NotificationDetailsPage(this.receivedNotification, {super.key});

  @override
  State<NotificationDetailsPage> createState() =>
      _NotificationDetailsPageState();
}

class _NotificationDetailsPageState extends State<NotificationDetailsPage> {
  String? displayedDate = '';

  @override
  void initState() {
    super.initState();
    displayedDate = AwesomeDateUtils.parseDateToString(
      widget.receivedNotification.displayedDate!,
      format: 'dd/MM/yyyy HH:mm',
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    ThemeData themeData = Theme.of(context);

    ImageProvider? largeIcon = widget.receivedNotification.largeIconImage;
    ImageProvider? bigPicture = widget.receivedNotification.bigPictureImage;

    if (largeIcon == bigPicture) largeIcon = null;

    double maxSize = max(mediaQueryData.size.width, mediaQueryData.size.height);

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
              Container(
                constraints: BoxConstraints(
                  minHeight: mediaQueryData.size.height,
                  minWidth: mediaQueryData.size.width,
                ),
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            bigPicture == null
                                ? Container(
                                    height: mediaQueryData.padding.top + 120,
                                    width: mediaQueryData.size.width,
                                    decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black12,
                                            Colors.transparent,
                                          ],
                                          stops: [
                                            0.0,
                                            1.0,
                                          ],
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: maxSize * 0.4 +
                                          mediaQueryData.padding.top,
                                      width: mediaQueryData.size.width,
                                      child: ShaderMask(
                                        shaderCallback: (rect) {
                                          return const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black,
                                              Colors.black,
                                              Colors.transparent,
                                            ],
                                            stops: [
                                          0.0,
                                          1.0
                                        ])),
                                  )
                                : Container(
                                    height: maxSize * 0.4 +
                                        mediaQueryData.padding.top,
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
                                              stops: [
                                                0.0,
                                                0.75,
                                                0.98
                                              ]).createShader(Rect.fromLTRB(
                                              0, 0, rect.width, rect.height));
                                        },
                                        blendMode: BlendMode.dstIn,
                                        child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom:
                                                    2.0), // 2 pixels to avoid render error on ShaderMask while the users are sliding the page
                                            child: FadeInImage(
                                              placeholder: const AssetImage(
                                                  'assets/images/placeholder.gif'),
                                              image: widget.receivedNotification
                                                  .bigPictureImage!,
                                              width: mediaQueryData.size.width,
                                              height: maxSize * 0.4 +
                                                  mediaQueryData.padding.top -
                                                  2,
                                              fit: BoxFit.cover,
                                            )))),
                          ],
                        ),
                        largeIcon == null
                            ? const SizedBox()
                            : Positioned(
                                left: bigPicture == null
                                    ? mediaQueryData.size.width / 2 - 60
                                    : 20,
                                top: mediaQueryData.padding.top +
                                    (bigPicture == null ? 30 : maxSize * 0.25),
                                child: CircleAvatar(
                                  radius: maxSize * 0.08,
                                  backgroundColor: const Color(0xffFDCF09),
                                  child: CircleAvatar(
                                    radius: maxSize * 0.08,
                                    backgroundColor: const Color(0xffFDCF09),
                                    child: CircleAvatar(
                                      radius: maxSize * 0.075,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: FadeInImage(
                                          placeholder: const AssetImage(
                                              'assets/images/placeholder.gif'),
                                          image: widget.receivedNotification
                                              .largeIconImage!,
                                          width: maxSize * 0.08 * 2,
                                          height: maxSize * 0.08 * 2,
                                          fit: BoxFit.cover,
                                        ),
                                      ), //widget.receivedNotification.largeIcon.image,
                                    ),
                                  ),
                                ),
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
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.receivedNotification
                                            .titleWithoutHtml ??
                                        ((widget.receivedNotification.body
                                                    ?.isEmpty ??
                                                true)
                                            ? 22
                                            : 32,
                                        height: 1.2,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                            TextSpan(
                              text: '\n$displayedDate',
                              style: themeData.textTheme.titleSmall
                                  ?.copyWith(color: Colors.black26),
                            )
                          ])),
                        )
                      ],
                    ),
                    (widget.receivedNotification.title?.isEmpty ?? true)
                        ? const SizedBox.shrink()
                        : (widget.receivedNotification.body?.isEmpty ?? true)
                            ? const SizedBox.shrink()
                            : Container(
                                width: mediaQueryData.size.width,
                                padding: const EdgeInsets.only(
                                    top: 10, left: 20, right: 20, bottom: 25),
                                child: Text(
                                    widget.receivedNotification
                                            .bodyWithoutHtml ??
                                        '',
                                    style: themeData.textTheme.bodyMedium)),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: mediaQueryData.size.width,
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                        width: mediaQueryData.size.width,
                        color: themeData.disabledColor,
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 30, bottom: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'ReceivedNotification details:',
                              style: themeData.textTheme.titleMedium
                                  ?.copyWith(color: themeData.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.results,
                              style: themeData.textTheme.bodyMedium
                                  .copyWith(color: themeData.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          bigPicture == null ||
                  Theme.of(context).platform == TargetPlatform.android
              ? const SizedBox()
              : Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: mediaQueryData.size.width,
                    height: mediaQueryData.padding.top + 6,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                          Colors.black54, //Colors.white54,//
                          Colors.black38, //Colors.white38,//
                          Colors.black12, //Colors.white12,//
                          Colors.transparent
                        ],
                            stops: [
                          0.2,
                          0.45,
                          0.75,
                          0.9
                        ])),
                  )),
          Positioned(
            top: mediaQueryData.padding.top + 10,
            left: 10,
            child: Container(
              height: 40,
              padding: EdgeInsets.zero,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ],
              ),
              child: IconButton(
                alignment: Alignment.center,
                icon: const Icon(FontAwesomeIcons.chevronLeft),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    )
  }
}
