import 'package:flutter/material.dart';

class LedLight extends StatelessWidget {
  final bool isOn;

  const LedLight(this.isOn, {super.key});

  @override
  Widget build(BuildContext context) {
    final Color lightColor = isOn ? Colors.green : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only(top: 25.0, bottom: 25.0),
      child: Container(
        width: 15.0,
        height: 15.0,
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: lightColor.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
