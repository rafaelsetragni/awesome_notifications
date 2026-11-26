import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

const Color mainColor = Color(0xFF9D50DD);

/// Single-file demo of awesome_notifications_fcm.
///
/// Prerequisites (Firebase is required for push):
///  * Android: add `android/app/google-services.json` and apply the
///    `com.google.gms.google-services` Gradle plugin.
///  * iOS: add `GoogleService-Info.plist`, enable Push Notifications +
///    Background Modes (Remote notifications) capabilities.
///
/// The FCM handlers MUST be top-level / static functions so the background
/// isolate can resolve them while the app is terminated.

/// Receives the Firebase Cloud Messaging token (and its refreshes).
Future<void> onFcmTokenReceived(String token) async {
  debugPrint('FCM token: $token');
}

/// Receives the raw native (APNs) token — iOS only.
Future<void> onNativeTokenReceived(String token) async {
  debugPrint('Native token: $token');
}

/// Handles silent (data-only) pushes, even while the app is terminated.
@pragma('vm:entry-point')
Future<void> onSilentDataReceived(FcmSilentData silentData) async {
  debugPrint(
      'Silent data: ${silentData.data} (source: ${silentData.createdSource})');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await AwesomeNotifications().initialize(
    // The status bar icon: a white glyph on transparent (Android draws only
    // its alpha). Without it, the full-color app icon shows as a square.
    'resource://drawable/res_notification_icon',
    [
      NotificationChannel(
        channelKey: 'push',
        channelName: 'Push notifications',
        channelDescription: 'Notifications delivered through Firebase',
        importance: NotificationImportance.High,
      ),
    ],
  );

  await AwesomeNotificationsFcm().initialize(
    onFcmTokenHandle: onFcmTokenReceived,
    onNativeTokenHandle: onNativeTokenReceived,
    onFcmSilentDataHandle: onSilentDataReceived,
    debug: true,
  );

  runApp(const FcmExampleApp());
}

///  *********************************************
///     NOTIFICATION CONTROLLER
///  *********************************************
///
/// Tapping a push (or one of its buttons) arrives here like any local
/// notification action, and opens the details page.
class NotificationController {
  // Lets the (static) action listener open a page from anywhere.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Lets the (static) event listeners show snackbars from anywhere.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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
    debugPrint('getInitialNotificationAction -> '
        '${action == null ? 'null (no launch action)' : 'id=${action.id} '
            'channelKey=${action.channelKey} '
            'buttonKeyPressed=${action.buttonKeyPressed}'}');
    if (action == null) return;
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => NotificationPage(action: action)),
      (route) => route.isFirst,
    );
  }

  // Listeners must be static / top-level and annotated with vm:entry-point.

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification received) async {
    _showEventSnackBar('Created #${received.id}', Colors.green);
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification received) async {
    _showEventSnackBar('Displayed #${received.id}', Colors.blue);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    _showEventSnackBar('Action #${action.id}', Colors.orange);
    // Open the details page when the user taps the notification.
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => NotificationPage(action: action)),
      (route) => route.isFirst,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction action) async {
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
}

class FcmExampleApp extends StatelessWidget {
  const FcmExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Notifications FCM - Simple Example',
      navigatorKey: NotificationController.navigatorKey,
      scaffoldMessengerKey: NotificationController.scaffoldMessengerKey,
      theme: ThemeData(colorSchemeSeed: mainColor, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _allowed = false;
  String _token = '(press "Get token")';
  final _topicController = TextEditingController(text: 'news');

  @override
  void initState() {
    super.initState();
    NotificationController.startListeningNotificationEvents();
    // Handle a push tap that launched the app from a killed state.
    NotificationController.handleInitialAction();
    AwesomeNotifications().isNotificationAllowed().then(
          (allowed) => setState(() => _allowed = allowed),
        );
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  /// Pushes are displayed as local notifications, so they need the permission.
  /// Shows a short rationale before the system permission prompt.
  Future<void> _requestPermission() async {
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
    if (userAuthorized != true) return;
    final allowed =
        await AwesomeNotifications().requestPermissionToSendNotifications();
    setState(() => _allowed = allowed);
  }

  Future<void> _getToken() async {
    final available = await AwesomeNotificationsFcm().isFirebaseAvailable;
    final token = available
        ? await AwesomeNotificationsFcm().requestFirebaseAppToken()
        : 'Firebase not configured';
    setState(() => _token = token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        title: const Text('Awesome Notifications FCM'),
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
              Text(_allowed
                  ? 'Notifications are allowed.'
                  : 'Notifications are not allowed yet.'),
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
          const _SectionDivisor('FCM token'),
          SelectableText(_token, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          _WideButton('Get token', onPressed: _getToken),
          const _SectionDivisor('Topics'),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: 'Topic'),
          ),
          const SizedBox(height: 8),
          _WideButton(
            'Subscribe',
            onPressed: () => AwesomeNotificationsFcm()
                .subscribeToTopic(_topicController.text),
          ),
          _WideButton(
            'Unsubscribe',
            onPressed: () => AwesomeNotificationsFcm()
                .unsubscribeToTopic(_topicController.text),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

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
            color:
                enabled ? (labelColor ?? Colors.black87) : Colors.grey.shade500,
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
    final pastLimit = _scrollController.position.pixels >=
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
                                  borderRadius:
                                      BorderRadius.circular(largeIconSize),
                                  child: FadeInImage(
                                    placeholder:
                                        const NetworkImage(_placeholder),
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
