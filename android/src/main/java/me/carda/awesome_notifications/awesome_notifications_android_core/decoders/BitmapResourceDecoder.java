package me.carda.awesome_notifications.awesome_notifications_android_core.decoders;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.AsyncTask;

import java.io.ByteArrayOutputStream;
import java.lang.ref.WeakReference;

import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.BitmapUtils;

public class BitmapResourceDecoder extends AsyncTask<Void, Void, byte[]> {

    public static final String TAG = "BitmapResourceDecoder";

    //the reason to use a weak reference is to protect from memory leak issues.
    private final WeakReference<Context> wContextReference;
    private final String bitmapReference;

    private final BitmapCompletionHandler completionHandler;

    private Exception exception;

    public BitmapResourceDecoder(Context context, String bitmapReference, BitmapCompletionHandler completionHandler) {
        this.wContextReference = new WeakReference<>(context);
        this.bitmapReference = bitmapReference;
        this.completionHandler = completionHandler;
    }

    @Override
    protected byte[] doInBackground(Void... params) {

        Context context = wContextReference.get();

        try {

            if(context != null) {
                Bitmap bitmap = BitmapUtils
                        .getInstance()
                        .getBitmapFromResource(context, bitmapReference);

                if(bitmap == null) throw new AwesomeNotificationException("File '"+bitmapReference+"' not found or invalid");

                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
                byte[] byteArray = stream.toByteArray();
                bitmap.recycle();

                return byteArray;
            }

        } catch (Exception e){
            exception = e;
        }

        return null;
    }

    @Override
    protected void onPostExecute(byte[] byteArray) {
        completionHandler.handle(byteArray, exception);
    }
}