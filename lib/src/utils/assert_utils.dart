import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:awesome_notifications/src/models/model.dart';
import 'package:intl/intl.dart';

import '../definitions.dart';
import 'string_utils.dart';

const String _dateFormat = "yyyy-MM-dd HH:mm:ss Z";

class AwesomeAssertUtils {
  static String? toSimpleEnumString<T extends Enum>(T? e) {
    return e?.name;
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
    if (list?.isEmpty ?? true) return null;

    List<Map<String, Object>> returnList = [];
    for (var element in list!) {
      returnList.add(Map<String, Object>.from(element.toMap()));
    }

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

  static extractValue(String reference, Map dataMap, Type T) {
    dynamic defaultValue = _getDefaultValue(reference, T);
    dynamic value = dataMap[reference];

    if (value is String) {
      String valueCasted = value;
      if (AwesomeStringUtils.isNullOrEmpty(valueCasted,
          considerWhiteSpaceAsEmpty: true)) return defaultValue;

      switch (T) {
        case DateTime:
          try {
            return DateFormat(_dateFormat).parse(valueCasted, true);
          } catch (err) {
            return defaultValue;
          }
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

        case bool:
          return valueCasted.toLowerCase() == 'true';
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
        break;

      case bool:
        return value ?? defaultValue ?? false;
    }

    if (value.runtimeType.hashCode != T.hashCode) return defaultValue;

    return defaultValue;
  }

  static extractMap<T, C>(Map dataMap, String reference) {
    Map? defaultValue = _getDefaultValue(reference, Map);

    dynamic value = dataMap[reference];
    if (value == null || value is! Map) return defaultValue;

    try {
      Map<T, C> castedValue = Map<T, C>.from(value);
      return castedValue.isEmpty ? defaultValue : castedValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static T? extractEnum<T extends Enum>(
      String reference, Map dataMap, List<T> values) {
    T? defaultValue = _getDefaultValue(reference, T);
    dynamic value = dataMap[reference];

    if (value is T) return value;

    if (value == null || value is! String) return defaultValue;

    String castedValue = value;
    castedValue = castedValue.trim();
    return enumToString<T>(castedValue, values, defaultValue ?? values.first);
  }

  static T? enumToString<T extends Enum>(
      String enumValue, List<T> values, T? defaultValue) {
    for (final enumerator in values) {
      if (AwesomeAssertUtils.toSimpleEnumString(enumerator)!.toLowerCase() ==
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
    if (listMapData.isEmpty) return null;

    List<T> actionButtons = [];
    for (var actionButtonData in listMapData) {
      actionButtons.add(newModel().fromMap(actionButtonData));
    }

    return actionButtons;
  }
}
