package me.carda.awesome_notifications.core.decoders;

import android.content.Context;
import android.graphics.Bitmap;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.ByteArrayOutputStream;
import java.lang.ref.WeakReference;

import me.carda.awesome_notifications.core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.threads.NotificationThread;
import me.carda.awesome_notifications.core.utils.BitmapUtils;

public class BitmapResourceDecoder extends NotificationThread<byte[]> {

    public static final String TAG = "BitmapResourceDecoder";

    //the reason to use a weak reference is to protect from memory leak issues.
    private final WeakReference<Context> wContextReference;
    private final String bitmapReference;

    private final BitmapCompletionHandler completionHandler;

    private Exception exception;

    public BitmapResourceDecoder(
            @NonNull Context context,
            @Nullable String bitmapReference,
            @NonNull BitmapCompletionHandler completionHandler
    ){
        this.wContextReference = new WeakReference<>(context);
        this.bitmapReference = bitmapReference;
        this.completionHandler = completionHandler;
    }

    byte[] convertBitmapToByteArray(
            @NonNull Bitmap bitmap,
            @NonNull ByteArrayOutputStream outputStream
    ){
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
        byte[] byteArray = outputStream.toByteArray();
        bitmap.recycle();

        return byteArray;
    }

    @Override
    protected byte[] doInBackground() throws AwesomeNotificationsException {
        Context context = wContextReference.get();
        if(context != null) {
            Bitmap bitmap = BitmapUtils
                    .getInstance()
                    .getBitmapFromResource(context, bitmapReference);

            if(bitmap == null)
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_BACKGROUND_EXECUTION_EXCEPTION,
                                "File '"+
                                        (bitmapReference == null ? "null" : bitmapReference)+
                                        "' not found or invalid",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS+".bitmap.reference");

            return convertBitmapToByteArray(
                    bitmap,
                    new ByteArrayOutputStream());
        }
        else
            return null;
    }

    @Override
    protected byte[] onPostExecute(byte[] byteArray) {
        return byteArray;
    }

    @Override
    protected void whenComplete(
            @Nullable byte[] returnedValue,
            @Nullable AwesomeNotificationsException exception
    ) {
        completionHandler.handle(returnedValue, exception);
    }
}