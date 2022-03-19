package me.carda.awesome_notifications.awesome_notifications_core.logs;

import android.util.Log;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class Logger {

    private static final DateFormat dateFormat =
            new SimpleDateFormat("yyyy/MM/dd HH:mm:ss (z)", Locale.US);

    private static String getCurrentTime(){
        return dateFormat.format(new Date());
    }

    public static void d(String className, String message){
        Log.d(className, getCurrentTime() + " - " + message);
    }

    public static void e(String className, String message){
        Log.e(className, getCurrentTime() + " - " + message);
    }

    public static void i(String className, String message){
        Log.i(className, getCurrentTime() + " - " + message);
    }

    public static void w(String className, String message){
        Log.w(className, getCurrentTime() + " - " + message);
    }

}
