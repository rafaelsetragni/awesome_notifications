package me.carda.awesome_notifications.core.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.enumerators.ActionType;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;

public class NotificationButtonModel extends AbstractModel {

    private static final String TAG = "NotificationButtonModel";

    public String key;
    public String icon;
    public String label;
    public Integer color;
    public Boolean enabled;
    public Boolean requireInputText = false;
    public Boolean autoDismissible;
    public Boolean showInCompactView;
    public Boolean isDangerousOption;
    public ActionType actionType;

    @Override
    public NotificationButtonModel fromMap(Map<String, Object> arguments) {

        processRetroCompatibility(arguments);

        key               = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_KEY, String.class, null);
        icon              = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_ICON, String.class, null);
        label             = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_LABEL, String.class, null);
        color             = getValueOrDefault(arguments, Definitions.NOTIFICATION_COLOR, Integer.class, null);
        actionType        = getValueOrDefault(arguments, Definitions.NOTIFICATION_ACTION_TYPE, ActionType.class, ActionType.Default);
        enabled           = getValueOrDefault(arguments, Definitions.NOTIFICATION_ENABLED, Boolean.class, true);
        requireInputText  = getValueOrDefault(arguments, Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, Boolean.class, false);
        isDangerousOption = getValueOrDefault(arguments, Definitions.NOTIFICATION_IS_DANGEROUS_OPTION, Boolean.class, false);
        autoDismissible   = getValueOrDefault(arguments, Definitions.NOTIFICATION_AUTO_DISMISSIBLE, Boolean.class, true);
        showInCompactView = getValueOrDefault(arguments, Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, Boolean.class, false);

        return this;
    }

    // Retro-compatibility with 0.6.X
    private void processRetroCompatibility(Map<String, Object> arguments){

        if (arguments.containsKey("autoCancel")) {
            Logger.w("AwesomeNotifications", "autoCancel is deprecated. Please use autoDismissible instead.");
            autoDismissible   = getValueOrDefault(arguments, "autoCancel", Boolean.class, true);
        }

        if (arguments.containsKey("buttonType")){
            Logger.w("AwesomeNotifications", "buttonType is deprecated. Please use actionType instead.");
            actionType = getValueOrDefault(arguments, "buttonType", ActionType.class, ActionType.Default);
        }

        adaptInputFieldToRequireText();
    }

    // Retro-compatibility with 0.6.X
    private void adaptInputFieldToRequireText(){
        if (actionType == ActionType.InputField) {
            Logger.d("AwesomeNotifications", "InputField is deprecated. Please use requireInputText instead.");
            actionType = ActionType.SilentAction;
            requireInputText = true;
        }
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_BUTTON_KEY, dataMap, key);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BUTTON_KEY, dataMap, key);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BUTTON_ICON, dataMap, icon);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BUTTON_LABEL, dataMap, label);
        putDataOnSerializedMap(Definitions.NOTIFICATION_COLOR, dataMap, color);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ACTION_TYPE, dataMap, actionType);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ENABLED, dataMap, enabled);
        putDataOnSerializedMap(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, dataMap, requireInputText);
        putDataOnSerializedMap(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, dataMap, autoDismissible);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, dataMap, showInCompactView);
        putDataOnSerializedMap(Definitions.NOTIFICATION_IS_DANGEROUS_OPTION, dataMap, isDangerousOption);

        return dataMap;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationButtonModel fromJson(String json){
        return (NotificationButtonModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationsException {
        if(stringUtils.isNullOrEmpty(key))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Button key is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".button.actionKey");

        if(stringUtils.isNullOrEmpty(label))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Button label is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".button.label");
    }
}
