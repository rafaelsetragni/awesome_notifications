package me.carda.awesome_notifications.utils;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.net.URL;
import java.net.URLConnection;
import java.util.regex.Pattern;

import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.view.FlutterMain;
import me.carda.awesome_notifications.R;

import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_ASSET;
import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_FILE;
import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_NETWORK;
import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_RESOURCE;

public class BitmapUtils extends MediaUtils {

    public static Bitmap getBitmapFromSource(Context context, String bitmapPath) {

        switch (MediaUtils.getMediaSourceType(bitmapPath)){

            case Resource:
                return getBitmapFromResource(context, bitmapPath);

            case File:
                return getBitmapFromFile(bitmapPath);

            case Asset:
                return getBitmapFromAsset(context, bitmapPath);

            case Network:
                return getBitmapFromUrl(BitmapUtils.cleanMediaPath(bitmapPath));

            case Unknown:
                return null;
        }
        return null;
    }

    public static String cleanMediaPath(String mediaPath) {
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

    public static int getResId(String variableName, Class<?> c) {

        try {
            Field idField = c.getDeclaredField(variableName);
            return idField.getInt(idField);
        } catch (Exception e) {
            e.printStackTrace();
            return -1;
        }
    }

    public static int getDrawableResourceId(Context context, String bitmapReference){
        bitmapReference = BitmapUtils.cleanMediaPath(bitmapReference);
        String[] reference = bitmapReference.split("\\/");
        try {
            int resId;

            String type = reference[0];
            String label = reference[1];

            // Resources protected from obfuscation
            // https://developer.android.com/studio/build/shrink-code#strict-reference-checks
            String name = String.format("res_%1s", label);
            resId = context.getResources().getIdentifier(name, type, context.getPackageName());

            if(resId == 0){
                resId = context.getResources().getIdentifier(label, type, context.getPackageName());
            }

            return resId;

        } catch (Exception e) {
            e.printStackTrace();
        }

        return 0;
    }

    public static Bitmap getBitmapFromResource(Context context, String bitmapReference){
        int resourceId = getDrawableResourceId(context, bitmapReference);
        if(resourceId <= 0) return null;
        return BitmapFactory.decodeResource(context.getResources(), resourceId);
    }

    public static Bitmap getBitmapFromAsset(Context context, String bitmapPath) {
        bitmapPath = BitmapUtils.cleanMediaPath(bitmapPath);

        if(bitmapPath == null) return null;

        //String appDir = context.getApplicationInfo().dataDir;
        //String filePathName = appDir +"/app_flutter/"+ bitmapPath;

        Bitmap bitmap = null;
        InputStream inputStream = null;
        try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                inputStream = context.getAssets().open("flutter_assets/" + bitmapPath);
            } else {
                String assetLookupKey = FlutterMain.getLookupKeyForAsset(bitmapPath);
                AssetManager assetManager = context.getAssets();
                AssetFileDescriptor assetFileDescriptor = assetManager.openFd(assetLookupKey);
                inputStream = assetFileDescriptor.createInputStream();
            }

            bitmap = BitmapFactory.decodeStream(inputStream);
            return bitmap;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private static Bitmap getBitmapFromFile(String bitmapPath){
        bitmapPath = BitmapUtils.cleanMediaPath(bitmapPath);
        Bitmap bitmap = null;

        try {
            File imageFile = new File(bitmapPath);
            bitmap = BitmapFactory.decodeFile(imageFile.getAbsolutePath());
        } catch (Exception e) {
            e.printStackTrace();
        }

        return bitmap;
    }

    private static Bitmap getBitmapFromUrl(String bitmapUri) {
        bitmapUri = BitmapUtils.cleanMediaPath(bitmapUri);
        Bitmap bitmap = null;
        InputStream inputStream = null;
        BufferedInputStream bufferedInputStream = null;

        try {
            URLConnection conn = new URL(bitmapUri).openConnection();
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

    public static Boolean isValidBitmap(Context context, String mediaPath) {

        if (mediaPath != null) {

            if (MediaUtils.matchMediaType(MEDIA_VALID_NETWORK, mediaPath, false)) {
                return true;
            }

            if (MediaUtils.matchMediaType(MEDIA_VALID_FILE, mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true;
            }

            if (MediaUtils.matchMediaType(MEDIA_VALID_RESOURCE, mediaPath)) {
                return isValidDrawableResource(context, mediaPath);
            }

            if (MediaUtils.matchMediaType(MEDIA_VALID_ASSET, mediaPath)) {
                return true;
            }

        }
        return false;
    }

    private static Boolean isValidDrawableResource(Context context, String name) {
        if(name != null){
            int resourceId = getDrawableResourceId(context, name);
            return resourceId > 0;
        }
        return false;
    }
}
