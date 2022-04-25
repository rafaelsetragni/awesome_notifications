package me.carda.awesome_notifications.core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.TestUtils;

public class NotificationChannelGroupModelTest {

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
        NotificationChannelGroupModel channelGroupModel = new NotificationChannelGroupModel();

        TestUtils.testModelField(channelGroupModel, Definitions.NOTIFICATION_CHANNEL_GROUP_NAME);
        TestUtils.testModelField(channelGroupModel, Definitions.NOTIFICATION_CHANNEL_GROUP_KEY);
    }

    @Test
    public void validate() {
    }
}