import 'package:flutter/material.dart';

class TextNote extends StatelessWidget {

  final String text;

  const TextNote(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Column(
        children: <Widget>[
          Row(
              children: <Widget>[
                Expanded(
                    child: Text('Note:',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14 ,
                            fontStyle: FontStyle.italic
                        )
                    )
                )
              ]
          ),
          SizedBox(height: 10),
          Row(
              children: <Widget>[
                Expanded(
                    child: Text(text,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontSize: 14
                        )
                    )
                )
              ]
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
