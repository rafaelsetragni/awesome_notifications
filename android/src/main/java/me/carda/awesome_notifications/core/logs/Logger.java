package me.carda.awesome_notifications.core.logs;

import android.util.Log;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class Logger {

    private static final String redColor = "\u001B[31m";
    private static final String greenColor = "\u001B[32m";
    private static final String blueColor = "\u001B[34m";
    private static final String yellowColor = "\u001B[33m";
    private static final String resetColor = "\u001B[0m";

    private static final DateFormat dateFormat =
            new SimpleDateFormat("yyyy/MM/dd HH:mm:ss (z)", Locale.US);

    private static String getCurrentTime(){
        return dateFormat.format(new Date());
    }

    private static String getLastLine(){
        StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
        if(stackTrace.length < 5)
            return "?";
        return String.valueOf(stackTrace[4].getLineNumber());
    }

    public static void d(String className, String message){
        Log.d(greenColor+"[Awesome Notifications]", "Android: " + message + " (" + className + ":" + getLastLine() + ")" + resetColor);
    }

    public static void e(String className, String message){
        Log.e(redColor+"[Awesome Notifications]", "Android: " + message + " (" + className + ":" + getLastLine() + ")" + resetColor);
    }

    public static void i(String className, String message){
        Log.i(blueColor+"[Awesome Notifications]",  "Android: " + message +  " (" + className + ":" + getLastLine() + ")" + resetColor);
    }

    public static void w(String className, String message){
        Log.w(yellowColor+"[Awesome Notifications]", "Android: " + message + " (" + className + ":" + getLastLine() + ")" + resetColor);
    }

}
