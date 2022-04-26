package me.carda.awesome_notifications.core.enumerators;

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