import 'package:flutter/material.dart';
import 'package:awesome_notifications_example/common_widgets/led_light.dart';
import 'package:awesome_notifications_example/common_widgets/simple_button.dart';

class ServiceControlPanel extends StatelessWidget {
  final String title;
  final bool statusControl;
  final ThemeData themeData;
  final void Function()? onPressed;

  const ServiceControlPanel(
    this.title,
    this.statusControl,
    this.themeData, {
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);

    return Container(
      width: mediaQueryData.size.width * 0.4,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  style: TextStyle(color: Colors.black87),
                  text: '$title status:\n',
                  children: [
                    TextSpan(
                        style: TextStyle(
                            color: statusControl
                                ? Colors.green
                                : Colors.redAccent),
                        text: (statusControl ? 'Available' : 'Unavailable') +
                            '\n'),
                    WidgetSpan(child: LedLight(statusControl))
                  ]),
            ),
          ),
          SimpleButton('Go to $title\nTest Page',
              width: mediaQueryData.size.width * 0.4,
              labelColor:
                  statusControl ? themeData.hintColor : themeData.disabledColor,
              onPressed: statusControl ? onPressed : null),
        ],
      ),
    );
  }
}
