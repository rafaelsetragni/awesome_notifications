// Example for the awesome_notifications_localizations decorator.
//
// Same skeleton as the base awesome_notifications example — the difference is
// the test buttons: here they exercise the localization feature. Just by
// depending on this package, notifications are translated at build time on the
// native side, according to the language set with setLocalization.
//
// NOTE: the native translation is currently Android-only — on iOS the decorator
// is a no-op placeholder, so the default (untranslated) content is shown there.
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

const String channelKey = 'alerts';
const Color mainColor = Color(0xFF9D50DD);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
class NotificationController {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  ///  *********************************************
  ///     INITIALIZATION
  ///  *********************************************
  static Future<bool> initializeLocalNotifications() {
    return AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Alerts',
          channelDescription: 'Localized notification tests',
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
  static Future<void> startListeningNotificationEvents() {
    return AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

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
  ///     LOCALIZATION
  ///  *********************************************
  /// Sets the language the decorator translates notifications into.
  static Future<bool> setLanguage(String? languageCode) async {
    try {
      await AwesomeNotifications().setLocalization(languageCode: languageCode);
      _showEventSnackBar('Language: ${languageCode ?? 'system default'}',
          mainColor);
      return true;
    } catch (_) {
      // The decorator is not wired on iOS yet (no handler registered there).
      _showEventSnackBar('Localization is Android-only for now', Colors.orange);
      return false;
    }
  }

  /// The same notification declared in every language: the decorator picks the
  /// content matching the current language at build time, translating the text,
  /// the images and the action button labels.
  static Future<void> showLocalizedNotification() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: channelKey,
        title: 'This title is written in english',
        body: 'Now it is really easy to translate a notification content, '
            'including images and buttons!',
        summary: 'Awesome Notifications Translations',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/awn-rocks-en.jpg',
        largeIcon: 'asset://assets/images/american.jpg',
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(key: 'AGREED1', label: 'I agree'),
        NotificationActionButton(key: 'AGREED2', label: 'I agree too'),
      ],
      localizations: {
        'pt-br': NotificationLocalization(
          title: 'Este título está escrito em português do Brasil!',
          body: 'Agora é muito fácil traduzir o conteúdo das notificações, '
              'incluindo imagens e botões!',
          summary: 'Traduções Awesome Notifications',
          bigPicture: 'asset://assets/images/awn-rocks-pt-br.jpg',
          largeIcon: 'asset://assets/images/brazilian.jpg',
          buttonLabels: {'AGREED1': 'Eu concordo!', 'AGREED2': 'Eu concordo também!'},
        ),
        'pt': NotificationLocalization(
          title: 'Este título está escrito em português de Portugal!',
          body: 'Agora é muito fácil traduzir o conteúdo das notificações, '
              'incluindo imagens e botões!',
          summary: 'Traduções Awesome Notifications',
          bigPicture: 'asset://assets/images/awn-rocks-pt.jpg',
          largeIcon: 'asset://assets/images/portuguese.jpg',
          buttonLabels: {'AGREED1': 'Eu concordo!', 'AGREED2': 'Eu concordo também!'},
        ),
        'es': NotificationLocalization(
          title: 'Este título está escrito en español!',
          body: 'Ahora es muy fácil traducir el contenido de las notificaciones, '
              'incluyendo imágenes y botones.',
          summary: 'Traducciones de Awesome Notifications',
          bigPicture: 'asset://assets/images/awn-rocks-es.jpg',
          largeIcon: 'asset://assets/images/spanish.jpg',
          buttonLabels: {
            'AGREED1': 'Estoy de acuerdo',
            'AGREED2': 'También estoy de acuerdo'
          },
        ),
        'zh': NotificationLocalization(
          title: '这个标题是用中文写的',
          body: '现在，轻松翻译通知内容，包括图像和按钮！',
          bigPicture: 'asset://assets/images/awn-rocks-zh.jpg',
          largeIcon: 'asset://assets/images/chinese.jpg',
          buttonLabels: {'AGREED1': '我同意', 'AGREED2': '我也同意'},
        ),
        'ko': NotificationLocalization(
          title: '이 타이틀은 한국어로 작성되었습니다',
          body: '이제 이미지 및 버튼을 포함한 알림 콘텐츠를 쉽게 번역할 수 있습니다!',
          bigPicture: 'asset://assets/images/awn-rocks-ko.jpg',
          largeIcon: 'asset://assets/images/korean.jpg',
          buttonLabels: {'AGREED1': '동의합니다', 'AGREED2': '저도 동의합니다'},
        ),
        'de': NotificationLocalization(
          title: 'Dieser Titel ist in Deutsch geschrieben',
          body: 'Jetzt ist es wirklich einfach, den Inhalt einer Benachrichtigung '
              'zu übersetzen, einschließlich Bilder und Schaltflächen!',
          bigPicture: 'asset://assets/images/awn-rocks-de.jpg',
          largeIcon: 'asset://assets/images/german.jpg',
          buttonLabels: {'AGREED1': 'Ich stimme zu', 'AGREED2': 'Ich stimme auch zu'},
        ),
      },
    );
  }

  /// Same idea, but the title/body come from app string resources referenced by
  /// `titleLocKey`/`bodyLocKey` (resolved for the current language), while the
  /// images and button labels still come from the localizations block.
  static Future<void> showLocalizedWithKeys() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: channelKey,
        title: 'Original title in English',
        body: 'Original body in English',
        titleLocKey: 'not_loc_key',
        bodyLocKey: 'not_loc_key',
        titleLocArgs: ['title'],
        bodyLocArgs: ['body'],
        summary: 'Awesome Notifications Translations',
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/awn-rocks-en.jpg',
        largeIcon: 'asset://assets/images/american.jpg',
        payload: {'uuid': 'user-profile-uuid'},
      ),
      actionButtons: [
        NotificationActionButton(key: 'AGREED1', label: 'I agree'),
        NotificationActionButton(key: 'AGREED2', label: 'I agree too'),
      ],
      localizations: {
        'pt-br': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-pt-br.jpg',
          largeIcon: 'asset://assets/images/brazilian.jpg',
          buttonLabels: {'AGREED1': 'Eu concordo!', 'AGREED2': 'Eu concordo também!'},
        ),
        'pt': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-pt.jpg',
          largeIcon: 'asset://assets/images/portuguese.jpg',
          buttonLabels: {'AGREED1': 'Eu concordo!', 'AGREED2': 'Eu concordo também!'},
        ),
        'es': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-es.jpg',
          largeIcon: 'asset://assets/images/spanish.jpg',
          buttonLabels: {
            'AGREED1': 'Estoy de acuerdo',
            'AGREED2': 'También estoy de acuerdo'
          },
        ),
        'zh': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-zh.jpg',
          largeIcon: 'asset://assets/images/chinese.jpg',
          buttonLabels: {'AGREED1': '我同意', 'AGREED2': '我也同意'},
        ),
        'ko': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-ko.jpg',
          largeIcon: 'asset://assets/images/korean.jpg',
          buttonLabels: {'AGREED1': '동의합니다', 'AGREED2': '저도 동의합니다'},
        ),
        'de': NotificationLocalization(
          bigPicture: 'asset://assets/images/awn-rocks-de.jpg',
          largeIcon: 'asset://assets/images/german.jpg',
          buttonLabels: {'AGREED1': 'Ich stimme zu', 'AGREED2': 'Ich stimme auch zu'},
        ),
      },
    );
  }

  ///  *********************************************
  ///     DISMISS / CANCEL
  ///  *********************************************
  static Future<void> dismissNotifications() {
    return AwesomeNotifications().dismissAllNotifications();
  }

  static Future<void> cancelNotifications() {
    return AwesomeNotifications().cancelAll();
  }
}

// The languages offered by the test buttons (label + flag + code, null = system).
const List<({String label, String? code})> _languages = [
  (label: 'System default', code: null),
  (label: 'English 🇺🇸', code: 'en'),
  (label: 'Brazilian Portuguese 🇧🇷', code: 'pt-br'),
  (label: 'Portuguese 🇵🇹', code: 'pt'),
  (label: 'Spanish 🇪🇸', code: 'es'),
  (label: 'Chinese 🇨🇳', code: 'zh'),
  (label: 'Korean 🇰🇷', code: 'ko'),
  (label: 'German 🇩🇪', code: 'de'),
];

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
      title: 'Awesome Notifications - Localizations',
      navigatorKey: NotificationController.navigatorKey,
      scaffoldMessengerKey: NotificationController.scaffoldMessengerKey,
      theme: ThemeData(colorSchemeSeed: mainColor, useMaterial3: true),
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
            Icon(Icons.translate, size: 72, color: Colors.white),
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
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    NotificationController.startListeningNotificationEvents();
    AwesomeNotifications().isNotificationAllowed().then(
      (allowed) => setState(() => _allowed = allowed),
    );
    AwesomeNotifications().getLocalization().then(
      (code) => setState(() => _language = code),
    );
  }

  Future<void> _requestPermission() async {
    final allowed = await NotificationController.requestPermission(context);
    setState(() => _allowed = allowed);
  }

  Future<void> _setLanguage(String? code) async {
    if (await NotificationController.setLanguage(code)) {
      final current = await AwesomeNotifications().getLocalization();
      setState(() => _language = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        title: const Text('Localizations decorator'),
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
          const _SectionDivisor('Localizations'),
          Text(
            'The same notification is declared in every language; the decorator '
            'translates the text, images and button labels to the language set '
            'below — at build time, on the native side.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _WideButton(
            'Show localized notification',
            backgroundColor: mainColor,
            labelColor: Colors.white,
            onPressed: NotificationController.showLocalizedNotification,
          ),
          _WideButton(
            'Show notification using localization Keys',
            onPressed: NotificationController.showLocalizedWithKeys,
          ),
          const _SectionDivisor('Set language'),
          Text('Current language: $_language',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          for (final lang in _languages)
            _WideButton(
              lang.label,
              enabled: _language != (lang.code ?? _language) || lang.code == null,
              onPressed: () => _setLanguage(lang.code),
            ),
          const _SectionDivisor('Dismiss vs Cancel'),
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
///     REUSABLE WIDGETS (inlined to match the base example)
///  *********************************************
///
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
