package me.carda.awesome_notifications.awesome_notifications_core.utils;

import java.util.TimeZone;
import javax.annotation.Nullable;

public class TimeZoneUtils {

    // *****************************  SINGLETON PATTERN  *****************************

    protected static final TimeZoneUtils instance = new TimeZoneUtils();

    private TimeZoneUtils(){}

    public static TimeZoneUtils getInstance(){
        return instance;
    }

    // *******************************************************************************

    @Nullable
    public TimeZone getValidTimeZone(@Nullable String timeZoneId){
        if(timeZoneId == null)
            return null;

        TimeZone finalTimeZone = TimeZone.getTimeZone(timeZoneId);

        if(finalTimeZone.getID().contains(timeZoneId))
            return finalTimeZone;

        return null;
    }

    @Nullable
    public String timeZoneToString(@Nullable TimeZone timeZone){
        if(timeZone == null)
            return null;

        return timeZone.getID();
    }
}
