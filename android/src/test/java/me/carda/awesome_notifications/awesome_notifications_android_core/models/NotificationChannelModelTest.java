package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;

import static org.junit.Assert.*;

public class NotificationChannelModelTest {

    @Test
    public void fromJsonAndToJson() {
        NotificationChannelModel channelModel = new NotificationChannelModel();

        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_ICON_RESOURCE_ID);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_ICON);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_DEFAULT_COLOR);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_CHANNEL_KEY);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_CHANNEL_NAME);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_CHANNEL_DESCRIPTION);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_CHANNEL_GROUP_KEY);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_PLAY_SOUND);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_SOUND_SOURCE);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_ENABLE_VIBRATION);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_VIBRATION_PATTERN);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_ENABLE_LIGHTS);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_LED_COLOR);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_LED_ON_MS);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_LED_OFF_MS);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_GROUP_KEY);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_GROUP_SORT);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_IMPORTANCE);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_DEFAULT_PRIVACY);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_LOCKED);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_ONLY_ALERT_ONCE);
        TestUtils.testModelField(channelModel, Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS);
    }

    @Test
    public void validate() {
    }
}