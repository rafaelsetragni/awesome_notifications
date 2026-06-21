// Minimal, self-contained Awesome Notifications example.
//
// Copy this file into your app's `lib/main.dart`, add `awesome_notifications`
// to your pubspec.yaml and run. It covers the essentials: initialize, request
// permission, create a notification (with a big picture + large icon), dismiss
// it, and open a details page when the user taps it.
//
// For a full-featured demo (dismiss vs cancel, dismiss concepts, the
// localizations decorator, …) see `examples/complete_example` in the repository.
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

const String channelKey = 'alerts';
const Color mainColor = Color(0xFF9D50DD);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize with at least one channel. Keep the Future so the UI can wait
  //    for it: creating a notification before initialize completes can fail.
  final Future<bool> awesomeNotificationsInitialization =
      NotificationController.initializeLocalNotifications();

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
          channelName: 'Alerts',
          channelDescription: 'Notification tests as alerts',
          defaultColor: mainColor,
          ledColor: mainColor,
          importance: NotificationImportance.High,
        ),
      ],
      debug: true,
    );
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
  ///     CREATE — BASIC (text only)
  ///  *********************************************
  // Title + body.
  static Future<void> createTitleAndBody() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: channelKey,
        title: 'Simple notification',
        body: 'Notification with a title and a body.',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  // Title only.
  static Future<void> createTitleOnly() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: channelKey,
        title: 'Notification with a title only',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  // Body only.
  static Future<void> createBodyOnly() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: channelKey,
        body: 'Notification with a body only.',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  // Neither title nor body (only a payload).
  static Future<void> createWithoutTitleAndBody() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 4,
        channelKey: channelKey,
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  ///  *********************************************
  ///     CREATE — IMAGE SOURCES
  ///  *********************************************
  // Same media/links used by the original complete example. We demonstrate the
  // assetless image sources here (network + file); `asset://` and
  // `resource://` are also supported but require bundled media (see the
  // complete_example in the repository).
  static const String _networkImage =
      'https://media.wired.com/photos/598e35994ab8482c0d6946e0/master/w_2560%2Cc_limit/phonepicutres-TA.jpg';
  static const String _largeIcon =
      'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg';

  // Network image (https://).
  static Future<void> createImageFromNetwork() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 11,
        channelKey: channelKey,
        title: 'Big picture (Network)',
        body: 'Image loaded from an https:// URL.',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: _networkImage,
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  // Local file (file://) — download an image to a temp file first, using only
  // dart:io (no extra dependencies), then show it from disk.
  static Future<void> createImageFromFile() async {
    final filePath = '${Directory.systemTemp.path}/awesome_bigpicture.jpg';
    final request = await HttpClient().getUrl(Uri.parse(_networkImage));
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (buffer, chunk) => buffer..addAll(chunk),
    );
    await File(filePath).writeAsBytes(bytes);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 13,
        channelKey: channelKey,
        title: 'Big picture (File)',
        body: 'Image read from a file on disk.',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'file://$filePath',
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  // A notification with a large icon (logo) shown beside the text.
  static Future<void> createWithLogo() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 21,
        channelKey: channelKey,
        title: 'Large icon (logo)',
        body: 'A large icon (logo) is shown next to the text.',
        largeIcon: _largeIcon,
        roundedLargeIcon: true,
        payload: {'uuid': 'uuid-test'},
      ),
    );
  }

  ///  *********************************************
  ///     CREATE — ACTION BUTTONS
  ///  *********************************************
  // Buttons rendered under the notification. The pressed key (and any typed
  // reply) arrives in the ReceivedAction handled by onActionReceivedMethod.
  static Future<void> createWithActionButtons() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 31,
        channelKey: channelKey,
        title: 'Action buttons',
        body: 'Tap a button below.',
        payload: {'uuid': 'uuid-test'},
      ),
      actionButtons: [
        NotificationActionButton(key: 'ACCEPT', label: 'Accept'),
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          requireInputText: true,
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
          isDangerousOption: true,
        ),
      ],
    );
  }

  ///  *********************************************
  ///     DISMISS / CANCEL
  ///  *********************************************
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
      title: 'Awesome Notifications - Simple Example',
      navigatorKey: NotificationController.navigatorKey,
      scaffoldMessengerKey: NotificationController.scaffoldMessengerKey,
      theme: ThemeData(
        colorSchemeSeed: mainColor,
        useMaterial3: true,
      ),
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
        title: const Text('Awesome Notifications Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const _SectionDivisor('Permission'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _allowed
                    ? Icons.notifications_active
                    : Icons.notifications_off,
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
          const _SectionDivisor('Basic notifications'),
          _WideButton(
            'Title and body',
            onPressed: NotificationController.createTitleAndBody,
          ),
          _WideButton(
            'Title only',
            onPressed: NotificationController.createTitleOnly,
          ),
          _WideButton(
            'Body only',
            onPressed: NotificationController.createBodyOnly,
          ),
          _WideButton(
            'Without title and body',
            onPressed: NotificationController.createWithoutTitleAndBody,
          ),
          const _SectionDivisor('Image sources'),
          _WideButton(
            'Big picture from network',
            onPressed: NotificationController.createImageFromNetwork,
          ),
          _WideButton(
            'Big picture from file',
            onPressed: NotificationController.createImageFromFile,
          ),
          _WideButton(
            'Large icon (logo)',
            onPressed: NotificationController.createWithLogo,
          ),
          const _SectionDivisor('Action buttons'),
          _WideButton(
            'Notification with action buttons',
            onPressed: NotificationController.createWithActionButtons,
          ),
          const _SectionDivisor('Dismiss vs Cancel'),
          Text(
            'Dismiss only removes the notification from the status bar. '
            'Cancel does the same AND cancels its schedule.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _WideButton(
            'Dismiss notifications',
            onPressed: NotificationController.dismissNotifications,
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
            color: enabled ? (labelColor ?? Colors.black87) : Colors.grey.shade500,
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
            systemOverlayStyle:
                overImage ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                      padding:
                          EdgeInsets.only(bottom: hasLargeIcon ? 60 : 20),
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
                padding:
                    const EdgeInsets.only(bottom: 20, left: 20, right: 20),
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
