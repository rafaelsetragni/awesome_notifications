import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:progressive_image/progressive_image.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationDetailsPage extends StatefulWidget {

  String get results => receivedNotification.toString();
  final ReceivedNotification receivedNotification;

  final String title = 'Notification Details';

  NotificationDetailsPage(this.receivedNotification);

  @override
  _NotificationDetailsPageState createState() => _NotificationDetailsPageState();
}

class _NotificationDetailsPageState extends State<NotificationDetailsPage> {
  String displayedDate = '';

  @override
  void initState() {
    super.initState();

    displayedDate =
        DateUtils.parseDateToString(
            DateUtils.utcToLocal(
                DateUtils.parseStringToDate(widget.receivedNotification.displayedDate)
            ),
            format: 'dd/MM/yyyy HH:mm'
        );
  }

  @override
  Widget build(BuildContext context) {

    MediaQueryData mediaQueryData = MediaQuery.of(context);
    ThemeData themeData = Theme.of(context);

    ImageProvider largeIcon = widget.receivedNotification.largeIconImage;
    ImageProvider bigPicture = widget.receivedNotification.bigPictureImage;

    if(largeIcon == bigPicture) largeIcon = null;

    double maxSize = max(mediaQueryData.size.width, mediaQueryData.size.height);

    if(bigPicture != null){
      SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(statusBarBrightness: Brightness.dark)
      );
    }

    return Scaffold(
        body: Stack(
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
                              bigPicture == null ?
                              Container(
                                height: mediaQueryData.padding.top + 80,
                                width: mediaQueryData.size.width,
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.black12, Colors.transparent],
                                        stops: [0.0, 1.0]
                                    )
                                ),
                              ) :
                              Container(
                                  height: maxSize * 0.4 + mediaQueryData.padding.top,
                                  width: mediaQueryData.size.width,
                                  child: ShaderMask(
                                      shaderCallback: (rect) {
                                        return LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Colors.black, Colors.black, Colors.transparent],
                                            stops: [0.0, 0.75, 0.98]
                                        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                                      },
                                      blendMode: BlendMode.dstIn,
                                      child: ProgressiveImage(
                                        placeholder: AssetImage('assets/images/placeholder.gif'),
                                        thumbnail: AssetImage('assets/images/placeholder.gif'),
                                        image: widget.receivedNotification.bigPictureImage,
                                        width: mediaQueryData.size.width,
                                        height: maxSize * 0.4 + mediaQueryData.padding.top,
                                        fit: BoxFit.cover,
                                      )
                                  )
                              ),
                            ],
                          ),
                          largeIcon == null ? SizedBox() :
                          Positioned(
                              left: bigPicture == null ? mediaQueryData.size.width / 2 - 60 : 20,
                              top: mediaQueryData.padding.top + (bigPicture == null ? 30 : maxSize * 0.25),
                              child: CircleAvatar(
                                radius: maxSize * 0.08,
                                backgroundColor: Color(0xffFDCF09),
                                child: CircleAvatar(
                                    radius: maxSize * 0.075,
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: ProgressiveImage(
                                        placeholder: AssetImage('assets/images/placeholder.gif'),
                                        thumbnail: AssetImage('assets/images/placeholder.gif'),
                                        image: widget.receivedNotification.largeIconImage,
                                        width: maxSize * 0.08 * 2,
                                        height: maxSize * 0.08 * 2,
                                        fit: BoxFit.cover,
                                      ),
                                    ) //widget.receivedNotification.largeIcon.image,
                                ),
                              )
                          ),
                          Container(
                            width: mediaQueryData.size.width,
                            padding: EdgeInsets.only(left: 20.0, right:20.0, bottom: 10, top: bigPicture == null ? (largeIcon == null ? 100 : 190) : maxSize * 0.45 + 5),
                            child: RichText(
                                text: TextSpan(
                                    children: [
                                      TextSpan(
                                          text: widget.receivedNotification?.titleWithoutHtml ?? ((widget.receivedNotification?.body?.isEmpty ?? true) ? '' : widget.receivedNotification.bodyWithoutHtml),
                                          style: TextStyle(fontSize: (widget.receivedNotification?.title?.isEmpty ?? true) ? 22 : 32, height: 1.2, color: Colors.black, fontWeight: FontWeight.bold)
                                      ),
                                      TextSpan(
                                          text: '\n' + displayedDate,
                                          style: themeData.textTheme.subtitle2.copyWith( color: Colors.black26 )
                                      )
                                    ]
                                )
                            ),
                          )
                        ],
                      ),
                      (widget.receivedNotification?.title?.isEmpty ?? true) ? SizedBox.shrink() :
                      (widget.receivedNotification?.body?.isEmpty ?? true) ? SizedBox.shrink() :
                      Container(
                          width: mediaQueryData.size.width,
                          padding: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 25),
                          child: Text(widget.receivedNotification.bodyWithoutHtml, style: themeData.textTheme.bodyText2)
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    minWidth: mediaQueryData.size.width,
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                          width: mediaQueryData.size.width,
                          color: themeData.dividerColor,
                          padding: EdgeInsets.only(left: 10, right: 10, top:30, bottom: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('ReceivedNotification details:', style: themeData.textTheme.subtitle1.copyWith(color: themeData.hintColor)),
                              SizedBox(height: 20 ),
                              Text(widget.results, style: themeData.textTheme.bodyText2.copyWith(color: themeData.hintColor)),
                            ],
                          )
                      ),
                    ],
                  ),
                )
              ],
            ),
            Positioned(
              top: mediaQueryData.padding.top + 10,
              left: 10,
              child: Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        )
    );
  }
}