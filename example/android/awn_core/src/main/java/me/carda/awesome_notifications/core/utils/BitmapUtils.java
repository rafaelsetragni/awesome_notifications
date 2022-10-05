package me.carda.awesome_notifications.core.utils;

import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_ASSET;
import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_FILE;
import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_NETWORK;
import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_RESOURCE;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;

import androidx.annotation.NonNull;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.regex.Pattern;

import javax.annotation.Nullable;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public class BitmapUtils extends MediaUtils {

    public static final String TAG = "BitmapUtils";

    // ************** SINGLETON PATTERN ***********************

    protected static BitmapUtils instance;

    protected BitmapUtils(){
        stringUtils = StringUtils.getInstance();
    }

    public static BitmapUtils getInstance() {
        if (instance == null)
            instance = new BitmapUtils();
        return instance;
    }

    // ********************************************************

    public Bitmap getBitmapFromSource(Context context, String bitmapPath, boolean roundedBitmap) {

        Bitmap returnedBitmap = null;
        switch (getMediaSourceType(bitmapPath)){

            case Resource:
                returnedBitmap = getBitmapFromResource(context, bitmapPath);
                break;

            case File:
                returnedBitmap = getBitmapFromFile(bitmapPath);
                break;

            case Asset:
                returnedBitmap = getBitmapFromAsset(context, bitmapPath);
                break;

            case Network:
                returnedBitmap = getBitmapFromUrl(this.cleanMediaPath(bitmapPath));

            case Unknown:
                break;
        }

        if(returnedBitmap != null && roundedBitmap){
            returnedBitmap = roundBitmap(returnedBitmap);
        }

        return returnedBitmap;
    }

    public String cleanMediaPath(String mediaPath) {
        if (mediaPath != null) {
            Pattern pattern = Pattern.compile("^https?:\\/\\/", Pattern.CASE_INSENSITIVE);
            Pattern pattern2 = Pattern.compile("^(asset:\\/\\/)(.*)", Pattern.CASE_INSENSITIVE);
            Pattern pattern3 = Pattern.compile("^(file:\\/\\/)(.*)", Pattern.CASE_INSENSITIVE);
            Pattern pattern4 = Pattern.compile("^(resource:\\/\\/)(.*)", Pattern.CASE_INSENSITIVE);

            if(pattern.matcher(mediaPath).find()){
                return mediaPath;
            }

            if(pattern2.matcher(mediaPath).find()){
                return pattern2.matcher(mediaPath).replaceAll("$2");
            }

            if(pattern3.matcher(mediaPath).find()){
                return pattern3.matcher(mediaPath).replaceAll("/$2");
            }

            if(pattern4.matcher(mediaPath).find()){
                return pattern4.matcher(mediaPath).replaceAll("$2");
            }
        }
        return null;
    }

    public int getDrawableResourceId(Context context, String bitmapReference){
        bitmapReference = this.cleanMediaPath(bitmapReference);
        String[] reference = bitmapReference.split("\\/");

        try {
            int resId;

            String type = reference[0];
            String label = reference[1];

            // Resources protected from obfuscation
            // https://developer.android.com/studio/build/shrink-code#strict-reference-checks
            String name = String.format("res_%1s", label);
            resId = context.getResources().getIdentifier(name, type, AwesomeNotifications.getPackageName(context));

            if(resId == 0){
                resId = context.getResources().getIdentifier(label, type, AwesomeNotifications.getPackageName(context));
            }

            return resId;

        } catch (Exception ignore) {
        }

        return 0;
    }

    public Bitmap getBitmapFromResource(Context context, String bitmapReference){
        int resourceId = getDrawableResourceId(context, bitmapReference);
        if(resourceId <= 0) return null;
        return BitmapFactory.decodeResource(context.getResources(), resourceId);
    }

    public Bitmap getBitmapFromAsset(Context context, String bitmapPath) {
        return null;
    }

    public Bitmap roundBitmap(@NonNull Bitmap bitmap) {
        Bitmap output = Bitmap.createBitmap(bitmap.getWidth(),
                bitmap.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        final int color = 0xff424242;
        final Paint paint = new Paint();
        final Rect rect = new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight());

        paint.setAntiAlias(true);
        canvas.drawARGB(0, 0, 0, 0);
        paint.setColor(color);

        float bitmapWidth = bitmap.getWidth();
        float bitmapHeight = bitmap.getHeight();

        if(bitmapWidth <= 0 || bitmapHeight <= 0)
            return bitmap;
        else{
            bitmapWidth /= 2;
            bitmapHeight /= 2;
        }

        canvas.drawCircle(bitmapWidth, bitmapHeight, bitmapWidth, paint);
        paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN));
        canvas.drawBitmap(bitmap, rect, rect, paint);

        return output;
    }

    private Bitmap getBitmapFromFile(String bitmapPath){
        bitmapPath = this.cleanMediaPath(bitmapPath);
        Bitmap bitmap = null;

        try {
            File imageFile = new File(bitmapPath);
            bitmap = BitmapFactory.decodeFile(imageFile.getAbsolutePath());
        } catch (Exception originalException) {
            ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "The image file '"+bitmapPath+"' is invalid",
                            originalException);
        }

        return bitmap;
    }

    private Bitmap getBitmapFromUrl(String bitmapUri) {
        bitmapUri = this.cleanMediaPath(bitmapUri);
        Bitmap bitmap = null;
        InputStream inputStream = null;
        BufferedInputStream bufferedInputStream = null;

        try {
            URLConnection conn = new URL(bitmapUri).openConnection();
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            conn.connect();

            inputStream = conn.getInputStream();
            bufferedInputStream = new BufferedInputStream(inputStream, 8192);
            bitmap = BitmapFactory.decodeStream(bufferedInputStream);
        }
        catch (Exception e){
            e.printStackTrace();
        }
        finally {
            if (bufferedInputStream != null)
            {
                try
                {
                    bufferedInputStream.close();
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                }
            }
            if (inputStream != null)
            {
                try
                {
                    inputStream.close();
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                }
            }
        }

        return bitmap;
    }

    public Boolean isValidBitmap(@NonNull Context context, @Nullable String mediaPath) {

        if (!stringUtils.isNullOrEmpty(mediaPath)) {

            if (matchMediaType(MEDIA_VALID_NETWORK, mediaPath, false)) {
                return true;
            }

            if (matchMediaType(MEDIA_VALID_FILE, mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true;
            }

            if (matchMediaType(MEDIA_VALID_RESOURCE, mediaPath)) {
                return isValidDrawableResource(context, mediaPath);
            }

            return matchMediaType(MEDIA_VALID_ASSET, mediaPath);

        }
        return false;
    }

    private Boolean isValidDrawableResource(@NonNull Context context, @NonNull String name) {
        int resourceId = getDrawableResourceId(context, name);
        return resourceId > 0;
    }
}
