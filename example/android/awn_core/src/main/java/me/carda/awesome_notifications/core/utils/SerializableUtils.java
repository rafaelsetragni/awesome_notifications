package me.carda.awesome_notifications.core.utils;

import androidx.annotation.NonNull;

import java.util.Calendar;
import java.util.TimeZone;

public class SerializableUtils {

    public static final String TAG = "SerializableUtils";

    protected final EnumUtils enumUtils;
    protected final StringUtils stringUtils;
    protected final CalendarUtils calendarUtils;
    protected final TimeZoneUtils timeZoneUtils;

    // ************** SINGLETON PATTERN ***********************

    protected SerializableUtils(
            @NonNull EnumUtils enumUtils,
            @NonNull StringUtils stringUtils,
            @NonNull CalendarUtils calendarUtils,
            @NonNull TimeZoneUtils timeZoneUtils
    ){
        this.enumUtils = enumUtils;
        this.stringUtils = stringUtils;
        this.calendarUtils = calendarUtils;
        this.timeZoneUtils = timeZoneUtils;
    }

    protected static SerializableUtils instance;
    public static SerializableUtils getInstance() {
        if (instance == null)
            instance = new SerializableUtils(
                    EnumUtils.getInstance(),
                    StringUtils.getInstance(),
                    CalendarUtils.getInstance(),
                    TimeZoneUtils.getInstance()
            );
        return instance;
    }

    // ***********************   SERIALIZATION METHODS   *********************************

    public <T extends Calendar> Object serializeCalendar(T value) {
        return calendarUtils.calendarToString(value);
    }

    public <T extends TimeZone> Object serializeTimeZone(T value) {
        return timeZoneUtils.timeZoneToString(value);
    }

    public Calendar deserializeCalendar(String value) {
        return calendarUtils.calendarFromString(value);
    }

    public TimeZone deserializeTimeZone(String value) {
        return timeZoneUtils.getValidTimeZone(value);
    }
}
