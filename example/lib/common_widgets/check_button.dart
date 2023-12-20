import 'package:flutter/material.dart';

class CheckButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final void Function(bool)? onPressed;

  const CheckButton(
    this.label,
    this.isSelected, {
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(
            width: mediaQueryData.size.width - 110 /* 30 - 60 - 20 */,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          SizedBox(
            width: 60,
            child: Switch(
              value: isSelected,
              onChanged: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
