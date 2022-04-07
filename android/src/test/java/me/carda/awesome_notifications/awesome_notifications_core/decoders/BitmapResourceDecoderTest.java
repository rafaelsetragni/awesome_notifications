package me.carda.awesome_notifications.awesome_notifications_core.decoders;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isA;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockConstruction;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.graphics.Bitmap;

import androidx.annotation.NonNull;

import org.hamcrest.core.Is;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedConstruction;
import org.mockito.MockedStatic;
import org.mockito.Mockito;

import java.io.ByteArrayOutputStream;

import me.carda.awesome_notifications.awesome_notifications_core.TestUtils;
import me.carda.awesome_notifications.awesome_notifications_core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.utils.BitmapUtils;

public class BitmapResourceDecoderTest {

    @Before
    public void setUp() throws Exception {
        TestUtils.startMockedContext();
    }

    @After
    public void tearDown() throws Exception {
        TestUtils.stopMockedContext();
    }

    @Test
    public void convertBitmapToByteArray() {
        Bitmap bitmapMock = mock(Bitmap.class);
        doNothing().when(bitmapMock).recycle();
        when(
            bitmapMock
                .compress(
                        any(Bitmap.CompressFormat.class),
                        anyInt(),
                        any(ByteArrayOutputStream.class))
                )
                .thenReturn(true);

        ByteArrayOutputStream mockOutputStream = mock(ByteArrayOutputStream.class);
        when(mockOutputStream.toByteArray()).thenReturn(new byte[]{0,1,2,3});

        assertArrayEquals(
                new byte[]{0,1,2,3},
                new BitmapResourceDecoder(
                        TestUtils.mockContext,
                        null,
                        new BitmapCompletionHandler() {
                            @Override
                            public void handle(byte[] byteArray, AwesomeNotificationsException exception) {
                            }
                        }
                ).convertBitmapToByteArray(bitmapMock, mockOutputStream)
        );

        when(mockOutputStream.toByteArray()).thenReturn(null);

        assertNull(
                new BitmapResourceDecoder(
                        TestUtils.mockContext,
                        null,
                        new BitmapCompletionHandler() {
                            @Override
                            public void handle(byte[] byteArray, AwesomeNotificationsException exception) {
                            }
                        }
                ).convertBitmapToByteArray(bitmapMock, mockOutputStream)
        );
    }

    @Test
    public void doInBackground() {

        BitmapUtils bitmapMock = mock(BitmapUtils.class);
        MockedStatic<BitmapUtils> mockedBitmapStatic = mockStatic(BitmapUtils.class);
        mockedBitmapStatic.when(() -> BitmapUtils.getInstance()).thenReturn(bitmapMock);

        when(bitmapMock.getBitmapFromResource(any(Context.class), isNull()))
                .thenReturn(null);

        assertNull(
                new BitmapResourceDecoder(
                        TestUtils.mockContext,
                        null,
                        new BitmapCompletionHandler() {
                            @Override
                            public void handle(byte[] byteArray, AwesomeNotificationsException exception) {
                            }
                        }
                ).doInBackground());

        assertNull(
                new BitmapResourceDecoder(
                        null,
                        "",
                        new BitmapCompletionHandler() {
                            @Override
                            public void handle(byte[] byteArray, AwesomeNotificationsException exception) {
                            }
                        }
                ).doInBackground());

        when(bitmapMock.getBitmapFromResource(any(Context.class), eq("")))
                .thenReturn(null);

        assertNull(
                new BitmapResourceDecoder(
                        TestUtils.mockContext,
                        "",
                        new BitmapCompletionHandler() {
                            @Override
                            public void handle(byte[] byteArray, AwesomeNotificationsException exception) {
                            }
                        }
                ).doInBackground());

        when(bitmapMock.getBitmapFromResource(any(Context.class), eq("resource://drawable/testImage")))
                .thenReturn(mock(Bitmap.class));

        class TestResource1 extends BitmapResourceDecoder{

            public TestResource1(Context context, String bitmapReference, BitmapCompletionHandler completionHandler) {
                super(context, bitmapReference, completionHandler);
            }

            @Override
            byte[] convertBitmapToByteArray(
                    @NonNull Bitmap bitmap,
                    @NonNull ByteArrayOutputStream outputStream){
                return new byte[]{0,1,2,3};
            }

        }

        BitmapResourceDecoder resourceDecoder = new TestResource1(
                TestUtils.mockContext,
                "resource://drawable/testImage",
                new BitmapCompletionHandler() {
                    @Override
                    public void handle(byte[] byteArray, Exception exception) {
                    }
                });

        /* THIS SHIT DOESNT WORK AT ALL
        doReturn(new byte[]{0,1,2,3})
                .when(spy(resourceDecoder))
                .convertBitmapToByteArray(
                    any(Bitmap.class),
                    any(ByteArrayOutputStream.class));*/

        Assert.assertArrayEquals(
                new byte[]{0,1,2,3},
                resourceDecoder.doInBackground());

        mockedBitmapStatic.close();
    }

    @Test
    public void onPostExecute() {

        BitmapResourceDecoder resourceDecoder = new BitmapResourceDecoder(
                TestUtils.mockContext,
                "resource://drawable/testImage",
                new BitmapCompletionHandler() {
                    @Override
                    public void handle(byte[] byteArray, AwesomeNotificationsException exception) {
                        assertArrayEquals(new byte[]{0,1,2,3}, byteArray);
                        assertNull(exception);
                    }
                });

        resourceDecoder.onPostExecute(new byte[]{0,1,2,3});
    }
}