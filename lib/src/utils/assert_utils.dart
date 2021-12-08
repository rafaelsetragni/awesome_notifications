import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AssertUtils {
  static String? toSimpleEnumString<T>(T e) {
    if (e == null) return null;
    return e.toString().split('.')[1];
  }

  static bool isNullOrEmptyOrInvalid(dynamic value, Type T) {
    if (value?.runtimeType != T) return true;

    switch (value.runtimeType) {
      case String:
      case Map:
      case List:
        return value.isEmpty;
    }

    return false;
  }

  static List<Map<String, Object>>? toListMap<T extends Model>(List<T>? list) {
    if (list == null || list.length == 0) return null;

    List<Map<String, Object>> returnList = [];
    list.forEach((element) {
      returnList.add(Map<String, Object>.from(element.toMap()));
    });

    return returnList;
  }

  static getValueOrDefault(String reference, dynamic value, Type T) {
    switch (value.runtimeType) {
      case MaterialColor:
        value = (value as MaterialColor).shade500;
        break;

      case MaterialAccentColor:
        value = Color((value as MaterialAccentColor).value);
        break;

      case CupertinoDynamicColor:
        value = Color((value as CupertinoDynamicColor).value);
        break;
    }

    if (value?.runtimeType == T) return value;

    return _getDefaultValue(reference, T);
  }

  static extractValue<T>(String reference, Map dataMap, Type T) {
    dynamic defaultValue = _getDefaultValue(reference, T);
    dynamic value = dataMap[reference];

    if (value is String) {
      String valueCasted = value;

      switch (T) {
        case String:
          return valueCasted;

        case Color:
        case int:

          // Color hexadecimal representation
          final RegExpMatch? match =
              RegExp(r'^(0x|#)(\w{2})?(\w{6,6})$').firstMatch(valueCasted);

          if (match != null) {
            String hex = (match.group(2) ?? 'FF') + match.group(3)!;
            final int colorValue = int.parse(hex, radix: 16);
            return (T == Color) ? Color(colorValue) : colorValue;
          } else if (T == int) {
            int? parsedValue = int.tryParse(valueCasted.replaceFirstMapped(
                RegExp(r'^(\d+)\.\d+$'), (match) => '${match.group(1)}'));
            return parsedValue ?? defaultValue;
          }
          break;

        case double:
          double? parsedValue = double.tryParse(valueCasted);
          return parsedValue ?? defaultValue;
      }
    }

    switch (T) {
      case int:
        if (value is int) return value;
        if (value is double) return value.round();
        return defaultValue;

      case double:
        if (value is int) return value;
        if (value is double) return value;
        return defaultValue;

      case Color:
        switch (value.runtimeType) {
          case MaterialColor:
            value = (value as MaterialColor).shade500;
            break;

          case MaterialAccentColor:
            value = Color((value as MaterialAccentColor).value);
            break;

          case CupertinoDynamicColor:
            value = Color((value as CupertinoDynamicColor).value);
            break;
        }
    }

    if (value == null || value.runtimeType.hashCode != T.hashCode)
      return defaultValue;

    return null;
  }

  static extractMap<T, C>(Map dataMap, String reference) {
    Map? defaultValue = _getDefaultValue(reference, Map);
    if (defaultValue != null && !(defaultValue is Map)) return defaultValue;

    dynamic value = dataMap[reference];
    if (value == null || !(value is Map)) return defaultValue;

    try {
      Map<T, C> castedValue = Map<T, C>.from(value);
      return castedValue.isEmpty ? defaultValue : castedValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static T? extractEnum<T>(String reference, Map dataMap, List<T> values) {
    T? defaultValue = _getDefaultValue(reference, T);
    dynamic value = dataMap[reference];

    if (value == null || !(value is String)) return defaultValue;

    String castedValue = value;
    castedValue = castedValue.trim();
    if (AssertUtils.isNullOrEmptyOrInvalid(castedValue, String))
      return defaultValue;

    return enumToString<T>(castedValue, values, defaultValue ?? values.first);
  }

  static T? enumToString<T>(String enumValue, List<T> values, T? defaultValue) {
    for (final enumerator in values) {
      if (AssertUtils.toSimpleEnumString(enumerator)!.toLowerCase() ==
          enumValue.toLowerCase()) return enumerator;
    }
    return defaultValue;
  }

  static dynamic _getDefaultValue(String reference, Type T) {
    dynamic defaultValue = Definitions.initialValues[reference];
    if (defaultValue?.runtimeType != T) return null;
    return defaultValue;
  }

  static List<T>? fromListMap<T extends Model>(
      Object? mapData, Function newModel) {
    if (mapData == null || mapData is List<Map<String, dynamic>>) return null;

    List<Map<String, dynamic>> listMapData = List.from(mapData as List);
    if (listMapData.length <= 0) return null;

    List<T> actionButtons = [];
    listMapData.forEach((actionButtonData) {
      return actionButtons.add(newModel().fromMap(actionButtonData));
    });

    return actionButtons;
  }
}
