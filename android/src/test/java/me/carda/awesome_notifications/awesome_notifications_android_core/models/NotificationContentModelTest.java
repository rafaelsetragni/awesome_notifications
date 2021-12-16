package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import com.google.common.reflect.TypeToken;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers.NotificationActionReceiver;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.DateUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.JsonUtils;

import static org.junit.Assert.*;

public class NotificationContentModelTest {

    @Test
    public void fromJsonAndToJson() {
        NotificationContentModel contentModel = new NotificationContentModel();

        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_ID);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_RANDOM_ID);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_TITLE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_BODY);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_SUMMARY);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_SHOW_WHEN);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_WAKE_UP_SCREEN);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_FULL_SCREEN_INTENT);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_ACTION_TYPE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_LOCKED);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_PLAY_SOUND);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_CUSTOM_SOUND);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_TICKER);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_PAYLOAD);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_AUTO_DISMISSIBLE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_LAYOUT);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_CREATED_SOURCE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_CREATED_LIFECYCLE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_DISPLAYED_DATE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_CREATED_DATE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_CHANNEL_KEY);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_CATEGORY);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_AUTO_DISMISSIBLE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_COLOR);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_BACKGROUND_COLOR);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_ICON);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_LARGE_ICON);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_BIG_PICTURE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_PROGRESS);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_GROUP_KEY);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_PRIVACY);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_PRIVATE_MESSAGE);
        TestUtils.testModelField(contentModel, Definitions.NOTIFICATION_MESSAGES);
    }

    @Test
    public void validate() {
    }
}