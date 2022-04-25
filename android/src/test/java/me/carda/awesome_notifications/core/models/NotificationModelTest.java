package me.carda.awesome_notifications.core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.core.Definitions;

public class NotificationModelTest {

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
        NotificationModel notificationModel = new NotificationModel();
    }

    @Test
    public void clonePush() {
    }

    @Test
    public void validate() {
    }
}