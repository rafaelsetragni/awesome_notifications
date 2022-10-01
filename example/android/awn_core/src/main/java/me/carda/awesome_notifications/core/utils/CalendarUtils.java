package me.carda.awesome_notifications.core.utils;

import androidx.annotation.NonNull;

import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.Objects;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.annotation.Nullable;

import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public class CalendarUtils {

    private static final String TAG = "CalendarUtils";

    // *****************************  SINGLETON PATTERN  *****************************

    protected static final CalendarUtils instance = new CalendarUtils();

    private CalendarUtils(){}

    public static CalendarUtils getInstance(){
        return instance;
    }

    // *******************************************************************************

    static TimeZone utcTimeZone = TimeZone.getTimeZone("GMT");
    public TimeZone getUtcTimeZone() {
        return utcTimeZone;
    }

    static TimeZone localTimeZone = TimeZone.getDefault();
    public TimeZone getLocalTimeZone() {
        return localTimeZone;
    }

    protected Calendar getNowCalendar(){
        Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        calendar.setTime(new Date());
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar;
    }

    public String getNowStringCalendar(){
        return calendarToString(getNowCalendar());
    }

    @Nullable
    public String calendarToString(@Nullable Calendar calendar){
        if(calendar == null)
            return null;

        return String
                .format(
                    Locale.US,
                    "%04d-%02d-%02d %02d:%02d:%02d %s",
                    calendar.get(Calendar.YEAR),
                        calendar.get(Calendar.MONTH)+1,
                        calendar.get(Calendar.DAY_OF_MONTH),
                        calendar.get(Calendar.HOUR_OF_DAY),
                        calendar.get(Calendar.MINUTE),
                        calendar.get(Calendar.SECOND),
                        calendar.getTimeZone().getID());
    }

    @Nullable
    public Calendar shiftTimeZone(@Nullable Calendar calendar, @Nullable String timeZoneId) throws AwesomeNotificationsException {
        if(calendar == null)
            return null;

        TimeZone timeZone = TimeZoneUtils.getInstance().getValidTimeZone(timeZoneId);

        if (timeZone != null){
            Calendar shiftedCalendar = (Calendar) calendar.clone();
            shiftedCalendar.setTimeZone(timeZone);
            return shiftedCalendar;
        }
        else {
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid time zone",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".calendar.timeZone");
        }
    }

    public Calendar shiftTimeZone(@NonNull Calendar calendar, @NonNull TimeZone timeZone) {
        Date date = calendar.getTime();
        long msFromEpochGmt = date.getTime();

        int offsetFromUTC =
            calendar
                .getTimeZone()
                .getOffset(msFromEpochGmt);

        Calendar shiftedCalendar = Calendar.getInstance(timeZone);
        shiftedCalendar.setTime(date);
        shiftedCalendar.add(Calendar.MILLISECOND, offsetFromUTC);

        return shiftedCalendar;
    }

    @Nullable
    public Calendar calendarFromString(@Nullable String date) {
        if(StringUtils.getInstance().isNullOrEmpty(date))
            return null;
        assert date != null;

        final String regex = "^((\\d+)-(\\d+)-(\\d+) (\\d+):(\\d+):(\\d+))( (\\S+))?$";

        final Pattern pattern = Pattern.compile(regex, Pattern.CASE_INSENSITIVE);
        final Matcher matcher = pattern.matcher(date);

        if(matcher.matches())
            return calendarFromString(Objects.requireNonNull(matcher.group(1)), matcher.group(9));
        else
            return null;
    }

    @Nullable
    public Calendar calendarFromString(@Nullable String date, @Nullable String timeZoneId) {

        if(StringUtils.getInstance().isNullOrEmpty(date))
            return null;

        TimeZone timeZone;
        if(StringUtils.getInstance().isNullOrEmpty(timeZoneId))
            timeZone =
                CalendarUtils
                    .getInstance()
                    .getUtcTimeZone();
        else
            timeZone =
                TimeZoneUtils
                    .getInstance()
                    .getValidTimeZone(timeZoneId);

        if (timeZone == null)
            timeZone =
                TimeZoneUtils
                    .getInstance()
                    .getValidTimeZone(timeZoneId);

        return calendarFromString(date, timeZone);
    }

    @Nullable
    public Calendar calendarFromString(@Nullable String date, @Nullable TimeZone timeZone) {

        if(StringUtils.getInstance().isNullOrEmpty(date))
            return null;

        final String regex = "^(\\d+)-(\\d+)-(\\d+) (\\d+):(\\d+):(\\d+)$";

        final Pattern pattern = Pattern.compile(regex, Pattern.CASE_INSENSITIVE);
        final Matcher matcher = pattern.matcher(date);

        if(matcher.matches()){

            final Calendar calendar = getNowCalendar();
            shiftTimeZone(calendar, timeZone);

            calendar.set(Calendar.YEAR, Integer.parseInt(matcher.group(1)));
            calendar.set(Calendar.MONTH, Integer.parseInt(matcher.group(2))-1);
            calendar.set(Calendar.DAY_OF_MONTH, Integer.parseInt(matcher.group(3)));
            calendar.set(Calendar.HOUR_OF_DAY, Integer.parseInt(matcher.group(4)));
            calendar.set(Calendar.MINUTE, Integer.parseInt(matcher.group(5)));
            calendar.set(Calendar.SECOND, Integer.parseInt(matcher.group(6)));

            return calendar;
        }

        return null;
    }

    @NonNull
    public Calendar getCurrentCalendar() {
        return getNowCalendar();
    }

    @NonNull
    public Calendar getCurrentCalendar(@NonNull String fromTimeZone) throws AwesomeNotificationsException {
        return shiftTimeZone(getNowCalendar(), fromTimeZone);
    }

    @NonNull
    public Calendar getCurrentCalendar(@NonNull TimeZone fromTimeZone) throws AwesomeNotificationsException {
        Calendar originalCalendar = getNowCalendar();
        Calendar shiftedCalendar = shiftTimeZone(originalCalendar, fromTimeZone);
        return shiftedCalendar;
    }
}
