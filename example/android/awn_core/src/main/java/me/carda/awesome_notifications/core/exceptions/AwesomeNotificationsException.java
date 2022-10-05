package me.carda.awesome_notifications.core.exceptions;

import androidx.annotation.NonNull;

public class AwesomeNotificationsException extends Exception {

    final String code;
    final String detailedCode;

    AwesomeNotificationsException(
            @NonNull String code,
            @NonNull String message,
            @NonNull String detailedCode
    ){
        super(message);
        this.code = code;
        this.detailedCode = detailedCode;
    }

    AwesomeNotificationsException(
            @NonNull String code,
            @NonNull String message,
            @NonNull String detailedCode,
            @NonNull StackTraceElement[] stackTraceElement
    ){
        super(message);
        this.code = code;
        this.detailedCode = detailedCode;
        this.setStackTrace(stackTraceElement);
    }

    AwesomeNotificationsException(
            @NonNull String code,
            @NonNull String message,
            @NonNull String detailedCode,
            @NonNull Exception originalException
    ){
        super(message);
        this.code = code;
        this.detailedCode = detailedCode;
        this.setStackTrace(originalException.getStackTrace());
    }

    @NonNull
    public final String getCode(){
        return code;
    }

    @NonNull
    public String getDetailedCode() {
        return this.detailedCode;
    }
}