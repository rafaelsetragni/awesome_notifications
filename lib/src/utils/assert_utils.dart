
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/models/model.dart';

class AssertUtils {

  static String toSimpleEnumString<T>(T e){
    if(e == null) return null;
    return e.toString().split('.')[1];
  }

  static bool isNullOrEmptyOrInvalid<T>(dynamic value, Type T){

    if(value == null) return true;
    if(value.runtimeType != T) return true;

    switch(value.runtimeType){
      case String:
      case Map:
      case List:
        return value.isEmpty;
    }

    return false;
  }

  static List<Map<String, Object>> toListMap<T extends Model>(List<T> list) {
    if(list == null || list.length == 0) return null;

    List<Map<String, Object>> returnList = List<Map<String, Object>>();
    list.forEach((element){
      returnList.add(element.toMap());
    });

    return returnList;
  }

  static extractValue<T>(Map dataMap, String reference){
    T defaultValue = _getDefaultValue(reference, T);
    dynamic value = dataMap[reference];

    if(value == null || !(value is T)) return defaultValue;

    return value;
  }

  static extractMap<T,C>(Map dataMap, String reference){

    Map defaultValue = _getDefaultValue(reference, Map);
    if(defaultValue != null && !(defaultValue is Map)) return defaultValue;

    dynamic value = dataMap[reference];
    if(value == null || !(value is Map)) return defaultValue;

    try{
        Map<T,C> castedValue = Map<T,C>.from(value);
        return castedValue.isEmpty ? defaultValue : castedValue;
    } catch(e){
      return defaultValue;
    }
  }

  static extractEnum<T>(Map dataMap, String reference, List<T> values){
    T defaultValue = _getDefaultValue(reference, T);
    dynamic value = dataMap[reference];

    if(value == null || !(value is String)) return defaultValue;

    String castedValue = value;
    if(AssertUtils.isNullOrEmptyOrInvalid(castedValue, String)) return defaultValue;

    return values.firstWhere(
            (e){
          return AssertUtils.toSimpleEnumString(e).toLowerCase() == castedValue.toLowerCase();
        },
        orElse: () => defaultValue
    );
  }

  static getValueOrDefault(String reference, dynamic value, Type T){

    switch(value.runtimeType){

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

    if(value == null || value.runtimeType != T)
      return _getDefaultValue(reference, T);
    return value;
  }

  static _getDefaultValue(String reference, Type T){
    dynamic defaultValue = Definitions.initialValues[reference];
    if(defaultValue == null || defaultValue.runtimeType != T) return null;
    return defaultValue;
  }

  static fromListMap<T extends Model>(Object mapData, Function newModel) {
    if(mapData == null || mapData is List<Map<String, dynamic>>) return null;

    List<Map<String, dynamic>> listMapData = mapData;
    if(listMapData.length <= 0) return null;

    List<T> actionButtons;
    listMapData.forEach((actionButtonData){
      return actionButtons.add(newModel().fromMap(actionButtonData));
    });

    return actionButtons;
  }
}