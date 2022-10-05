package me.carda.awesome_notifications.core.utils;

public class BooleanUtils {

    // ************** SINGLETON PATTERN ***********************

    private static BooleanUtils instance;

    private BooleanUtils(){
    }

    public static BooleanUtils getInstance() {
        if (instance == null)
            instance = new BooleanUtils();
        return instance;
    }

    // ********************************************************

    public boolean getValue(Boolean booleanObject){
        return booleanObject != null && booleanObject;
    }
    public boolean getValueOrDefault(Boolean booleanObject, Boolean defaultValue){
        return booleanObject == null ? getValue(defaultValue) : getValue(booleanObject);
    }
}
