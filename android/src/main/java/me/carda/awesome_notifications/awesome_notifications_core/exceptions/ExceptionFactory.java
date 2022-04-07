package me.carda.awesome_notifications.awesome_notifications_core.exceptions;

import androidx.annotation.NonNull;

import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers.AwesomeExceptionReceiver;

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
            @NonNull String message
    ) {
        return createNewAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message));
    }

    public AwesomeNotificationsException createNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String message,
            @NonNull Exception originalException
    ) {
        return createNewAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message,
                        originalException));
    }

    public AwesomeNotificationsException createNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull Exception e
    ) {
        return createNewAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        String.format("%s", e.getLocalizedMessage()),
                        e));
    }

    public void registerNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String message
    ) {
        registerAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message));
    }

    public void registerNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull String message,
            @NonNull Exception originalException
    ) {
        registerAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        message,
                        originalException));
    }

    public void registerNewAwesomeException(
            @NonNull String className,
            @NonNull String code,
            @NonNull Exception e
    ) {
        registerAwesomeException(
                className,
                new AwesomeNotificationsException(
                        code,
                        String.format("%s", e.getLocalizedMessage()),
                        e));
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
