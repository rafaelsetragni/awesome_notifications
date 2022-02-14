package me.carda.awesome_notifications.awesome_notifications_core.models.returnedData;

import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.TestUtils;

import static org.junit.Assert.*;

public class NotificationReceivedTest {

    @Test
    public void fromJsonAndToJson() {
        NotificationReceived notificationReceived = new NotificationReceived();

        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_ID);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_RANDOM_ID);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_TITLE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_BODY);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_SUMMARY);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_SHOW_WHEN);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_WAKE_UP_SCREEN);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_FULL_SCREEN_INTENT);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_ACTION_TYPE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_LOCKED);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_PLAY_SOUND);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_CUSTOM_SOUND);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_TICKER);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_PAYLOAD);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_AUTO_DISMISSIBLE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_LAYOUT);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_CREATED_SOURCE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_CREATED_LIFECYCLE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_DISPLAYED_DATE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_CREATED_DATE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_CHANNEL_KEY);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_CATEGORY);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_AUTO_DISMISSIBLE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_COLOR);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_BACKGROUND_COLOR);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_ICON);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_LARGE_ICON);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_BIG_PICTURE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_PROGRESS);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_GROUP_KEY);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_PRIVACY);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_PRIVATE_MESSAGE);
        TestUtils.testModelField(notificationReceived, Definitions.NOTIFICATION_MESSAGES);
    }

}