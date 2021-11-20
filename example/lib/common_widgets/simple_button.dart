import 'package:flutter/material.dart';

class SimpleButton extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final Color? backgroundColor;
  final double? width;
  final void Function()? onPressed;
  final bool enabled;

  const SimpleButton(
    this.label, {
    Key? key,
    this.labelColor,
    this.backgroundColor,
    this.width,
    this.onPressed,
    this.enabled = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 5),
        child: ElevatedButton(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
            child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: (labelColor ?? Colors.black87).withAlpha( enabled ? 255 : 60 )
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: backgroundColor ?? Colors.grey.shade200,
            textStyle: TextStyle(
              color: labelColor ?? Colors.black87
            )
          ),
          onPressed: enabled ? onPressed : null
        )
    );
  }
}
