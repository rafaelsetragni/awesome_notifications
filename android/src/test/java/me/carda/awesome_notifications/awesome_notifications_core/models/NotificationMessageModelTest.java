package me.carda.awesome_notifications.awesome_notifications_core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.TestUtils;

import static org.junit.Assert.*;

public class NotificationMessageModelTest {

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
        NotificationMessageModel messageModel = new NotificationMessageModel();

        TestUtils.testModelField(messageModel, Definitions.NOTIFICATION_TITLE);
        TestUtils.testModelField(messageModel, Definitions.NOTIFICATION_MESSAGES);
        TestUtils.testModelField(messageModel, Definitions.NOTIFICATION_LARGE_ICON);
        TestUtils.testModelField(messageModel, Definitions.NOTIFICATION_TIMESTAMP);
    }

    @Test
    public void validate() {
    }
}