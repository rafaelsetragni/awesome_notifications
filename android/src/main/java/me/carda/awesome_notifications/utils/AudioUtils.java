package me.carda.awesome_notifications.utils;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import me.carda.awesome_notifications.notifications.enumerators.MediaSource;

import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_ASSET;
import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_FILE;
import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_NETWORK;
import static me.carda.awesome_notifications.Definitions.MEDIA_VALID_RESOURCE;

public class AudioUtils extends MediaUtils {

    public static Bitmap getAudioFromSource(Context context, String bitmapPath) {

        switch (MediaUtils.getMediaSourceType(bitmapPath)){

            case Resource:
                return getAudioFromResource(context, bitmapPath);

            case File:
                /// TODO MISSING IMPLEMENTATION
                return null;

            case Asset:
                /// TODO MISSING IMPLEMENTATION
                return null;

            case Network:
                /// TODO MISSING IMPLEMENTATION
                return null;

            case Unknown:
                return null;
        }
        return null;
    }

    public static MediaSource getAudioSourceType(String mediaPath) {

        if (mediaPath != null) {

            if (matchMediaType(MEDIA_VALID_NETWORK, mediaPath, false)) {
                return MediaSource.Network;
            }

            if (matchMediaType(MEDIA_VALID_FILE, mediaPath)) {
                return MediaSource.File;
            }

            if (matchMediaType(MEDIA_VALID_RESOURCE, mediaPath)) {
                return MediaSource.Resource;
            }

            if (matchMediaType(MEDIA_VALID_ASSET, mediaPath)) {
                return MediaSource.Asset;
            }

        }
        return MediaSource.Unknown;
    }

    public static int getAudioResourceId(Context context, String audioReference){
        audioReference = AudioUtils.cleanMediaPath(audioReference);
        String[] reference = audioReference.split("\\/");

        try {
            int resId = 0;

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

    private static Bitmap getAudioFromResource(Context context, String bitmapReference){
        int resourceId = getAudioResourceId(context, bitmapReference);
        return BitmapFactory.decodeResource(context.getResources(), resourceId);
    }

    public static Boolean isValidAudio(Context context, String mediaPath) {

        if (mediaPath != null) {

            if (matchMediaType(MEDIA_VALID_RESOURCE, mediaPath)) {
                return isValidAudioResource(context, mediaPath);
            }

            if (matchMediaType(MEDIA_VALID_NETWORK, mediaPath, false)) {
                // TODO MISSING IMPLEMENTATION
                return false;
            }

            if (matchMediaType(MEDIA_VALID_FILE, mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return false;
            }

            if (matchMediaType(MEDIA_VALID_ASSET, mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return false;
            }

        }
        return false;
    }

    private static Boolean isValidAudioResource(Context context, String name) {
        if(name != null){
            int resourceId = getAudioResourceId(context, name);
            return resourceId > 0;
        }
        return false;
    }
}
