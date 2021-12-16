package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;

import static org.junit.Assert.*;

public class NotificationChannelGroupModelTest {

    @Test
    public void fromJsonAndToJson() {
        NotificationChannelGroupModel channelGroupModel = new NotificationChannelGroupModel();

        TestUtils.testModelField(channelGroupModel, Definitions.NOTIFICATION_CHANNEL_GROUP_NAME);
        TestUtils.testModelField(channelGroupModel, Definitions.NOTIFICATION_CHANNEL_GROUP_KEY);
    }

    @Test
    public void validate() {
    }
}