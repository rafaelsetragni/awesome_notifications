package me.carda.awesome_notifications.core.exceptions;

import androidx.annotation.NonNull;

import me.carda.awesome_notifications.core.broadcasters.receivers.AwesomeExceptionReceiver;

public class ExceptionFactory {

    public static String TAG = "ExceptionFactory";

    // ************** SINGLETON PATTERN ***********************

    private static ExceptionFactory instance;

    private ExceptionFactory(){}

    public static ExceptionFactory getInstance() {
        if (instance == null)
            instance = new ExceptionFactory();
        return instance;
    }

    /// **************  FACTORY METHODS  *********************

    public AwesomeNotificationsException createNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String message,
            @NonNull String detailedCode
    ) {
        return createNewAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message,
                        detailedCode));
    }

    public AwesomeNotificationsException createNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String message,
            @NonNull String detailedCode,
            @NonNull Exception originalException
    ) {
        return createNewAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message,
                        detailedCode,
                        originalException));
    }

    public AwesomeNotificationsException createNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String detailedCode,
            @NonNull Exception e
    ) {
        return createNewAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        String.format("%s", e.getLocalizedMessage()),
                        detailedCode,
                        e));
    }

    public void registerNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String message,
            @NonNull String detailedCode
    ) {
        registerAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message,
                        detailedCode));
    }

    public void registerNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String message,
            @NonNull String detailedCode,
            @NonNull Exception originalException
    ) {
        registerAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message,
                        detailedCode,
                        originalException));
    }

    public void registerNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String detailedCode,
            @NonNull Exception originalException
    ) {
        registerAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        String.format("%s", originalException.getLocalizedMessage()),
                        detailedCode,
                        originalException));
    }

    /// **************  FACTORY METHODS  *********************

    private AwesomeNotificationsException createNewAwesomeException(
            @NonNull String className,
            @NonNull AwesomeNotificationsException exception
    ) {
        AwesomeExceptionReceiver
                .getInstance()
                .notifyNewException(className, exception);
        return exception;
    }

    private void registerAwesomeException(
            @NonNull String className,
            @NonNull AwesomeNotificationsException exception
    ) {
        AwesomeExceptionReceiver
                .getInstance()
                .notifyNewException(className, exception);
    }
}
