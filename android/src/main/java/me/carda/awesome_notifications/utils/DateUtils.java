package me.carda.awesome_notifications.utils;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

import me.carda.awesome_notifications.Definitions;

public class DateUtils {

    public static TimeZone utcTimeZone = TimeZone.getTimeZone("UTC");

    public static Date parseDate(String dateTime){
        try {
            SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
            simpleDateFormat.setTimeZone(utcTimeZone);
            return simpleDateFormat.parse(dateTime);
        } catch (ParseException e) {
            e.printStackTrace();
        }
        return null;
    }

    public static String getUTCDate(){
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(utcTimeZone);
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(utcTimeZone);
        return simpleDateFormat.format(calendar.getTime());
    }

    public static Date getUTCDateTime(){
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(utcTimeZone);
        return calendar.getTime();
    }
}
