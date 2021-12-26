package me.carda.awesome_notifications.awesome_notifications_android_core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class GroupSortTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";
        assertEquals(errorMessage, 0, GroupSort.Asc.ordinal());
        assertEquals(errorMessage, 1, GroupSort.Desc.ordinal());
    }
}