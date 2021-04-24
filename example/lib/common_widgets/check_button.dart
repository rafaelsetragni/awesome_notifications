import 'package:flutter/material.dart';

class CheckButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final void Function(bool)? onPressed;

  const CheckButton(
    this.label,
    this.isSelected, {
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: mediaQueryData.size.width - 110 /* 30 - 60 - 20 */,
            child: Text(label, style: TextStyle(fontSize: 16)),
          ),
          Container(
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
