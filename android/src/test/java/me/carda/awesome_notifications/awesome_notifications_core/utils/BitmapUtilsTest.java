package me.carda.awesome_notifications.awesome_notifications_core.utils;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.test.mock.MockContext;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;

public class BitmapUtilsTest {

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
        BitmapUtils bitmapUtils = BitmapUtils.getInstance();
        assertNotNull("", bitmapUtils);

        BitmapUtils bitmapUtils2 = BitmapUtils.getInstance();
        assertNotNull("", bitmapUtils2);

        assertEquals("", bitmapUtils, bitmapUtils2);
    }

    @Test
    public void cleanMediaPath() {

        BitmapUtils bitmapUtils = BitmapUtils.getInstance();

        assertNull("Null values must return null", bitmapUtils.cleanMediaPath(null));

        assertEquals("Network address must be preserved", "http://www.media.com",        bitmapUtils.cleanMediaPath("http://www.media.com"));
        assertEquals("Network address must be preserved", "https://media.com",           bitmapUtils.cleanMediaPath("https://media.com"));
        assertEquals("Network address must be preserved", "https://media.com/image",     bitmapUtils.cleanMediaPath("https://media.com/image"));
        assertEquals("Network address must be preserved", "https://media.com/image.jpg", bitmapUtils.cleanMediaPath("https://media.com/image.jpg"));
        assertEquals("Network address must be preserved", "https://media.com/image.png", bitmapUtils.cleanMediaPath("https://media.com/image.png"));

        assertEquals("File address must remove the type address tag", "/app/files/androidapp/imagefile.png", bitmapUtils.cleanMediaPath("file://app/files/androidapp/imagefile.png"));
        assertEquals("Resource address must remove the type address tag", "drawable/ic_launcher", bitmapUtils.cleanMediaPath("resource://drawable/ic_launcher"));

        assertEquals("Assets address must remove the type address tag", "assets/img/imagefile.png", bitmapUtils.cleanMediaPath("asset://assets/img/imagefile.png"));
    }

    @Test
    public void getDrawableResourceId() {

        assertEquals("An invalid resource must return an invalid reference",
                0,
                BitmapUtils.getInstance().getDrawableResourceId(mockContext, "resource://testIcon"));

        when(mockResources.getIdentifier("testIcon", "drawable", "com.test.testPackage"))
                .thenReturn(500);

        assertEquals("",
            500,
            BitmapUtils.getInstance().getDrawableResourceId(mockContext, "resource://drawable/testIcon"));

        when(mockResources.getIdentifier("res_testIcon", "drawable", "com.test.testPackage"))
            .thenReturn(501);

        assertEquals("",
            501,
            BitmapUtils.getInstance().getDrawableResourceId(mockContext, "resource://drawable/testIcon"));

        when(mockResources.getIdentifier("testIcon2", "drawable", "com.test.testPackage"))
                .thenReturn(0);

        assertEquals("",
                0,
                BitmapUtils.getInstance().getDrawableResourceId(mockContext, "resource://drawable/testIcon2"));
    }

    @Test
    public void getBitmapFromSource() {
    }

    @Test
    public void getBitmapFromResource() {

        when(mockResources.getIdentifier("testIcon", "drawable", "com.test.testPackage"))
                .thenReturn(500);
/*
        Bitmap mockedBitmap = mock(Bitmap.class);
        MockedStatic<BitmapFactory> mockedBmpFactory = Mockito.mockStatic(BitmapFactory.class);

        mockedBmpFactory.when(() -> BitmapFactory.decodeResource(mockResources, eq(500))).thenReturn(mockedBitmap);
        mockedBmpFactory.when(() -> BitmapFactory.decodeResource(mockResources, eq(0))).thenReturn(null);

        assertNull("",
                BitmapUtils.getInstance().getBitmapFromResource(mockContext, "resource://drawable/testIcon2"));

        assertEquals("",
                mockedBitmap, BitmapUtils.getInstance().getBitmapFromResource(mockContext, "resource://drawable/testIcon"));
*/
    }

    @Test
    public void getBitmapFromAsset() {
    }

    @Test
    public void isValidBitmap() {

        assertFalse("A null reference is always a invalid bitmap reference",
                BitmapUtils.getInstance().isValidBitmap(mockContext,null));

        String networkErrorMessage = "A valid network bitmap was not identified as valid bitmap reference";
        assertTrue(networkErrorMessage, BitmapUtils.getInstance().isValidBitmap(mockContext,"http://test.com/image.jpg"));
        assertTrue(networkErrorMessage, BitmapUtils.getInstance().isValidBitmap(mockContext,"https://test.com/image.jpg"));
        assertTrue(networkErrorMessage, BitmapUtils.getInstance().isValidBitmap(mockContext,"http://www.test.com/image.jpg"));
        assertTrue(networkErrorMessage, BitmapUtils.getInstance().isValidBitmap(mockContext,"https://www.test.com/image.jpg"));

        String assetErrorMessage = "A valid asset bitmap was not identified as valid bitmap reference";
        assertTrue(assetErrorMessage, BitmapUtils.getInstance().isValidBitmap(mockContext,"asset://assets/image.jpg"));

        String fileErrorMessage = "A valid file bitmap was not identified as valid bitmap reference";
        assertTrue(fileErrorMessage, BitmapUtils.getInstance().isValidBitmap(mockContext,"file://path/to/file/image.jpg"));

        when(mockResources.getIdentifier("testIcon", "drawable", "com.test.testPackage"))
                .thenReturn(500);

        when(mockResources.getIdentifier("testIcon2", "drawable", "com.test.testPackage"))
                .thenReturn(0);

        assertTrue("A valid resource bitmap was not identified as valid bitmap reference", BitmapUtils.getInstance().isValidBitmap(mockContext,"resource://drawable/testIcon"));
        assertFalse("An invalid resource bitmap was not identified as invalid bitmap reference", BitmapUtils.getInstance().isValidBitmap(mockContext,"resource://drawable/testIcon2"));
    }
}