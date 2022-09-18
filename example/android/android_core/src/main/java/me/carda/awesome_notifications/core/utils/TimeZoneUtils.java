package me.carda.awesome_notifications.core.utils;

import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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

        final String regex = "^((\\-|\\+)?(\\d{2}(:\\d{2})?))|(\\S+)$";

        final Pattern pattern = Pattern.compile(regex, Pattern.MULTILINE);
        final Matcher matcher = pattern.matcher(timeZoneId);

        TimeZone finalTimeZone;
        if(matcher.matches()){
            if(matcher.group(1) != null) {
                finalTimeZone = TimeZone.getTimeZone(
                        "GMT"+
                                (matcher.group(2) == null ? "+" : matcher.group(2)) +
                                matcher.group(3) +
                                (matcher.group(4) == null ? ":00" : matcher.group(4)));
            }
            else {
                finalTimeZone = TimeZone.getTimeZone(matcher.group(5));
            }
        }
        else {
            finalTimeZone = TimeZone.getDefault();
        }

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
