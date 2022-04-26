package me.carda.awesome_notifications.core.services;

import static org.junit.Assert.*;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.app.Service;
import android.content.Intent;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.core.TestUtils;

public class AutoCancelServiceTest {

    @Before
    public void setUp() throws Exception {
        TestUtils.startMockedLog();
    }

    @After
    public void tearDown() throws Exception {
        TestUtils.stopMockedLog();
    }

    @Test
    public void onBind() {
        Intent mockedIntent = mock(Intent.class);
        assertNull(new AutoCancelService().onBind(mockedIntent));
    }

    @Test
    public void onTaskRemoved() {
        Service autoCancelService = spy(new AutoCancelService());
        doNothing().when(spy(autoCancelService)).stopSelf();
        autoCancelService.onTaskRemoved(mock(Intent.class));

        verify(autoCancelService, times(1)).stopSelf();
    }
}