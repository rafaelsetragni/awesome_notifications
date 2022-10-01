package me.carda.awesome_notifications.core.utils;

import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_ASSET;
import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_FILE;
import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_NETWORK;
import static me.carda.awesome_notifications.core.Definitions.MEDIA_VALID_RESOURCE;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import me.carda.awesome_notifications.core.enumerators.MediaSource;

public abstract class MediaUtils {

    protected StringUtils stringUtils;

    protected Boolean matchMediaType(String regex, String mediaPath){
        return matchMediaType(regex, mediaPath, true);
    }

    protected Boolean matchMediaType(String regex, String mediaPath, Boolean filterEmpty){
        Pattern p = Pattern.compile(regex, Pattern.CASE_INSENSITIVE);
        Matcher m = p.matcher(mediaPath);
        String s = mediaPath.replaceFirst(regex, "");
        return m.find() && (!filterEmpty || !s.isEmpty());
    }

    public MediaSource getMediaSourceType(String mediaPath) {

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
}
