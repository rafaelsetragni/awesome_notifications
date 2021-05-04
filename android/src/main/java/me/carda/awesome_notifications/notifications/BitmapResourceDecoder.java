package me.carda.awesome_notifications.notifications;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.AsyncTask;

import java.io.ByteArrayOutputStream;
import java.lang.ref.WeakReference;

import io.flutter.plugin.common.MethodChannel;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.BitmapUtils;

public class BitmapResourceDecoder extends AsyncTask<Void, Void, byte[]> {

    //the reason to use a weak reference is to protect from memory leak issues.
    private WeakReference<Context> wContextReference;
    private MethodChannel.Result result;

    private String bitmapReference;

    private Exception exception;

    public BitmapResourceDecoder(Context context, MethodChannel.Result result, String bitmapReference) {
        this.wContextReference = new WeakReference<>(context);
        this.result = result;

        this.bitmapReference = bitmapReference;
    }

    @Override
    protected byte[] doInBackground(Void... params) {

        Context context = wContextReference.get();

        try {

            if(context != null) {
                Bitmap bitmap = BitmapUtils.getBitmapFromResource(context, bitmapReference);

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

        //check if bitmap is available or not
        if(exception != null){
            exception.printStackTrace();
            result.error("BitmapResourceDecoder", exception.getMessage(), exception);
        }
        else {
            result.success(byteArray);
        }
    }
}