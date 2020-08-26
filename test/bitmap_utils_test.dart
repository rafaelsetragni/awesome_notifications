import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/src/enumerators/time_and_date.dart';
import 'package:awesome_notifications/src/helpers/cron_helper.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
  });

  tearDown(() {
  });

  test('test cleanMediaSource', () async {

    expect("http://www.media.com",        BitmapUtils().cleanMediaPath("http://www.media.com"));
    expect("https://media.com",           BitmapUtils().cleanMediaPath("https://media.com"));
    expect("https://media.com/image",     BitmapUtils().cleanMediaPath("https://media.com/image"));
    expect("https://media.com/image.jpg", BitmapUtils().cleanMediaPath("https://media.com/image.jpg"));
    expect("https://media.com/image.png", BitmapUtils().cleanMediaPath("https://media.com/image.png"));

    expect("/app/files/androidapp/imagefile.png", BitmapUtils().cleanMediaPath("file://app/files/androidapp/imagefile.png"));
    expect("/app/files/androidapp/imagefile.png", BitmapUtils().cleanMediaPath("resource://app/files/androidapp/imagefile.png"));

    expect("assets/img/imagefile.png", BitmapUtils().cleanMediaPath("asset://assets/img/imagefile.png"));

  });
}
