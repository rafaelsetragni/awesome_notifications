package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;

import static org.junit.Assert.*;

public class NotificationScheduleModelTest {

    @Test
    public void fromJsonAndToJson() {
        NotificationIntervalModel intervalModel = new NotificationIntervalModel();

        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_SCHEDULE_TIMEZONE);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_CREATED_DATE);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_SCHEDULE_REPEATS);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_ALLOW_WHILE_IDLE);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_SCHEDULE_PRECISE_ALARM);
    }

    @Test
    public void getNextValidDate() {
    }

    @Test
    public void hasNextValidDate() {
    }

    @Test
    public void getScheduleModelFromMap() {
    }
}