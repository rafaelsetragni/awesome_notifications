import 'package:flutter/material.dart';

class LedLight extends StatelessWidget {
  final bool isOn;

  const LedLight(this.isOn, {super.key});

  @override
  Widget build(BuildContext context) {
    final Color lightColor = isOn ? Colors.green : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Container(
        width: 16.0,
        height: 16.0,
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: lightColor.withValues(alpha: 0.5),
              spreadRadius: 4,
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
