package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;

import static org.junit.Assert.*;

public class DefaultsModelTest {

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
        DefaultsModel defaultsModel = new DefaultsModel();

        TestUtils.testModelField(defaultsModel, Definitions.NOTIFICATION_APP_ICON);
        TestUtils.testModelField(defaultsModel, Definitions.SILENT_HANDLE);
        TestUtils.testModelField(defaultsModel, Definitions.DART_BG_HANDLE);
    }

    @Test
    public void validate() {
    }
}