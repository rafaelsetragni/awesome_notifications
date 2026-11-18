import 'package:flutter/material.dart';

// Host app for the black-box compat suite; the tests live in integration_test/.
void main() => runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('compat')))));
