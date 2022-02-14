package me.carda.awesome_notifications.awesome_notifications_core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class ActionTypeTest {

    @Test
    public void testEnumOrder(){
        String errorMessage = "";

        assertEquals(errorMessage, 0, ActionType.Default.ordinal());
        assertEquals(errorMessage, 1, ActionType.DisabledAction.ordinal());
        assertEquals(errorMessage, 2, ActionType.KeepOnTop.ordinal());
        assertEquals(errorMessage, 3, ActionType.SilentAction.ordinal());
        assertEquals(errorMessage, 4, ActionType.SilentBackgroundAction.ordinal());
    }

}