package me.carda.awesome_notifications.core.managers;

import org.checkerframework.checker.nullness.qual.NonNull;

import java.util.Calendar;
import java.util.Locale;

abstract public class EventManager {

    protected static String _getKeyByIdAndDate(
            @NonNull Integer id,
            @NonNull Calendar displayedDate
    ){
        return _getKeyById(id) + "-" + _getKeyByCalendar(displayedDate);
    }

    protected static String _getKeyById(
            @NonNull Integer id
    ){
        return String.format(Locale.US, "%010d", id);
    }

    protected static String _getKeyByCalendar(
            @NonNull Calendar displayedDate
    ){
        long unixTimestamp = displayedDate.getTimeInMillis();
        return String.format(Locale.US, "%010d", unixTimestamp);
    }
}
