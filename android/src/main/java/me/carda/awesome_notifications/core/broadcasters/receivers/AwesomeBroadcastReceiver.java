package me.carda.awesome_notifications.core.broadcasters.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.models.AbstractModel;
import me.carda.awesome_notifications.core.utils.StringUtils;

public abstract class AwesomeBroadcastReceiver extends BroadcastReceiver {

    private static final String TAG = "AwesomeBroadcastReceiver";

    public abstract void onReceiveBroadcastEvent(Context context, Intent intent) throws Exception;

    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            if (AbstractModel.defaultValues.isEmpty())
                AbstractModel
                    .defaultValues
                    .putAll(Definitions.initialValues);

            AwesomeNotifications.loadExtensions(
                    context,
                    StringUtils.getInstance());

            onReceiveBroadcastEvent(context, intent);
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        } catch (Exception e) {
            ExceptionFactory
                .getInstance()
                .registerNewAwesomeException(
                        TAG,
                        ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                        ExceptionCode.DETAILED_UNEXPECTED_ERROR+"."+e.getClass().getSimpleName(),
                        e);
        }
    }
}
