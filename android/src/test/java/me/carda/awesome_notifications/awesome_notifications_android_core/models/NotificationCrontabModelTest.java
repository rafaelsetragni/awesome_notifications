package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;

import static org.junit.Assert.*;

public class NotificationCrontabModelTest {

    @Test
    public void fromJsonAndToJson() {
        NotificationCrontabModel crontabModel = new NotificationCrontabModel();

        TestUtils.testModelField(crontabModel, Definitions.NOTIFICATION_INITIAL_DATE_TIME);
        TestUtils.testModelField(crontabModel, Definitions.NOTIFICATION_EXPIRATION_DATE_TIME);
        TestUtils.testModelField(crontabModel, Definitions.NOTIFICATION_CRONTAB_EXPRESSION);
        TestUtils.testModelField(crontabModel, Definitions.NOTIFICATION_PRECISE_SCHEDULES);
    }

    @Test
    public void validate() {
        NotificationCrontabModel crontabModel = new NotificationCrontabModel();

        assertThrows( "Must throw exception case the required files are empty",
                AwesomeNotificationException.class,() -> {
                    crontabModel.validate(null);
                });
    }

    @Test
    public void getNextValidDate() {
    }
}