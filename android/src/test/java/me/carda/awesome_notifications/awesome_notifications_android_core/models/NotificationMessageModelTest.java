package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;

import static org.junit.Assert.*;

public class NotificationMessageModelTest {

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