package me.carda.awesome_notifications.notifications.models;

import java.util.Calendar;
import java.util.Date;

public abstract class NotificationScheduleModel extends Model {

    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    public Boolean repeats;
    public Boolean allowWhileIdle;

    public abstract Calendar getNextValidDate(Date fixedNowDate);
}
