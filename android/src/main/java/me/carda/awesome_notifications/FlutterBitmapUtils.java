package me.carda.awesome_notifications;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;

import java.io.InputStream;

import io.flutter.view.FlutterMain;
import me.carda.awesome_notifications.core.utils.BitmapUtils;

public class FlutterBitmapUtils extends BitmapUtils {

    // ************** SINGLETON PATTERN ***********************

    FlutterBitmapUtils(){
        super();
    }

    public static void extendCapabilities() {
        if (instance == null || instance.getClass() != FlutterBitmapUtils.class)
            instance = new FlutterBitmapUtils();
    }

    // ********************************************************

    @Override
    public Bitmap getBitmapFromAsset(Context context, String bitmapPath) {
        bitmapPath = this.cleanMediaPath(bitmapPath);

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
}
