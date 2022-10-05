package me.carda.awesome_notifications.core.utils;

import android.os.Looper;

public class ThreadUtils {

    // ************** SINGLETON PATTERN ***********************

    private static ThreadUtils instance;

    private ThreadUtils(){}
    public static ThreadUtils getInstance() {
        if (instance == null)
            instance = new ThreadUtils();
        return instance;
    }

    // ********************************************************

    public boolean isMainThread(){
        return Looper.myLooper() == Looper.getMainLooper();
    }
}
