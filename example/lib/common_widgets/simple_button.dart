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
    super.key,
    this.labelColor,
    this.backgroundColor,
    this.width,
    this.onPressed,
    this.enabled = true
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            textStyle: TextStyle(
              color: labelColor ?? Colors.black87
            )
          ),
          onPressed: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
            child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: (labelColor ?? Colors.black87).withAlpha( enabled ? 255 : 60 )
              ),
            ),
          )
        )
    );
  }
}
