package me.carda.awesome_notifications.awesome_notifications_android_core.services;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;

import android.content.Intent;

import androidx.annotation.NonNull;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.notifications.NotificationForegroundThread;

public class ForegroundServiceTest {

    @Before
    public void setUp() throws Exception {
        TestUtils.startMockedContext();
    }

    @After
    public void tearDown() throws Exception {
        TestUtils.stopMockedContext();
    }

    @Test
    public void isForegroundServiceRunning() {
    }

    @Test
    public void start(){

    }

    @Test
    public void stop() {
    }

    @Test
    public void onStartCommand() throws AwesomeNotificationException {
        MockedStatic<NotificationForegroundThread> foregroundServiceStatic =
                mockStatic(NotificationForegroundThread.class);

        Intent mockedIntent = mock(Intent.class);

        ForegroundService foregroundService = new ForegroundService();
        foregroundService.onStartCommand(mockedIntent, 0, 0);
        /*
        foregroundService.when(
            () ->
                NotificationForegroundService.start(
                    any(Context.class),
                    anyInt(),
                    any(ForegroundService.ForegroundServiceIntent.class),
                    any(NotificationBuilder.class),
                    any(NotificationLifeCycle.class),
                    any(NotificationModel.class)));*/

        foregroundServiceStatic.close();
    }

    @Test
    public void onBind() {
        Intent mockedIntent = mock(Intent.class);
        assertNull(new AutoCancelService().onBind(mockedIntent));
    }
}