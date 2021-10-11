package android.src.main.test.java.me.carda.awesome_notifications.utils;

import org.junit.Test;

import me.carda.push_notifications.notifications.enumerators.MediaSource;

import static org.junit.Assert.assertEquals;

public class MediaUtilsTest {

    @Test
    public void getMediaSourceType() {
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType(null));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("app/files/androidapp/imagefile.png"));

        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("resource://"));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("file://"));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("asset://"));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("http://"));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("https://"));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("http://www."));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("https://www."));
        assertEquals(MediaSource.Unknown, BitmapUtils.getMediaSourceType("https:/media.com/image.jpg"));

        assertEquals(MediaSource.File, BitmapUtils.getMediaSourceType("File://app/files/androidapp/imagefile.png"));
        assertEquals(MediaSource.File, BitmapUtils.getMediaSourceType("file://app/files/androidapp/imagefile.png"));

        assertEquals(MediaSource.Resource, BitmapUtils.getMediaSourceType("resource://app/files/androidapp/imagefile.png"));
        assertEquals(MediaSource.Resource, BitmapUtils.getMediaSourceType("Resource://app/files/androidapp/imagefile.png"));

        assertEquals(MediaSource.Asset, BitmapUtils.getMediaSourceType("asset://assets/img/imagefile.png"));
        assertEquals(MediaSource.Asset, BitmapUtils.getMediaSourceType("Asset://assets/img/imagefile.png"));

        assertEquals(MediaSource.Network, BitmapUtils.getMediaSourceType("http://www.media.com"));
        assertEquals(MediaSource.Network, BitmapUtils.getMediaSourceType("https://media.com"));
        assertEquals(MediaSource.Network, BitmapUtils.getMediaSourceType("https://media.com/image"));
        assertEquals(MediaSource.Network, BitmapUtils.getMediaSourceType("https://media.com/image.jpg"));
        assertEquals(MediaSource.Network, BitmapUtils.getMediaSourceType("https://media.com/image.png"));
    }

    @Test
    public void cleanMediaPath() {

        assertEquals("http://www.media.com",        BitmapUtils.cleanMediaPath("http://www.media.com"));
        assertEquals("https://media.com",           BitmapUtils.cleanMediaPath("https://media.com"));
        assertEquals("https://media.com/image",     BitmapUtils.cleanMediaPath("https://media.com/image"));
        assertEquals("https://media.com/image.jpg", BitmapUtils.cleanMediaPath("https://media.com/image.jpg"));
        assertEquals("https://media.com/image.png", BitmapUtils.cleanMediaPath("https://media.com/image.png"));

        assertEquals("/app/files/androidapp/imagefile.png", BitmapUtils.cleanMediaPath("file://app/files/androidapp/imagefile.png"));
        assertEquals("drawable/ic_launcher", BitmapUtils.cleanMediaPath("resource://drawable/ic_launcher"));

        assertEquals("assets/img/imagefile.png", BitmapUtils.cleanMediaPath("asset://assets/img/imagefile.png"));
    }
}