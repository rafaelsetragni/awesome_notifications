package me.carda.awesome_notifications.awesome_notifications_core.models;

import android.content.Context;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.io.Serializable;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.TestEnum;
import me.carda.awesome_notifications.awesome_notifications_core.TestModel;
import me.carda.awesome_notifications.awesome_notifications_core.TestUtils;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

import static org.junit.Assert.*;

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