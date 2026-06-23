import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../common_widgets/led_light.dart';
import '../common_widgets/simple_button.dart';
import '../common_widgets/text_divisor.dart';

/// Main page with the test options, following the original example's style
/// (ListView of TextDivisor sections + full-width SimpleButtons). Notification
/// events are surfaced as snackbars (see main.dart).
class HomePage extends StatefulWidget {
  final String channelKey;

  const HomePage({super.key, required this.channelKey});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _bigPicture =
      'https://media.wired.com/photos/598e35994ab8482c0d6946e0/master/w_2560%2Cc_limit/phonepicutres-TA.jpg';
  static const String _largeIcon =
      'https://image.freepik.com/vetores-gratis/modelo-de-logotipo-de-restaurante-retro_23-2148451519.jpg';

  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().isNotificationAllowed().then((allowed) {
      if (mounted) setState(() => _allowed = allowed);
    });
  }

  Future<void> _requestPermission() async {
    final allowed =
        await AwesomeNotifications().requestPermissionToSendNotifications();
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _basic() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: widget.channelKey,
          title: 'Basic notification',
          body: 'A simple title + body notification.',
        ),
      );

  Future<void> _withImageAndPayload() =>
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: widget.channelKey,
          title: 'Notification with image',
          body: 'Tap me to open the details page with the picture and payload.',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: _bigPicture,
          largeIcon: _largeIcon,
          payload: {'page': 'details', 'itemId': '1062', 'from': 'home'},
        ),
      );

  Future<void> _payloadOnly() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 3,
          channelKey: widget.channelKey,
          title: 'Notification with payload',
          body: 'No image; tap to inspect the payload.',
          payload: {'secret': '42', 'origin': 'payload-only'},
        ),
      );

  // Auto-dismiss concept: stays in the tray after a tap (Android).
  Future<void> _keepOnTap() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 4,
          channelKey: widget.channelKey,
          title: 'Stays after tap',
          body: 'autoDismissible: false — tapping keeps it on the tray (Android).',
          autoDismissible: false,
          payload: {'origin': 'keep-on-tap'},
        ),
      );

  // DismissAction concept: a tap dismisses it and fires onDismissActionReceived.
  Future<void> _dismissOnTap() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 5,
          channelKey: widget.channelKey,
          title: 'Dismiss on tap',
          body: 'actionType DismissAction — tapping dismisses it and fires '
              'onDismissActionReceived.',
          actionType: ActionType.DismissAction,
          payload: {'origin': 'dismiss-action'},
        ),
      );

  // Localizations decorator: the same notification declared in every language;
  // translated at build time (text, images and button labels) to the language
  // set with setLocalization.
  Future<void> _localized() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 6,
          channelKey: widget.channelKey,
          title: 'This title is written in english',
          body: 'Now it is really easy to translate a notification content, '
              'including images and buttons!',
          summary: 'Awesome Notifications Translations',
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: 'asset://assets/images/awn-rocks-en.jpg',
          largeIcon: 'asset://assets/images/american.jpg',
          payload: {'origin': 'localized'},
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
            buttonLabels: {
              'AGREED1': 'Eu concordo!',
              'AGREED2': 'Eu concordo também!'
            },
          ),
          'pt': NotificationLocalization(
            title: 'Este título está escrito em português de Portugal!',
            body: 'Agora é muito fácil traduzir o conteúdo das notificações, '
                'incluindo imagens e botões!',
            summary: 'Traduções Awesome Notifications',
            bigPicture: 'asset://assets/images/awn-rocks-pt.jpg',
            largeIcon: 'asset://assets/images/portuguese.jpg',
            buttonLabels: {
              'AGREED1': 'Eu concordo!',
              'AGREED2': 'Eu concordo também!'
            },
          ),
          'es': NotificationLocalization(
            title: 'Este título está escrito en español!',
            body: 'Ahora es muy fácil traducir el contenido de las '
                'notificaciones, incluyendo imágenes y botones.',
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
            body: 'Jetzt ist es wirklich einfach, den Inhalt einer '
                'Benachrichtigung zu übersetzen, einschließlich Bilder und '
                'Schaltflächen!',
            bigPicture: 'asset://assets/images/awn-rocks-de.jpg',
            largeIcon: 'asset://assets/images/german.jpg',
            buttonLabels: {
              'AGREED1': 'Ich stimme zu',
              'AGREED2': 'Ich stimme auch zu'
            },
          ),
        },
      );

  // Title/body come from app string resources (titleLocKey/bodyLocKey) resolved
  // for the current language; images and button labels come from the block.
  Future<void> _localizedKeys() => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 6,
          channelKey: widget.channelKey,
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
          payload: {'origin': 'localized-keys'},
        ),
        actionButtons: [
          NotificationActionButton(key: 'AGREED1', label: 'I agree'),
          NotificationActionButton(key: 'AGREED2', label: 'I agree too'),
        ],
        localizations: {
          'pt-br': NotificationLocalization(
            bigPicture: 'asset://assets/images/awn-rocks-pt-br.jpg',
            largeIcon: 'asset://assets/images/brazilian.jpg',
            buttonLabels: {
              'AGREED1': 'Eu concordo!',
              'AGREED2': 'Eu concordo também!'
            },
          ),
          'pt': NotificationLocalization(
            bigPicture: 'asset://assets/images/awn-rocks-pt.jpg',
            largeIcon: 'asset://assets/images/portuguese.jpg',
            buttonLabels: {
              'AGREED1': 'Eu concordo!',
              'AGREED2': 'Eu concordo também!'
            },
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
            buttonLabels: {
              'AGREED1': 'Ich stimme zu',
              'AGREED2': 'Ich stimme auch zu'
            },
          ),
        },
      );

  // Sets the decorator's target language (null = system default).
  Future<void> _setLanguage(String? code) =>
      AwesomeNotifications().setLocalization(languageCode: code);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Awesome Notifications')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          TextDivisor(title: 'Global Permission to send Notifications'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LedLight(_allowed),
                const SizedBox(height: 4),
                Text(
                  'Notifications are ${_allowed ? 'allowed' : 'not allowed'}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SimpleButton(
            'Request permission to send notifications',
            enabled: !_allowed,
            backgroundColor: Colors.deepPurple,
            labelColor: Colors.white,
            onPressed: _requestPermission,
          ),
          TextDivisor(title: 'Basic Notifications'),
          SimpleButton('Show the most basic notification', onPressed: _basic),
          SimpleButton('Show notification with image and payload',
              onPressed: _withImageAndPayload),
          SimpleButton('Show notification with payload',
              onPressed: _payloadOnly),
          TextDivisor(title: 'Dismiss vs Cancel'),
          Text(
            'Dismiss only removes the notification from the status bar. '
            'Cancel does the same AND cancels its schedule.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SimpleButton('Dismiss the basic notification (#1)',
              onPressed: () => AwesomeNotifications().dismiss(1)),
          SimpleButton('Cancel the basic notification (#1)',
              onPressed: () => AwesomeNotifications().cancel(1)),
          SimpleButton('Dismiss all notifications',
              onPressed: () =>
                  AwesomeNotifications().dismissAllNotifications()),
          SimpleButton('Cancel all notifications',
              onPressed: () => AwesomeNotifications().cancelAll()),
          TextDivisor(title: 'Dismiss concepts'),
          SimpleButton('Keep on tray after tap (autoDismissible: false)',
              onPressed: _keepOnTap),
          SimpleButton('Dismiss on tap (DismissAction)',
              onPressed: _dismissOnTap),
          TextDivisor(title: 'Localizations (decorator)'),
          SimpleButton('Show localized notification', onPressed: _localized),
          SimpleButton('Show notification using localization Keys',
              onPressed: _localizedKeys),
          const SizedBox(height: 16),
          SimpleButton('Set language: system default',
              onPressed: () => _setLanguage(null)),
          SimpleButton('Set language: English 🇺🇸',
              onPressed: () => _setLanguage('en')),
          SimpleButton('Set language: Brazilian Portuguese 🇧🇷',
              onPressed: () => _setLanguage('pt-br')),
          SimpleButton('Set language: Portuguese 🇵🇹',
              onPressed: () => _setLanguage('pt')),
          SimpleButton('Set language: Spanish 🇪🇸',
              onPressed: () => _setLanguage('es')),
          SimpleButton('Set language: Chinese 🇨🇳',
              onPressed: () => _setLanguage('zh')),
          SimpleButton('Set language: Korean 🇰🇷',
              onPressed: () => _setLanguage('ko')),
          SimpleButton('Set language: German 🇩🇪',
              onPressed: () => _setLanguage('de')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
