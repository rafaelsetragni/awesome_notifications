package me.carda.awesome_notifications.awesome_notifications_core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.TestUtils;

import static org.junit.Assert.*;

import java.util.HashMap;

public class NotificationButtonModelTest {

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
        NotificationButtonModel buttonModel = new NotificationButtonModel();

        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_BUTTON_KEY);
        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_BUTTON_ICON);
        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_BUTTON_LABEL);
        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_COLOR);

        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_ACTION_TYPE);

        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_ENABLED);
        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT);
        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_AUTO_DISMISSIBLE);
        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW);
        TestUtils.testModelField(buttonModel, Definitions.NOTIFICATION_IS_DANGEROUS_OPTION);
    }

    @Test
    public void validate() {
    }
}