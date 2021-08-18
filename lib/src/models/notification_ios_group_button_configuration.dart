
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/models/model.dart';

///
/// NotificationIOSGroupButtonConfiguration
///
/// For ios making button display when APP KILLED!
/// need to config it before and init on notification center
///
/// IOS ONLY!!!
///
class NotificationIOSGroupButtonConfiguration extends Model{

  static const _IDENTIFIER_KEY = "identifier";
  static const _POSITIVE_BUTTON_KEY = "positive";
  static const _NEGATIVE_BUTTON_KEY = "negative";

  String? identifier;
  NotificationActionButton? positive;
  NotificationActionButton? negative;

  NotificationIOSGroupButtonConfiguration({this.identifier, this.positive, this.negative}){
    validate();
  }


  @override
  Model? fromMap(Map<String, dynamic> mapData) {
    identifier = AssertUtils.extractValue(mapData, _IDENTIFIER_KEY);
    positive = NotificationActionButton().fromMap(mapData[_POSITIVE_BUTTON_KEY] as Map<String, dynamic>);
    negative = NotificationActionButton().fromMap(mapData[_NEGATIVE_BUTTON_KEY] as Map<String, dynamic>);
    validate();
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      _IDENTIFIER_KEY:identifier,
      _POSITIVE_BUTTON_KEY: positive?.toMap(),
      _NEGATIVE_BUTTON_KEY: negative?.toMap(),
    };
  }

  @override
  void validate() {
    assert(!AssertUtils.isNullOrEmptyOrInvalid(identifier, String));
    assert(positive != null,true);
    assert(negative != null,true);
    positive!.validate();
    negative!.validate();
  }


}