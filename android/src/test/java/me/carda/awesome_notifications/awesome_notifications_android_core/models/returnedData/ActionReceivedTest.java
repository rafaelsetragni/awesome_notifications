package me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData;

import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;

import static org.junit.Assert.*;

public class ActionReceivedTest {

    @Test
    public void fromJsonAndToJson() {
        ActionReceived actionReceived = new ActionReceived();

        TestUtils.testModelField(actionReceived, Definitions.NOTIFICATION_BUTTON_KEY_PRESSED);
        TestUtils.testModelField(actionReceived, Definitions.NOTIFICATION_BUTTON_KEY_INPUT);
        TestUtils.testModelField(actionReceived, Definitions.NOTIFICATION_ACTION_DATE);
        TestUtils.testModelField(actionReceived, Definitions.NOTIFICATION_DISMISSED_DATE);

        TestUtils.testModelField(actionReceived, Definitions.NOTIFICATION_ACTION_LIFECYCLE);
        TestUtils.testModelField(actionReceived, Definitions.NOTIFICATION_DISMISSED_LIFECYCLE);
    }

}