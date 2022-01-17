package me.carda.awesome_notifications.awesome_notifications_android_core.utils;

import static org.junit.Assert.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.res.Resources;
import android.test.mock.MockContext;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_android_core.TestUtils;

public class AudioUtilsTest {

    Context mockContext;
    Resources mockResources;

    @Before
    public void setUp() throws Exception {
        mockContext =  mock(MockContext.class);
        mockResources =  mock(Resources.class);

        when(mockContext.getPackageName())
                .thenReturn("com.test.testPackage");
        when(mockContext.getResources())
                .thenReturn(mockResources);
    }

    @After
    public void tearDown() throws Exception {
        mockContext = null;
        mockResources = null;
    }

    @Test
    public void getInstance() {
        AudioUtils audioUtils1 = AudioUtils.getInstance();
        assertNotNull("", audioUtils1);

        AudioUtils audioUtils2 = AudioUtils.getInstance();
        assertNotNull("", audioUtils2);

        assertEquals("", audioUtils1, audioUtils2);
    }

    @Test
    public void getAudioFromSource() {
    }

    @Test
    public void getAudioSourceType() {
    }

    @Test
    public void getAudioResourceId() {

        assertEquals("An invalid resource must return an invalid reference",
                0,
                AudioUtils.getInstance().getAudioResourceId(TestUtils.mockContext, "resource://testIcon"));

        when(TestUtils.mockResources.getIdentifier("testIcon", "raw", "com.test.testPackage"))
                .thenReturn(500);

        assertEquals("",
                500,
                AudioUtils.getInstance().getAudioResourceId(TestUtils.mockContext, "resource://raw/testIcon"));

        when(TestUtils.mockResources.getIdentifier("res_testIcon", "raw", "com.test.testPackage"))
                .thenReturn(501);

        assertEquals("",
                501,
                AudioUtils.getInstance().getAudioResourceId(TestUtils.mockContext, "resource://raw/testIcon"));

        when(TestUtils.mockResources.getIdentifier("testIcon2", "raw", "com.test.testPackage"))
                .thenReturn(0);

        assertEquals("",
                0,
                AudioUtils.getInstance().getAudioResourceId(TestUtils.mockContext, "resource://raw/testIcon2"));
    }

    @Test
    public void isValidAudio() {

        assertFalse("A null reference is always a invalid bitmap reference",
                AudioUtils.getInstance().isValidAudio(TestUtils.mockContext,null));

        String networkErrorMessage = "There is no valid audio resource for notifications from network resources";
        assertFalse(networkErrorMessage, AudioUtils.getInstance().isValidAudio(TestUtils.mockContext,"http://test.com/image.jpg"));
        assertFalse(networkErrorMessage, AudioUtils.getInstance().isValidAudio(TestUtils.mockContext,"https://test.com/image.jpg"));
        assertFalse(networkErrorMessage, AudioUtils.getInstance().isValidAudio(TestUtils.mockContext,"http://www.test.com/image.jpg"));
        assertFalse(networkErrorMessage, AudioUtils.getInstance().isValidAudio(TestUtils.mockContext,"https://www.test.com/image.jpg"));

        String assetErrorMessage = "There is no valid audio resource for notifications from asset resources";
        assertFalse(assetErrorMessage, AudioUtils.getInstance().isValidAudio(TestUtils.mockContext,"asset://assets/image.jpg"));

        String fileErrorMessage = "There is no valid audio resource for notifications from file resources";
        assertFalse(fileErrorMessage, AudioUtils.getInstance().isValidAudio(TestUtils.mockContext,"file://path/to/file/image.jpg"));

        when(TestUtils.mockResources.getIdentifier("testAudio1", "raw", "com.test.testPackage"))
                .thenReturn(500);

        when(TestUtils.mockResources.getIdentifier("testAudio2", "raw", "com.test.testPackage"))
                .thenReturn(0);

        assertTrue("A valid audio resource was not identified as valid reference", AudioUtils.getInstance().isValidAudio(mockContext,"resource://raw/testAudio1"));
        assertFalse("An invalid audio resource was not identified as invalid reference", AudioUtils.getInstance().isValidAudio(mockContext,"resource://raw/testAudio2"));
    }
}