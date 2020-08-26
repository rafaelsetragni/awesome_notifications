import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;


import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/models/received_models/push_notification.dart';

import 'package:awesome_notifications/src/models/notification_channel.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/models/notification_button.dart';
import 'package:awesome_notifications/src/models/received_models/received_action.dart';
import 'package:awesome_notifications/src/models/received_models/received_notification.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';

class AwesomeNotifications  {

  static String rootNativePath;


  /// STREAM CREATION METHODS *********************************************


  // Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
  final StreamController<String> _tokenStreamController = StreamController<String>.broadcast();

  final StreamController<ReceivedNotification>
            // ignore: close_sinks
            _createdNotificationSubject = StreamController<ReceivedNotification>.broadcast(sync: true);

  final StreamController<ReceivedNotification>
            // ignore: close_sinks
            _displayedNotificationSubject = StreamController<ReceivedNotification>.broadcast(sync: true);

  final StreamController<ReceivedAction>
            // ignore: close_sinks
            _actionNotificationSubject = StreamController<ReceivedAction>.broadcast(sync: true);



  /// STREAM METHODS *********************************************


  Stream<String> get fcmTokenStream {
    return _tokenStreamController.stream;
  }

  Stream<ReceivedNotification> get createdNotificationStream {
    return _createdNotificationSubject.stream;
  }

  Stream<ReceivedNotification> get displayedNotificationStream {
    return _displayedNotificationSubject.stream;
  }

  Stream<ReceivedAction> get actionNotificationStream {
    return _actionNotificationSubject.stream;
  }


  /// SINK METHODS *********************************************


  Sink get fcmTokenSink {
    return _tokenStreamController.sink;
  }

  Sink get createdNotificationSink {
    return _createdNotificationSubject.sink;
  }

  Sink get displayedNotificationSink {
    return _displayedNotificationSubject.sink;
  }

  Sink get actionNotificationSink {
    return _actionNotificationSubject.sink;
  }


  /// CLOSE STREAM METHODS *********************************************

  dispose(){
    _tokenStreamController.close();
    _createdNotificationSubject.close();
    _displayedNotificationSubject.close();
    _actionNotificationSubject.close();
  }


  /// SINGLETON METHODS *********************************************


  final MethodChannel _channel;
  factory AwesomeNotifications() => _instance;

  @visibleForTesting
  AwesomeNotifications.private(MethodChannel channel)
      : _channel = channel;


  static final AwesomeNotifications _instance =
      AwesomeNotifications.private(
          const MethodChannel(CHANNEL_FLUTTER_PLUGIN)
      );


  /// INITIALIZING METHODS *********************************************


  Future<bool> initialize(String defaultIcon, List<NotificationChannel> channels) async {

    WidgetsFlutterBinding.ensureInitialized();

    _channel.setMethodCallHandler(_handleMethod);

    List<dynamic> serializedChannels = List();
    for(NotificationChannel channel in channels){
      serializedChannels.add(channel.toMap());
    }

    String defaultIconPath;
    if(!AssertUtils.isNullOrEmptyOrInvalid<String>(defaultIcon, String)){
      // To set a icon on top of notification, is mandatory to user a native resource
      assert(BitmapUtils().getMediaSource(defaultIcon) == MediaSource.Resource);
      defaultIconPath = defaultIcon;
    }

    var result = await _channel.invokeMethod(CHANNEL_METHOD_INITIALIZE, {
      INITIALIZE_DEFAULT_ICON: defaultIconPath,
      INITIALIZE_CHANNELS: serializedChannels
    });

    return result;
  }


  /// NATIVE MEDIA METHODS *********************************************


  Future<Uint8List> getDrawableData (String drawablePath) async {
    DecoderCallback decode;
    var result2 = await _channel.invokeMethod(CHANNEL_METHOD_GET_DRAWABLE_DATA, drawablePath);

    if(result2 == null) return null;

    return result2;
  }

  Future<dynamic> _handleMethod(MethodCall call) async {

    Map<String, dynamic> arguments = Map<String, dynamic>.from(call.arguments);

    switch (call.method) {

      case CHANNEL_METHOD_NEW_FCM_TOKEN:
        final String token = call.arguments;
        _tokenStreamController.add(token);
        return;

      case CHANNEL_METHOD_NOTIFICATION_CREATED:
        _createdNotificationSubject.sink.add(
            ReceivedNotification()
                .fromMap(arguments)
        );
        debugPrint('Notification created');
        return;

      case CHANNEL_METHOD_NOTIFICATION_DISPLAYED:
        _displayedNotificationSubject.sink.add(
            ReceivedNotification()
                .fromMap(arguments)
        );
        debugPrint('Notification displayed');
        return;

      case CHANNEL_METHOD_ACTION_RECEIVED:
        _actionNotificationSubject.sink.add(
            ReceivedAction()
                .fromMap(arguments)
        );
        debugPrint('Action received');
        return;

      default:
        throw UnsupportedError('Unrecognized JSON message');
    }
  }

  void _validateId(int id) {
    if (id > 0x7FFFFFFF || id < -0x80000000) {
      throw ArgumentError('The id field must be the limited to 32-bit size integer');
    }
  }


  /// FIREBASE METHODS *********************************************


  /// Fires when a new FCM token is generated.
  Stream<String> get onTokenRefresh {
    return _tokenStreamController.stream;
  }

  Future<String> get firebaseAppToken async {
    final String token = await _channel.invokeMethod(CHANNEL_METHOD_GET_FCM_TOKEN);
    return token;
  }

  Future<bool> get isFirebaseAvailable async {
    final bool isAvailable = await _channel.invokeMethod(CHANNEL_METHOD_IS_FCM_AVAILABLE);
    return isAvailable;
  }


  /// LOCAL NOTIFICATION METHODS *********************************************

  Future<bool> createNotification({
      @required NotificationContent content,
      NotificationSchedule schedule,
      List<NotificationActionButton> actionButtons,
  }) async {
    _validateId(content.id);

    final bool wasCreated = await _channel.invokeMethod(
      CHANNEL_METHOD_CREATE_NOTIFICATION,
      PushNotification(
        content: content,
        schedule: schedule,
        actionButtons: actionButtons
      ).toMap()
    );

    return wasCreated;
  }

  Future<List<PushNotification>> listScheduledNotifications() async {
    List<PushNotification> scheduledNotifications = List<PushNotification>();
    List<Object> returned = await _channel.invokeListMethod(CHANNEL_METHOD_LIST_ALL_SCHEDULES);
    for(Object object in returned){
      if(object is Map){
        try {
          PushNotification pushNotification = PushNotification().fromMap(Map<String, dynamic>.from(object));
          scheduledNotifications.add(pushNotification);
        } catch (e){
          return List<PushNotification>();
        }
      }
    }
    return scheduledNotifications;
  }

  Future<void> setChannel(NotificationChannel notificationChannel) async {
    await _channel.invokeMethod(CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL, notificationChannel.toMap());
  }

  Future<bool> removeChannel(String channelKey) async {
    final bool wasRemoved = await _channel.invokeMethod(CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL, channelKey);
    return wasRemoved;
  }

  Future<void> cancel(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_NOTIFICATION, id);
  }

  Future<void> cancelSchedule(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_SCHEDULE, id);
  }

  Future<void> cancelAllSchedules() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_SCHEDULES);
  }

  Future<void> cancelAll() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS);
  }
}
