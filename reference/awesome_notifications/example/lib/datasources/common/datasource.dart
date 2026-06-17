import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

abstract class DataSource {
  @protected
  Future<Response?> fetchData({
    String directory = '',
    Map<String, String>? parameters,
    Map<String, String> headers = const {},
    String body = '',
    int timeoutInMilliseconds = 5000,
  });
}
