package me.carda.awesome_notifications.awesome_notifications_core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class GroupAlertBehaviourTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, GroupAlertBehaviour.All.ordinal());
        assertEquals(errorMessage, 1, GroupAlertBehaviour.Summary.ordinal());
        assertEquals(errorMessage, 2, GroupAlertBehaviour.Children.ordinal());
    }
}