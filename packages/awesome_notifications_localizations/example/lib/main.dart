// Single-file example for the awesome_notifications_localizations decorator.
//
// The decorator adds no Dart API: the localization surface (setLocalization and
// NotificationContent.localizations) lives in the core. Just by depending on
// this package, notifications are translated at build time on the native side.
//
// NOTE: the native translation is currently Android-only — on iOS the decorator
// is a no-op placeholder, so the default (untranslated) text is shown there.
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

const String channelKey = 'alerts';
const Color mainColor = Color(0xFF9D50DD);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final init = AwesomeNotifications().initialize(
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
  runApp(MyApp(initialization: init));
}

class MyApp extends StatelessWidget {
  final Future<bool> initialization;
  const MyApp({super.key, required this.initialization});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Notifications Localizations',
      scaffoldMessengerKey: HomePage.scaffoldMessengerKey,
      theme: ThemeData(colorSchemeSeed: mainColor, useMaterial3: true),
      home: FutureBuilder<bool>(
        future: initialization,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
                ? const HomePage()
                : const Scaffold(
                    backgroundColor: mainColor,
                    body: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().requestPermissionToSendNotifications();
    AwesomeNotifications().getLocalization().then(
      (code) => setState(() => _language = code),
    );
  }

  Future<void> _setLanguage(String code) async {
    try {
      await AwesomeNotifications().setLocalization(languageCode: code);
      setState(() => _language = code);
      _snack('Language set to "$code"', mainColor);
    } catch (_) {
      // The decorator is not wired on iOS yet (no handler registered there).
      _snack('Localization is Android-only for now', Colors.orange);
    }
  }

  // The same notification, translated at build time by the decorator according
  // to the language set above.
  Future<void> _showLocalized() {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: channelKey,
        title: 'Hello',
        body: 'This is the default (en) text.',
      ),
      localizations: {
        'pt': NotificationLocalization(
          title: 'Olá',
          body: 'Este é o texto em português.',
        ),
        'es': NotificationLocalization(
          title: 'Hola',
          body: 'Este es el texto en español.',
        ),
      },
    );
  }

  void _snack(String message, Color color) {
    HomePage.scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        title: const Text('Localizations decorator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Current language: $_language'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  for (final code in const ['en', 'pt', 'es'])
                    ChoiceChip(
                      label: Text(code.toUpperCase()),
                      selected: _language == code,
                      onSelected: (_) => _setLanguage(code),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _showLocalized,
                icon: const Icon(Icons.translate),
                label: const Text('Show localized notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
