// Minimal, self-contained awesome_notifications_chat example.
//
// Copy this file into your app's `lib/main.dart`, add `awesome_notifications`
// and `awesome_notifications_chat` to your pubspec.yaml and run. It shows a
// one-to-one and a group conversation, answers from the notification itself
// and marks a conversation as read. Android shows them as conversations; iOS
// and macOS as communication notifications (see the package README for the
// required Xcode setup). Messages can also arrive by push: add your Firebase
// config files (google-services.json / GoogleService-Info.plist) and send the
// payload shown in the README to the FCM token the app displays.
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_chat/awesome_notifications_chat.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

const String channelKey = 'chat';
const Color mainColor = Color(0xFF9D50DD);

// Avatars come from the network: the example bundles no assets.
const String _imagesRoot =
    'https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/2f5a5346f36cfea0b8d221062b32a54ae309339f/example/assets/images';

const NotificationPerson me = NotificationPerson(key: 'me', name: 'Me');
const NotificationPerson ana = NotificationPerson(
  key: 'ana',
  name: 'Ana',
  avatar: '$_imagesRoot/american.jpg',
  isImportant: true,
);
const NotificationPerson bot = NotificationPerson(
  key: 'awn-bot',
  name: 'Awesome Bot',
  avatar: '$_imagesRoot/awesome-notifications-logo-color.png',
  isBot: true,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize with at least one channel. Keep the Future so the UI can wait
  //    for it: creating a notification before initialize completes can fail.
  final Future<bool> awesomeNotificationsInitialization =
      NotificationController.initializeLocalNotifications().then((ok) async {
        await NotificationController.initializeRemoteNotifications();
        return ok;
      });

  runApp(
    MyApp(
      awesomeNotificationsInitialization: awesomeNotificationsInitialization,
    ),
  );
}

///  *********************************************
///     NOTIFICATION CONTROLLER
///  *********************************************
///
/// Keeps all the Awesome Notifications calls in one place so the widgets stay
/// focused on the UI.
class NotificationController {
  // Lets the (static) action listener open a page from anywhere.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Lets the (static) event listeners show snackbars from anywhere.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  ///  *********************************************
  ///     INITIALIZATION
  ///  *********************************************
  static Future<bool> initializeLocalNotifications() {
    return AwesomeNotifications().initialize(
      null, // no custom default icon → uses the app icon
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Chat',
          channelDescription: 'Chat messages',
          defaultColor: mainColor,
          ledColor: mainColor,
          importance: NotificationImportance.High,
        ),
      ],
      debug: true,
    );
  }

  ///  *********************************************
  ///     PUSH (FCM)
  ///  *********************************************
  /// The FCM token, shown on the home page to send test pushes to.
  static final ValueNotifier<String> fcmToken = ValueNotifier('');

  static Future<void> initializeRemoteNotifications() async {
    if (!AwesomeNotificationsFcm.isPlatformSupported) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      fcmToken.value = 'Firebase not configured: add your config files';
      return;
    }
    await AwesomeNotificationsFcm().initialize(
      onFcmTokenHandle: onFcmTokenReceived,
      onFcmSilentDataHandle: onSilentDataReceived,
      debug: true,
    );
    fcmToken.value = await AwesomeNotificationsFcm().requestFirebaseAppToken();
  }

  @pragma('vm:entry-point')
  static Future<void> onFcmTokenReceived(String token) async {
    fcmToken.value = token;
    debugPrint('FCM token: $token');
  }

  @pragma('vm:entry-point')
  static Future<void> onSilentDataReceived(FcmSilentData data) async {
    debugPrint('Silent data: ${data.data}');
  }

  ///  *********************************************
  ///     EVENT LISTENERS
  ///  *********************************************
  ///  Notification events are only delivered after this is called.
  static Future<void> startListeningNotificationEvents() {
    return AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// If the app was launched by tapping a notification (killed state), the tap
  /// is not delivered to [onActionReceivedMethod] (no listener existed yet):
  /// it is retrieved here instead, and opens the details page.
  static Future<void> handleInitialAction() async {
    final ReceivedAction? action = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
    debugPrint(
      'getInitialNotificationAction -> '
      '${action == null ? 'null (no launch action)' : 'id=${action.id} '
                'channelKey=${action.channelKey} '
                'buttonKeyPressed=${action.buttonKeyPressed}'}',
    );
    if (action == null) return;
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => NotificationPage(action: action)),
      (route) => route.isFirst,
    );
  }

  // Listeners must be static / top-level and annotated with vm:entry-point.

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification received,
  ) async {
    _showEventSnackBar('Created #${received.id}', Colors.green);
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification received,
  ) async {
    _showEventSnackBar('Displayed #${received.id}', Colors.blue);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    // A reply typed in the notification: "send" it, then add it to the
    // conversation (Android stops showing the sending indicator).
    final conversationId = AwesomeNotificationsChat.conversationIdOf(action);
    if (action.buttonKeyPressed == 'REPLY' && conversationId != null) {
      final text = action.buttonKeyInput;
      if (text.isNotEmpty) {
        await AwesomeNotificationsChat().addReply(
          conversationId,
          NotificationMessage(sender: me, text: text),
        );
      }
      _showEventSnackBar('Replied: $text', Colors.orange);
      return;
    }
    _showEventSnackBar('Action #${action.id}', Colors.orange);
    // Open the details page when the user taps the notification.
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => NotificationPage(action: action)),
      (route) => route.isFirst,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction action,
  ) async {
    _showEventSnackBar('Dismissed #${action.id}', Colors.red);
  }

  // Shows a notification event as a colored snackbar.
  static void _showEventSnackBar(String message, Color color) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  ///  *********************************************
  ///     REQUESTING PERMISSIONS
  ///  *********************************************
  ///
  /// Shows a short rationale before the system permission prompt.
  static Future<bool> requestPermission(BuildContext context) async {
    final userAuthorized = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Get Notified!'),
        content: const Text(
          'Allow Awesome Notifications to send you beautiful notifications!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Deny', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow', style: TextStyle(color: mainColor)),
          ),
        ],
      ),
    );

    if (userAuthorized != true) return false;
    return AwesomeNotifications().requestPermissionToSendNotifications();
  }

  ///  *********************************************
  ///     CHAT MESSAGES
  ///  *********************************************
  static final NotificationActionButton _reply = NotificationActionButton(
    key: 'REPLY',
    label: 'Reply',
    requireInputText: true,
    actionType: ActionType.SilentAction,
  );

  static int _sent = 0;

  // A one-to-one conversation: every message joins the same notification.
  static Future<void> messageFromAna() {
    const texts = [
      'Hi! Are you coming?',
      'I saved you a seat',
      'Text me when you arrive',
    ];
    final text = texts[_sent++ % texts.length];
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: channelKey,
        notificationLayout: NotificationLayout.Messaging,
      ),
      actionButtons: [_reply],
      extensions: [
        NotificationConversation(
          id: 'ana',
          me: me,
          participants: const [ana],
          message: NotificationMessage(sender: ana, text: text),
        ),
      ],
    );
  }

  // A group conversation with a title and several senders.
  static Future<void> messageInGroup() {
    final fromAna = _sent++ % 2 == 0;
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: channelKey,
        notificationLayout: NotificationLayout.MessagingGroup,
      ),
      actionButtons: [_reply],
      extensions: [
        NotificationConversation(
          id: 'awesome-team',
          title: 'Awesome team',
          image: '$_imagesRoot/awn-rocks-en.jpg',
          me: me,
          participants: const [ana, bot],
          message: fromAna
              ? const NotificationMessage(
                  sender: ana,
                  text: 'Release notes are ready',
                )
              : const NotificationMessage(
                  sender: bot,
                  text: 'Build #128 passed',
                ),
        ),
      ],
    );
  }

  static Future<void> markGroupAsRead() =>
      AwesomeNotificationsChat().markAsRead('awesome-team');

  static Future<void> markAnaAsRead() =>
      AwesomeNotificationsChat().markAsRead('ana');

  // Dismiss removes the notifications from the status bar (keeps any schedule).
  static Future<void> dismissNotifications() {
    return AwesomeNotifications().dismissAllNotifications();
  }

  // Cancel removes the notifications AND cancels their schedule.
  static Future<void> cancelNotifications() {
    return AwesomeNotifications().cancelAll();
  }
}

///  *********************************************
///     MAIN WIDGET
///  *********************************************
///
class MyApp extends StatelessWidget {
  final Future<bool> awesomeNotificationsInitialization;

  const MyApp({super.key, required this.awesomeNotificationsInitialization});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Notifications Chat - Simple Example',
      navigatorKey: NotificationController.navigatorKey,
      scaffoldMessengerKey: NotificationController.scaffoldMessengerKey,
      theme: ThemeData(colorSchemeSeed: mainColor, useMaterial3: true),
      // Show a simple splash until the plugin finished initializing.
      home: FutureBuilder<bool>(
        future: awesomeNotificationsInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _SplashScreen();
          }
          return const HomePage();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: mainColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active, size: 72, color: Colors.white),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

///  *********************************************
///     HOME PAGE
///  *********************************************
///
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    NotificationController.startListeningNotificationEvents();
    // Handle a notification tap that launched the app from a killed state.
    NotificationController.handleInitialAction();
    AwesomeNotifications().isNotificationAllowed().then(
      (allowed) => setState(() => _allowed = allowed),
    );
  }

  Future<void> _requestPermission() async {
    final allowed = await NotificationController.requestPermission(context);
    setState(() => _allowed = allowed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        title: const Text('Awesome Notifications Chat'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const _SectionDivisor('Permission'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _allowed ? Icons.notifications_active : Icons.notifications_off,
                color: mainColor,
              ),
              const SizedBox(width: 8),
              Text(
                _allowed
                    ? 'Notifications are allowed.'
                    : 'Notifications are not allowed yet.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _WideButton(
            'Allow notifications',
            enabled: !_allowed,
            backgroundColor: mainColor,
            labelColor: Colors.white,
            onPressed: _requestPermission,
          ),
          const _SectionDivisor('Push (FCM token)'),
          ValueListenableBuilder<String>(
            valueListenable: NotificationController.fcmToken,
            builder: (context, token, _) => SelectableText(
              token.isEmpty ? 'Waiting for the token…' : token,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const _SectionDivisor('Conversations'),
          _WideButton(
            'Message from Ana',
            onPressed: NotificationController.messageFromAna,
          ),
          _WideButton(
            'Message in the group',
            onPressed: NotificationController.messageInGroup,
          ),
          const _SectionDivisor('Mark as read'),
          _WideButton(
            'Ana\'s conversation',
            onPressed: NotificationController.markAnaAsRead,
          ),
          _WideButton(
            'Group conversation',
            onPressed: NotificationController.markGroupAsRead,
          ),
          _WideButton(
            'Cancel notifications',
            onPressed: NotificationController.cancelNotifications,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

///  *********************************************
///     REUSABLE WIDGETS (inlined to keep this a single-file example)
///  *********************************************
///
/// A section title between two divider lines.
class _SectionDivisor extends StatelessWidget {
  final String title;

  const _SectionDivisor(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }
}

/// A full-width button matching the example's style.
class _WideButton extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? labelColor;
  final bool enabled;
  final VoidCallback? onPressed;

  const _WideButton(
    this.label, {
    this.backgroundColor,
    this.labelColor,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: enabled
                ? (labelColor ?? Colors.black87)
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

///  *********************************************
///     NOTIFICATION DETAILS PAGE
///  *********************************************
///
/// Opened when a notification is tapped. Mirrors the original example's page: a
/// stretchy, collapsing big-picture header with the large icon overlaid, the
/// title/body, and the raw received action at the bottom.
class NotificationPage extends StatefulWidget {
  final ReceivedAction action;

  const NotificationPage({super.key, required this.action});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const String _placeholder =
      'https://cdn.syncfusion.com/content/images/common/placeholder.gif';

  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  ReceivedAction get action => widget.action;
  bool get hasTitle => action.title?.isNotEmpty ?? false;
  bool get hasBody => action.body?.isNotEmpty ?? false;
  bool get hasLargeIcon => action.largeIconImage != null;
  bool get hasBigPicture => action.bigPictureImage != null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final pastLimit =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240;
    if (!hasBigPicture) return;
    if (_isCollapsed != pastLimit) {
      setState(() => _isCollapsed = pastLimit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bigPictureSize = MediaQuery.of(context).size.height * 0.4;
    final double largeIconSize =
        MediaQuery.of(context).size.height * (hasBigPicture ? 0.16 : 0.2);
    final bool overImage = hasBigPicture && !_isCollapsed;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            elevation: 0,
            pinned: true,
            stretch: true,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            systemOverlayStyle: overImage
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: overImage ? Colors.white : Colors.black,
              ),
            ),
            expandedHeight: hasBigPicture
                ? bigPictureSize + (hasLargeIcon ? 40 : 0)
                : (hasLargeIcon
                      ? largeIconSize + 10
                      : MediaQuery.of(context).padding.top + 28),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              centerTitle: true,
              expandedTitleScale: 1,
              collapseMode: CollapseMode.pin,
              title: !hasLargeIcon
                  ? null
                  : Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: hasBigPicture
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: largeIconSize,
                                width: largeIconSize,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    largeIconSize,
                                  ),
                                  child: FadeInImage(
                                    placeholder: const NetworkImage(
                                      _placeholder,
                                    ),
                                    image: action.largeIconImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              background: !hasBigPicture
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(bottom: hasLargeIcon ? 60 : 20),
                      child: FadeInImage(
                        placeholder: const NetworkImage(_placeholder),
                        image: action.bigPictureImage!,
                        height: bigPictureSize,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle)
                      Text(
                        action.title!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if (hasBody) ...[
                      const SizedBox(height: 16),
                      Text(
                        action.bodyWithoutHtml ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.black12,
                padding: const EdgeInsets.all(20),
                child: Text(action.toString()),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
