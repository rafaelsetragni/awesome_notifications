import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awesome_notifications_example/common_widgets/simple_button.dart';
import 'package:awesome_notifications_example/datasources/firebase_datasource.dart';
import 'package:awesome_notifications_example/main.dart';

class FirebaseTestPage extends StatefulWidget {
  final String firebaseAppToken;
  final String packageName = 'me.carda.awesome_notifications_example';
  final String sharedLastKeyReference = 'FcmServerKey';

  FirebaseTestPage(this.firebaseAppToken);

  final FirebaseDataSource firebaseDataSource = FirebaseDataSource();

  @override
  _FirebaseTestPageState createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverKeyTextController;

  @override
  void initState() {
    super.initState();
  }

  String? serverKeyValidation(value) {
    if (value.isEmpty) {
      return 'The FCM server key is required';
    }

    if (!RegExp(r'^[A-z0-9\:\-\_]{150,}$').hasMatch(value)) {
      return 'Enter Valid FCM server key';
    }

    return null;
  }

  Future<String> getLastServerKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(widget.sharedLastKeyReference) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Firebase Push Test', style: TextStyle(fontSize: 20)),
          elevation: 10,
        ),
        body: FutureBuilder<String>(
          future: getLastServerKey(),
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(App.mainColor),
              ));
            } else {
              String lastServerKey = snapshot.data ?? '';
              _serverKeyTextController =
                  TextEditingController(text: lastServerKey);
              return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  children: <Widget>[
                    Text('Firebase App Token:'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Text(widget.firebaseAppToken,
                          style: TextStyle(color: App.mainColor)),
                    ),
                    SimpleButton(
                      'Copy Firebase app token',
                      onPressed: () async {
                        if (widget.firebaseAppToken.isNotEmpty) {
                          Clipboard.setData(
                              ClipboardData(text: widget.firebaseAppToken));
                          Fluttertoast.showToast(msg: 'Token copied');
                        }
                      },
                    ),
                    SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              minLines:
                                  1, //Normal textInputField will be displayed
                              maxLines:
                                  5, // when user presses enter it will adapt to it
                              keyboardType: TextInputType.multiline,
                              controller: _serverKeyTextController,
                              validator: serverKeyValidation,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock),
                                  labelText: ' Firebase Server Key ',
                                  hintText:
                                      'Paste here your Firebase server Key'),
                            )
                          ],
                        ),
                      ),
                    ),
                    Text(MapUtils.printPrettyMap(widget.firebaseDataSource
                        .getFirebaseExampleContent(
                            firebaseAppToken:
                                _serverKeyTextController.value.text))),
                    SimpleButton(
                      'Send Firebase request',
                      onPressed: () async {
                        String fcmServerKey =
                            _serverKeyTextController.value.text;
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setString(
                            widget.sharedLastKeyReference, fcmServerKey);

                        if (_formKey.currentState?.validate() ?? false) {
                          FocusScopeNode currentFocus = FocusScope.of(context);
                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }

                          pushFirebaseNotification(1, fcmServerKey);
                        }
                      },
                    )
                  ]);
            }
          },
        ));
  }

  Future<String> pushFirebaseNotification(
      int id, String firebaseServerKey) async {
    return await widget.firebaseDataSource.pushBasicNotification(
        firebaseServerKey: firebaseServerKey,
        firebaseAppToken: widget.firebaseAppToken,
        notificationId: id,
        title: 'Notification through firebase',
        body:
            'This notification was sent through firebase messaging cloud services.',
        payload: {'uuid': 'testPayloadKey'});
  }
}
