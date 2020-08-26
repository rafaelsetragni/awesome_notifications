import 'package:awesome_notifications/src/utils/map_utils.dart';

abstract class Model {

  Map<String, dynamic> toMap();
  Model fromMap(Map<String, dynamic> mapData);

  @override
  String toString() {
    Map mapData = toMap();
    return MapUtils.printPrettyMap(mapData);
  }

  void validate();
}
