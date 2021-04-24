import 'dart:io';

import 'package:http/http.dart' show Client, Response;
import 'package:flutter/cupertino.dart';
import 'package:awesome_notifications_example/utils/common_functions.dart';
import 'datasource.dart';

class HttpDataSource extends DataSource {
  final String baseAPI;
  final bool isUsingHttps;
  final bool isCertificateHttps;

  HttpDataSource({
    required this.baseAPI,
    this.isUsingHttps = true,
    this.isCertificateHttps = true,
  });

  String getDomainName() {
    return baseAPI;
  }

  String getDomainUrl() {
    return (isUsingHttps ? 'https://' : 'http://') + baseAPI;
  }

  void printDebugData(Response response) {
    int? sent = response.request?.contentLength;
    int? received = response.contentLength;
    debugPrint(
      '${response.request?.method} (${response.statusCode}) - ${((sent == null ? '' : 'Up:${fileSize(sent)} ') + (received == null ? '' : 'Down:${fileSize(received)} '))}${response.request?.url.path}',
    );
  }

  @override
  Future<Response?> fetchData({
    String directory = '',
    Map<String, String>? parameters,
    Map<String, String> headers = const {},
    String body = '',
    int timeoutInMilliseconds = 5000,
  }) async {
    int tries = 3;

    do {
      try {
        String apiUrl = getDomainUrl() + directory;

        debugPrint('Requesting url "$apiUrl"...');

        final Client client = Client();
        final Uri uri = isUsingHttps
            ? Uri.https(baseAPI, directory, parameters)
            : Uri.http(baseAPI, directory, parameters);
        final Response response = body.isEmpty
            ? await client.get(uri, headers: headers)
            : await client.post(uri, headers: headers, body: body);

        printDebugData(response);
        return response;
      } on HttpException catch (_) {
        tries--;
        sleep(Duration(milliseconds: 500));
      } on Exception catch (_) {
        tries--;
        sleep(Duration(milliseconds: 500));
      }
    } while (tries > 0);

    return null;
  }
}
