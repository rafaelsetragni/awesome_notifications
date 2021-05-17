package me.carda.awesome_notifications.notifications.models;

import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public abstract class NotificationScheduleModel extends Model {

    public String timeZone;
    public String createdDate;

    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    public Boolean repeats;
    public Boolean allowWhileIdle;

    public abstract Calendar getNextValidDate(Date fixedNowDate) throws Exception;

    public Boolean hasNextValidDate() throws Exception {

        TimeZone timeZone = StringUtils.isNullOrEmpty(this.timeZone) ?
                DateUtils.localTimeZone :
                TimeZone.getTimeZone(this.timeZone);

        if (timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        if(createdDate == null && !repeats)
            return false;

        Date referenceDate = repeats ?
                DateUtils.getLocalDateTime(this.timeZone) :
                DateUtils.stringToDate(createdDate, this.timeZone);

        Calendar nextSchedule = getNextValidDate(referenceDate);
        if(nextSchedule == null)
            return false;

        Date nextValidDate = nextSchedule.getTime();
        return nextValidDate != null && nextValidDate.compareTo(DateUtils.getLocalDateTime(this.timeZone)) >= 0;
    }
}
