import 'package:flutter/material.dart';

class RemarkableText extends StatelessWidget {
  final String text;
  final Color? color;

  const RemarkableText({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: FittedBox(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
