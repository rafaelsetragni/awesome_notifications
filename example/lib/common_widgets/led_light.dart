import 'package:flutter/material.dart';

class LedLight extends StatelessWidget {

  final bool isOn;

  const LedLight(this.isOn, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color lightColor = isOn ? Colors.green : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only( top: 15.0, bottom: 10.0 ),
      child: Container(
          width: 15.0,
          height: 15.0,
          decoration: BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)
              ),
              boxShadow: [
                BoxShadow(
                  color: lightColor.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 1), // changes position of shadow
                ),
              ]
          )
      ),
    );
  }
}
