package me.carda.awesome_notifications.core.enumerators;

import org.junit.Test;

import static org.junit.Assert.*;

public class MediaSourceTest {

    @Test
    public void testEnumOrder() {
        String errorMessage = "";

        assertEquals(errorMessage, 0, MediaSource.Resource.ordinal());
        assertEquals(errorMessage, 1, MediaSource.Asset.ordinal());
        assertEquals(errorMessage, 2, MediaSource.File.ordinal());
        assertEquals(errorMessage, 3, MediaSource.Network.ordinal());
        assertEquals(errorMessage, 4, MediaSource.Unknown.ordinal());
    }
}