import 'dart:async';
import 'dart:typed_data';

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
            _createdSubject = StreamController<ReceivedNotification>.broadcast(sync: true);

  final StreamController<ReceivedNotification>
            // ignore: close_sinks
            _displayedSubject = StreamController<ReceivedNotification>.broadcast(sync: true);

  final StreamController<ReceivedAction>
            // ignore: close_sinks
            _actionSubject = StreamController<ReceivedAction>.broadcast(sync: true);



  /// STREAM METHODS *********************************************

  /// Stream to capture all FCM token updates. Could be changed at any time.
  Stream<String> get fcmTokenStream {
    return _tokenStreamController.stream;
  }

  /// Stream to capture all created notifications
  Stream<ReceivedNotification> get createdStream {
    return _createdSubject.stream;
  }

  /// Stream to capture all notifications displayed on user's screen.
  Stream<ReceivedNotification> get displayedStream {
    return _displayedSubject.stream;
  }

  /// Stream to capture all actions (tap) over notifications
  Stream<ReceivedAction> get actionStream {
    return _actionSubject.stream;
  }


  /// SINK METHODS *********************************************

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get fcmTokenSink {
    return _tokenStreamController.sink;
  }

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get createdSink {
    return _createdSubject.sink;
  }

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get displayedSink {
    return _displayedSubject.sink;
  }

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get actionSink {
    return _actionSubject.sink;
  }


  /// CLOSE STREAM METHODS *********************************************

  /// Closes definitely all the streams.
  dispose(){
    _tokenStreamController.close();
    _createdSubject.close();
    _displayedSubject.close();
    _actionSubject.close();
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

  /// Initializes the plugin, creating a default icon and the initial channels. Only needs
  /// to be called at main.dart once.
  /// OBS: [defaultIcon] needs to be a Resource media type
  /// OBS 2: [channels] are updated if they already exists
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

  /// Decode a drawable resource bytes into a Uint8List to be used in Flutter widgets
  Future<Uint8List> getDrawableData (String drawablePath) async {

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
        _createdSubject.sink.add(
            ReceivedNotification()
                .fromMap(arguments)
        );
        debugPrint('Notification created');
        return;

      case CHANNEL_METHOD_NOTIFICATION_DISPLAYED:
        _displayedSubject.sink.add(
            ReceivedNotification()
                .fromMap(arguments)
        );
        debugPrint('Notification displayed');
        return;

      case CHANNEL_METHOD_ACTION_RECEIVED:
        _actionSubject.sink.add(
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

  /// Gets the firebase cloud messaging token
  Future<String> get firebaseAppToken async {
    final String token = await _channel.invokeMethod(CHANNEL_METHOD_GET_FCM_TOKEN);
    return token;
  }

  /// Check if firebase is fully available on the project
  Future<bool> get isFirebaseAvailable async {
    final bool isAvailable = await _channel.invokeMethod(CHANNEL_METHOD_IS_FCM_AVAILABLE);
    return isAvailable;
  }


  /// LOCAL NOTIFICATION METHODS *********************************************

  /// Creates a new notification.
  /// If notification has no [body] or [title], it will only be created, but never displayed. (background notification)
  /// [schedule] and [actionButtons] are optional
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

  /// List all active scheduled notifications.
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

  /// Set a new notification channel or updates if already exists
  Future<void> setChannel(NotificationChannel notificationChannel) async {
    await _channel.invokeMethod(CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL, notificationChannel.toMap());
  }

  /// Remove a notification channel
  Future<bool> removeChannel(String channelKey) async {
    final bool wasRemoved = await _channel.invokeMethod(CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL, channelKey);
    return wasRemoved;
  }

  /// Cancel a single notification
  Future<void> cancel(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_NOTIFICATION, id);
  }

  /// Cancel a single scheduled notification
  Future<void> cancelSchedule(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_SCHEDULE, id);
  }

  /// Cancel all active notification schedules
  Future<void> cancelAllSchedules() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_SCHEDULES);
  }

  /// Cancel all notifications and active schedules
  Future<void> cancelAll() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS);
  }
}
