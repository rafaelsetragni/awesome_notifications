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

    private static String getLastLine(){
        StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
        if(stackTrace.length < 5)
            return "?";
        return String.valueOf(stackTrace[4].getLineNumber());
    }

    public static void d(String className, String message){
        Log.d("Android: [Awesome Notifications - DEBUG]", message + " (" + className + ":" + getLastLine() + ")");
    }

    public static void e(String className, String message){
        Log.e("\u001B[31mAndroid: [Awesome Notifications - ERROR]", message + " (" + className + ":" + getLastLine() + ")\u001B[0m");
    }

    public static void i(String className, String message){
        Log.i("\u001B[34mAndroid: [Awesome Notifications - INFO]",  message +  " (" + className + ")\u001B[0m");
    }

    public static void w(String className, String message){
        Log.w("\u001B[33mAndroid: [Awesome Notifications - WARNING]",  message +  " (" + className + ":" + getLastLine() + ")\u001B[0m");
    }

}
