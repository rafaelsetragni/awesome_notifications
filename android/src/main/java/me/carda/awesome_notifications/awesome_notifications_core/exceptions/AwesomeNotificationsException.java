package me.carda.awesome_notifications.awesome_notifications_core.exceptions;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class AwesomeNotificationsException extends Exception {

    final String code;

    AwesomeNotificationsException(
            @NonNull String code,
            @NonNull String message
    ){
        super(message);
        this.code = code;
    }

    AwesomeNotificationsException(
            @NonNull String code,
            @NonNull String message,
            @NonNull StackTraceElement[] stackTraceElement
    ){
        super(message);
        this.code = code;
        this.setStackTrace(stackTraceElement);
    }

    AwesomeNotificationsException(
            @NonNull String code,
            @NonNull String message,
            @NonNull Exception originalException
    ){
        super(message);
        this.code = code;
    }

    @NonNull
    public final String getCode(){
        return code;
    }
}