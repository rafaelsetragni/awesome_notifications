import 'package:awesome_notifications/src/utils/map_utils.dart';

abstract class Model {
  Model();

  /// Imports data from a serializable object
  Map<String, dynamic> toMap();

  /// Exports all content into a serializable object
  Model? fromMap(Map<String, dynamic> mapData);

  @override
  String toString() {
    Map mapData = toMap();
    return MapUtils.printPrettyMap(mapData);
  }

  /// Validates
  void validate();
}
