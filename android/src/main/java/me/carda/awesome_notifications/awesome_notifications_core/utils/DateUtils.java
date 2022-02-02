package me.carda.awesome_notifications.awesome_notifications_core.utils;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

public class DateUtils {

    static TimeZone utcTimeZone = TimeZone.getTimeZone("GMT");
    public static TimeZone getUtcTimeZone() {
        return utcTimeZone;
    }

    static TimeZone localTimeZone = TimeZone.getDefault();
    public static TimeZone getLocalTimeZone() {
        return localTimeZone;
    }

    public static Date stringToDate(String dateTime, String fromTimeZone) throws AwesomeNotificationsException {
        try {
            TimeZone timeZone = getTimeZone(fromTimeZone);

            if(timeZone == null)
                throw new AwesomeNotificationsException("Invalid time zone");

            SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
            simpleDateFormat.setTimeZone(timeZone);

            return simpleDateFormat.parse(dateTime);
        } catch (ParseException e) {
            e.printStackTrace();
            throw new AwesomeNotificationsException("Invalid date");
        }
    }

    public static String dateToString(Date dateTime, String fromTimeZone) throws AwesomeNotificationsException {
        TimeZone timeZone = getTimeZone(fromTimeZone);

        if(timeZone == null)
            throw new AwesomeNotificationsException("Invalid time zone");

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(timeZone);

        return simpleDateFormat.format(dateTime);
    }

    public static String getLocalDate(String fromTimeZone) throws AwesomeNotificationsException {
        TimeZone timeZone = (fromTimeZone == null) ?
                localTimeZone :
                getTimeZone(fromTimeZone);

        if(timeZone == null)
            throw new AwesomeNotificationsException("Invalid time zone");

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(timeZone);

        return simpleDateFormat.format(new Date());
    }

    public static Date shiftToTimeZone(Date date, TimeZone timeZone) {
        timeZone = (timeZone == null) ? utcTimeZone : timeZone;

        Calendar calendar = Calendar.getInstance();
        calendar.setTime(date);
        calendar.setTimeZone(timeZone);

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(timeZone);

        return calendar.getTime();
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
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar.getTime();
    }

    public static Date getLocalDateTime(String fromTimeZone) throws AwesomeNotificationsException {
        TimeZone timeZone;

        String cleanedTimeZone =
            cleanTimeZoneIdentifier(
                fromTimeZone == null ?
                        DateUtils.localTimeZone.getID() : fromTimeZone);

        timeZone = TimeZone.getTimeZone(cleanedTimeZone);
        if(timeZone == null)
            throw new AwesomeNotificationsException("Invalid time zone");

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(timeZone);
        calendar.set(Calendar.MILLISECOND, 0);

        return calendar.getTime();
    }

    public static TimeZone getTimeZone(String timeZoneId) throws AwesomeNotificationsException {

        if(StringUtils.isNullOrEmpty(timeZoneId))
            throw new AwesomeNotificationsException("Invalid time zone "+timeZoneId);

        String cleanedTimeZoneId = cleanTimeZoneIdentifier(timeZoneId);

        TimeZone timeZone = TimeZone.getTimeZone(cleanTimeZoneIdentifier(timeZoneId));
        if(
            !cleanedTimeZoneId.equals("UTC") &&
            !cleanedTimeZoneId.equals("GMT") &&
            !cleanedTimeZoneId.equals("GMT+00:00") &&
            (timeZone.getID().equals("GMT") || timeZone.getID().equals("UTC"))
        )
            throw new AwesomeNotificationsException("Invalid time zone "+timeZoneId);

        return timeZone;
    }

    public static String cleanTimeZoneIdentifier(String timeZoneId){
        final String regex = ".*.ZoneInfo\\[id=\"([\\w\\/]+)\",.*";
        final String subst = "$1";

        final Pattern pattern = Pattern.compile(regex, Pattern.MULTILINE);
        final Matcher matcher = pattern.matcher(timeZoneId);

        return matcher.replaceAll(subst);
    }
}
