package me.carda.awesome_notifications.core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.TestUtils;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

import static org.junit.Assert.*;

public class NotificationCrontabModelTest {

    @Before
    public void setUp() throws Exception {
        AbstractModel
                .defaultValues
                .putAll(Definitions.initialValues);
    }

    @After
    public void tearDown() throws Exception {
        Definitions
                .initialValues
                .clear();
    }

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
                AwesomeNotificationsException.class,() -> {
                    crontabModel.validate(null);
                });
    }

    @Test
    public void getNextValidDate() {
    }
}