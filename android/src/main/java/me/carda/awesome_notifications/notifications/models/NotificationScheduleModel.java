package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.externalLibs.CronExpression;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public abstract class NotificationScheduleModel extends Model {

    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    public Boolean repeats;
    public Boolean allowWhileIdle;

    public abstract Calendar getNextValidDate();
}
