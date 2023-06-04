import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const String _dateFormatTimezone = "yyyy-MM-dd HH:mm:ss Z";

class AwesomeAssertUtils {
  static String? toSimpleEnumString<T extends Enum>(T? e) {
    return e?.name;
  }

  static bool isNullOrEmptyOrInvalid<T>(dynamic value) {
    if (value == null) return true;
    if (value is! T) return true;
    if (value is String) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    if (value is List) return value.isEmpty;
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

  static T? getValueOrDefault<T>(String reference, dynamic value) {
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

    T? defaultValue = _getDefaultValue<T>(reference);
    if (value == null) return defaultValue;
    if (value is T) return value;
    return defaultValue;
  }

  static extractValue<T>(String reference, Map dataMap) {
    dynamic defaultValue = _getDefaultValue<T>(reference);
    dynamic value = dataMap[reference];

    if (value is String) {
      String valueCasted = value;
      switch (T) {
        case DateTime:
          try {
            if (RegExp(r'\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2} \w+')
                .hasMatch(valueCasted)) {
              return DateFormat(_dateFormatTimezone).parse(valueCasted, true);
            }
            if (RegExp(r'\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(\.\d{1,3})?')
                .hasMatch(valueCasted)) {
              return AwesomeDateUtils.parseStringToDate(valueCasted);
            }
            return null;
          } catch (err) {
            return defaultValue;
          }

        case String:
          return valueCasted;

        case Color:
        case int:

          // Color hexadecimal representation
          final RegExpMatch? match =
              RegExp(r'^(0x|#)(\w{2})?(\w{6})$').firstMatch(valueCasted);

          if (match != null) {
            String hex = (match.group(2) ?? 'FF') + match.group(3)!;
            final int colorValue = int.parse(hex, radix: 16);
            return (T == Color) ? Color(colorValue) : colorValue;
          } else if (T == int) {
            int? parsedValue = int.tryParse(valueCasted.replaceFirstMapped(
                RegExp(r'^(\d+)\.\d+$'), (match) => '${match.group(1)}'));
            var finalValue = parsedValue ?? defaultValue;
            return finalValue;
          }
          break;

        case double:
          double? parsedValue = double.tryParse(valueCasted);
          return parsedValue ?? defaultValue;

        case bool:
          switch (valueCasted.toLowerCase()) {
            case 'true':
              return true;
            case 'false':
              return false;
            case '1':
              return true;
            case '0':
              return false;
          }
          return null;
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
          case int:
            return Color(value);
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

      case Duration:
        if (value == null) return defaultValue;
        Duration? duration;
        if (value is String) duration = Duration(seconds: int.parse(value));
        if (value is int) duration = Duration(seconds: value);
        return (duration?.inSeconds ?? -1) < 0 ? defaultValue : duration;

      case bool:
        if (value == null) return defaultValue;
        if (value is int) return value == 1;
        if (value is bool) return value;
        return defaultValue;
    }

    if (value is T) return value;

    return defaultValue;
  }

  static extractMap<T, C>(String reference, Map dataMap) {
    Map? defaultValue = _getDefaultValue<Map>(reference);

    dynamic value = dataMap[reference];
    if (value == null || value is! Map) return defaultValue;

    try {
      if (value.isEmpty) return defaultValue;
      return Map<T, C>.from(value);
    } catch (e) {
      return defaultValue;
    }
  }

  static T? extractEnum<T extends Enum>(
      String reference, Map dataMap, List<T> values) {
    T? defaultValue = _getDefaultValue<T>(reference);
    dynamic value = dataMap[reference];

    if (value is T) return value;

    if (value == null || value is! String) return defaultValue;

    if (AwesomeStringUtils.isNullOrEmpty(value,
        considerWhiteSpaceAsEmpty: true)) {
      return defaultValue;
    }

    String castedValue = value;
    castedValue = castedValue.trim();
    return enumToString<T>(castedValue, values, defaultValue);
  }

  static T? enumToString<T extends Enum>(
      String enumValue, List<T> values, T? defaultValue) {
    for (final enumerator in values) {
      if (AwesomeAssertUtils.toSimpleEnumString(enumerator)!.toLowerCase() ==
          enumValue.toLowerCase()) return enumerator;
    }
    return defaultValue;
  }

  static dynamic _getDefaultValue<T>(String reference) {
    dynamic defaultValue = Definitions.initialValues[reference];
    if (defaultValue is! T) return null;
    return defaultValue;
  }

  static List<T>? fromListMap<T extends Model>(
      Object? mapData, Function newModel) {
    if (mapData == null || mapData is! List<Map<String, dynamic>>) return null;

    List<Map<String, dynamic>> listMapData = List.from(mapData);
    if (listMapData.isEmpty) return null;

    List<T> actionButtons = [];
    for (var actionButtonData in listMapData) {
      actionButtons.add(newModel().fromMap(actionButtonData));
    }

    return actionButtons;
  }
}
