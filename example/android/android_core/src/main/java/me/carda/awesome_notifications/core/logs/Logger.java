package me.carda.awesome_notifications.core.logs;

import android.util.Log;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class Logger {

    private static final String redColor = "\u001B[31m";
    private static final String greenColor = "\u001B[32m";
    private static final String blueColor = "\u001B[94m";
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
        Log.d("Android: "+greenColor+"[Awesome Notifications]"+resetColor,  message + " (" + className + ":" + getLastLine() + ")");
    }

    public static void e(String className, String message){
        Log.e("Android: "+redColor+"[Awesome Notifications]", message + " (" + className + ":" + getLastLine() + ")" + resetColor);
    }

    public static void i(String className, String message){
        Log.i("Android: "+blueColor+"[Awesome Notifications]",  message +  " (" + className + ":" + getLastLine() + ")" + resetColor);
    }

    public static void w(String className, String message){
        Log.w("Android: "+yellowColor+"[Awesome Notifications]", message + " (" + className + ":" + getLastLine() + ")" + resetColor);
    }

}
