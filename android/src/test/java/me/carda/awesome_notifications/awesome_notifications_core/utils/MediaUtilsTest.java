package me.carda.awesome_notifications.awesome_notifications_core.utils;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_core.enumerators.MediaSource;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

public class MediaUtilsTest {

    @Before
    public void setUp() throws Exception {
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void testGetMediaSourceType() {

        MediaUtils mediaUtils = new BitmapUtils();

        assertEquals("Null paths must be unknown", MediaSource.Unknown, mediaUtils.getMediaSourceType(null));
        assertEquals("A relative web path must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("app/files/androidapp/imagefile.png"));

        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("resource://"));
        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("file://"));
        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("asset://"));
        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("http://"));
        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("https://"));
        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("http://www."));
        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("https://www."));
        assertEquals("Incomplete paths must be considered not valid", MediaSource.Unknown, mediaUtils.getMediaSourceType("https:/media.com/image.jpg"));

        assertEquals("Type's prefix must be case insensitive", MediaSource.File, mediaUtils.getMediaSourceType("File://app/files/androidapp/imagefile.png"));
        assertEquals("Type's prefix must be case insensitive", MediaSource.File, mediaUtils.getMediaSourceType("file://app/files/androidapp/imagefile.png"));
        assertEquals("Type's prefix must be case insensitive", MediaSource.Resource, mediaUtils.getMediaSourceType("resource://app/files/androidapp/imagefile.png"));
        assertEquals("Type's prefix must be case insensitive", MediaSource.Resource, mediaUtils.getMediaSourceType("Resource://app/files/androidapp/imagefile.png"));
        assertEquals("Type's prefix must be case insensitive", MediaSource.Asset, mediaUtils.getMediaSourceType("asset://assets/img/imagefile.png"));
        assertEquals("Type's prefix must be case insensitive", MediaSource.Asset, mediaUtils.getMediaSourceType("Asset://assets/img/imagefile.png"));
        assertEquals("Type's prefix must be case insensitive", MediaSource.Network, mediaUtils.getMediaSourceType("Http://media.com/image.jpg"));
        assertEquals("Type's prefix must be case insensitive", MediaSource.Network, mediaUtils.getMediaSourceType("http://media.com/image.jpg"));

        assertEquals("Valid http address must be considered valid", MediaSource.Network, mediaUtils.getMediaSourceType("http://www.media.com"));
        assertEquals("Valid https address must be considered valid", MediaSource.Network, mediaUtils.getMediaSourceType("https://media.com"));
        assertEquals("WWW address without termination must be considered valid", MediaSource.Network, mediaUtils.getMediaSourceType("https://media.com/image"));
        assertEquals("WWW jpg address files must be considered valid", MediaSource.Network, mediaUtils.getMediaSourceType("https://media.com/image.jpg"));
        assertEquals("WWW png address files must be considered valid", MediaSource.Network, mediaUtils.getMediaSourceType("https://media.com/image.png"));
    }

    @Test
    public void testCleanMediaPath() {

        MediaUtils mediaUtils = new MediaUtils() {
            @Override
            protected Boolean matchMediaType(String regex, String mediaPath) {
                return super.matchMediaType(regex, mediaPath);
            }
        };

        assertNull("Null values must return null", mediaUtils.cleanMediaPath(null));

        assertEquals("Network address must be preserved", "http://www.media.com",        mediaUtils.cleanMediaPath("http://www.media.com"));
        assertEquals("Network address must be preserved", "https://media.com",           mediaUtils.cleanMediaPath("https://media.com"));
        assertEquals("Network address must be preserved", "https://media.com/image",     mediaUtils.cleanMediaPath("https://media.com/image"));
        assertEquals("Network address must be preserved", "https://media.com/image.jpg", mediaUtils.cleanMediaPath("https://media.com/image.jpg"));
        assertEquals("Network address must be preserved", "https://media.com/image.png", mediaUtils.cleanMediaPath("https://media.com/image.png"));

        assertEquals("File address must remove the type address tag", "/app/files/androidapp/imagefile.png", mediaUtils.cleanMediaPath("file://app/files/androidapp/imagefile.png"));
        assertEquals("Resource address must remove the type address tag", "drawable/ic_launcher", mediaUtils.cleanMediaPath("resource://drawable/ic_launcher"));

        assertEquals("Assets address must remove the type address tag", "assets/img/imagefile.png", mediaUtils.cleanMediaPath("asset://assets/img/imagefile.png"));
    }
}