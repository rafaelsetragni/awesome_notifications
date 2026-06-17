import 'package:flutter/material.dart';
import 'package:awesome_notifications_example/common_widgets/remarkable_divisor.dart';

class TextDivisor extends StatelessWidget {
  final String title;

  TextDivisor({this.title = ''});

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Padding(
        padding: EdgeInsets.only(top: 20, bottom: 20),
        child: title.isNotEmpty ?
        Row(
            children: <Widget>[
              Expanded(
                  child: RemarkableDivisor()
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: mediaQueryData.size.width / 2),
                    child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  )
              ),
              Expanded(
                  child: RemarkableDivisor()
              ),
            ]
        ):
        RemarkableDivisor()
    );
  }
}
