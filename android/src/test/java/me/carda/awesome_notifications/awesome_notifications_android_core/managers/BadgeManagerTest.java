package me.carda.awesome_notifications.awesome_notifications_android_core.managers;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;

import android.content.SharedPreferences;
import android.os.Build;
import android.preference.PreferenceManager;
import android.provider.Settings;

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
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import static me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils.mockContext;
import static me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils.setFinalStaticField;
import static me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils.startMockedContext;
import static me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils.stopMockedContext;

import me.leolin.shortcutbadger.ShortcutBadgeException;
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
        doNothing().when(sud).setGlobalBadgeCounter(any(), anyInt());
        sud.resetGlobalBadgeCounter(mockContext);
        verify(sud, times(1)).resetGlobalBadgeCounter(any());
    }

    @Test
    public void incrementGlobalBadgeCounter() {
        BadgeManager sud = BadgeManager.getInstance();
        BadgeManager spyReference = spy(sud);

        doNothing().when(spyReference).setGlobalBadgeCounter(any(), anyInt());

        when(spyReference.getGlobalBadgeCounter(any())).thenReturn(0);
        assertEquals(1, sud.incrementGlobalBadgeCounter(mockContext));

        //verify(spyReference, times(1)).setGlobalBadgeCounter(any(), anyInt());

        when(spyReference.getGlobalBadgeCounter(any())).thenReturn(1);
        assertEquals(2, sud.incrementGlobalBadgeCounter(mockContext));

        when(spyReference.getGlobalBadgeCounter(any())).thenReturn(9998);
        assertEquals(9999, sud.incrementGlobalBadgeCounter(mockContext));
    }

    @Test
    public void decrementGlobalBadgeCounter() {
        BadgeManager sud = BadgeManager.getInstance();
        BadgeManager spyReference = spy(sud);

        doNothing().when(spyReference).setGlobalBadgeCounter(any(), anyInt());

        when(spyReference.getGlobalBadgeCounter(any())).thenReturn(9999);
        assertEquals(9998, sud.decrementGlobalBadgeCounter(mockContext));

        when(spyReference.getGlobalBadgeCounter(any())).thenReturn(1);
        assertEquals(0, sud.decrementGlobalBadgeCounter(mockContext));

        //verify(spyReference, times(1)).setGlobalBadgeCounter(any(), anyInt());

        when(spyReference.getGlobalBadgeCounter(any())).thenReturn(0);
        assertEquals(0, sud.decrementGlobalBadgeCounter(mockContext));
    }

    @Test
    public void isBadgeDeviceGloballyAllowed() {
        BadgeManager sud = BadgeManager.getInstance();
        MockedStatic<Settings.Secure> secureMockedStatic = mockStatic(Settings.Secure.class);

        secureMockedStatic.when(() -> Settings.Secure.getInt(any(), eq("notification_badging"))).thenReturn(PermissionManager.ON);
        assertTrue(sud.isBadgeDeviceGloballyAllowed(mockContext));

        secureMockedStatic.when(() -> Settings.Secure.getInt(any(), eq("notification_badging"))).thenReturn(PermissionManager.OFF);
        assertFalse(sud.isBadgeDeviceGloballyAllowed(mockContext));

        secureMockedStatic.close();
    }

    @Test
    public void isBadgeNumberingAllowed() {
        BadgeManager sud = BadgeManager.getInstance();

        mockedShortcutBadger.when(()-> ShortcutBadger.applyCountOrThrow(any(), anyInt())).thenAnswer(invocation -> null);
        assertTrue(sud.isBadgeNumberingAllowed(any()));

        mockedShortcutBadger.when(()-> ShortcutBadger.applyCountOrThrow(any(), anyInt())).thenThrow(ShortcutBadgeException.class);
        assertFalse(sud.isBadgeNumberingAllowed(any()));
    }

    @Test
    public void isBadgeAppGloballyAllowed() {
        BadgeManager sud = BadgeManager.getInstance();

        // TODO missing implementation
        assertTrue(sud.isBadgeAppGloballyAllowed(mockContext));

    }

    @Test
    public void isBadgeGloballyAllowed() {

        try {
            BadgeManager sud1 = new BadgeManager();
            setFinalStaticField(Build.VERSION.class.getField("SDK_INT"), Build.VERSION_CODES.M);
            assertTrue(
                    "Android older than Marshmallow does not have badges. Permissions are considered enabled case are not available.",
                    sud1.isBadgeGloballyAllowed(mockContext));

            setFinalStaticField(Build.VERSION.class.getField("SDK_INT"), Build.VERSION_CODES.N);

            BadgeManager sud2 = new BadgeManager();
            BadgeManager spyReference2 = spy(sud2);
            doReturn(false).when(spyReference2).isBadgeDeviceGloballyAllowed(any());
            doReturn(false).when(spyReference2).isBadgeAppGloballyAllowed(any());
            assertFalse(
                    "If the badge is disable on app level, it must return false",
                    sud2.isBadgeGloballyAllowed(mockContext));

            BadgeManager sud3 = new BadgeManager();
            BadgeManager spyReference3 = spy(sud3);
            doReturn(true).when(spyReference3).isBadgeDeviceGloballyAllowed(any());
            doReturn(false).when(spyReference3).isBadgeAppGloballyAllowed(any());
            assertFalse(
                    "If the badge is disable on device level, it must return false",
                    sud3.isBadgeGloballyAllowed(mockContext));

            BadgeManager sud4 = mock(BadgeManager.class);
            doReturn(true).when(sud4).isBadgeDeviceGloballyAllowed(any());
            doReturn(true).when(sud4).isBadgeAppGloballyAllowed(any());
            assertTrue(
                    "If the badge is enable on both device and app level, it must return true",
                    sud4.isBadgeGloballyAllowed(mockContext));

        } catch (NoSuchFieldException e) {
            e.printStackTrace();
            fail("SDK could not be mocked");
        }

    }

    @Test
    public void getInstance() {
        LifeCycleManager.instance = null;
        assertNotNull("Singleton instance returned null", LifeCycleManager.getInstance());
        assertNotNull("Singleton instance returned null", LifeCycleManager.getInstance());
    }

}