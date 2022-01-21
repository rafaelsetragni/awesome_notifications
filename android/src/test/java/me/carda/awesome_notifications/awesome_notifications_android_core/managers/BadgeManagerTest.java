package me.carda.awesome_notifications.awesome_notifications_android_core.managers;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;

import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import org.hamcrest.core.Is;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import org.mockito.MockedConstruction;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import static me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils.mockContext;
import static me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils.startMockedContext;
import static me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils.stopMockedContext;

import me.leolin.shortcutbadger.ShortcutBadger;

public class BadgeManagerTest {

    MockedStatic<PreferenceManager> mockedPreference;
    MockedStatic<ShortcutBadger> mockedShortcutBadger;

    SharedPreferences mockedPrefs;
    SharedPreferences.Editor mockedEditor;

    @Before
    public void setUp() {

        mockedPrefs = mock(SharedPreferences.class);
        mockedEditor = mock(SharedPreferences.Editor.class);

        when(mockedPrefs.edit()).thenReturn(mockedEditor);
        doNothing().when(mockedEditor).apply();
        when(mockedEditor.putInt(anyString(), anyInt())).thenReturn(mockedEditor);

        mockedPreference = mockStatic(PreferenceManager.class);
        mockedPreference.when(() -> PreferenceManager.getDefaultSharedPreferences(any())).thenReturn(mockedPrefs);

        mockedShortcutBadger = mockStatic(ShortcutBadger.class);
        mockedShortcutBadger.when(() -> ShortcutBadger.applyCount(any(), anyInt())).thenReturn(true);

        startMockedContext();
    }

    @After
    public void tearDown(){
        mockedPreference.close();
        mockedShortcutBadger.close();
        stopMockedContext();
    }

    @Test
    public void getGlobalBadgeCounter() {
        when(mockedPrefs.getInt(anyString(), anyInt())).thenReturn(0);
        assertEquals("If there is no value defined, it must returns 0", BadgeManager.getInstance().getGlobalBadgeCounter(mockContext), 0);

        when(mockedPrefs.getInt(anyString(), anyInt())).thenReturn(99999);
        assertEquals("It must return the maximum value possible", BadgeManager.getInstance().getGlobalBadgeCounter(mockContext), 99999);

        when(mockedPrefs.getInt(anyString(), anyInt())).thenReturn(-1);
        assertEquals("If the value was stored wrongly, the value returned must be 0", BadgeManager.getInstance().getGlobalBadgeCounter(mockContext), 0);
    }

    @Test
    public void setGlobalBadgeCounter() {
        BadgeManager.getInstance().setGlobalBadgeCounter(mockContext, 0);

        verify(mockedEditor, times(1)).putInt(anyString(), eq(0));
        mockedShortcutBadger.verify(times(1), () -> ShortcutBadger.applyCount(any(), eq(0)));
    }

    @Test
    public void resetGlobalBadgeCounter() {

        BadgeManager sud = mock(BadgeManager.class);
        doNothing().when(sud).setGlobalBadgeCounter(any(), eq(0));
        sud.resetGlobalBadgeCounter(mockContext);
        verify(sud, times(1)).resetGlobalBadgeCounter(any());
    }

    @Test
    public void incrementGlobalBadgeCounter() {
    }

    @Test
    public void decrementGlobalBadgeCounter() {
    }

    @Test
    public void isBadgeDeviceGloballyAllowed() {

    }

    @Test
    public void isBadgeNumberingAllowed() {

    }

    @Test
    public void isBadgeAppGloballyAllowed() {

    }

    @Test
    public void isBadgeGloballyAllowed() {

    }

    @Test
    public void getInstance() {
        LifeCycleManager.instance = null;
        assertNotNull("Singleton instance returned null", LifeCycleManager.getInstance());
        assertNotNull("Singleton instance returned null", LifeCycleManager.getInstance());
    }

}