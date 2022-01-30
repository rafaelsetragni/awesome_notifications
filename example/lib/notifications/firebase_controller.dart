
class FirebaseController {

  static void initializeFirebasesPlugins(){
    //FirebaseApp firebaseApp = await Firebase.initializeApp();
    //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /*
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');

    if(
      !StringUtils.isNullOrEmpty(message.notification?.title, considerWhiteSpaceAsEmpty: true) ||
      !StringUtils.isNullOrEmpty(message.notification?.body, considerWhiteSpaceAsEmpty: true)
    ){
      print('message also contained a notification: ${message.notification}');

      String? imageUrl;
      imageUrl ??= message.notification!.android?.imageUrl;
      imageUrl ??= message.notification!.apple?.imageUrl;

      Map<String, dynamic> notificationAdapter = {
        NOTIFICATION_CHANNEL_KEY: 'basic_channel',
        NOTIFICATION_ID:
              message.data[NOTIFICATION_CONTENT]?[NOTIFICATION_ID] ??
              message.messageId ??
              Random().nextInt(2147483647),
        NOTIFICATION_TITLE:
              message.data[NOTIFICATION_CONTENT]?[NOTIFICATION_TITLE] ??
              message.notification?.title,
        NOTIFICATION_BODY:
              message.data[NOTIFICATION_CONTENT]?[NOTIFICATION_BODY] ??
              message.notification?.body ,
        NOTIFICATION_LAYOUT:
            StringUtils.isNullOrEmpty(imageUrl) ? 'Default' : 'BigPicture',
        NOTIFICATION_BIG_PICTURE: imageUrl
      };

      AwesomeNotifications().createNotificationFromJsonData(notificationAdapter);
    }
    else {
      AwesomeNotifications().createNotificationFromJsonData(message.data);
    }
  }*/
}