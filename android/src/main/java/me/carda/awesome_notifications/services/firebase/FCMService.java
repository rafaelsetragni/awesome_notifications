/*
package me.carda.awesome_notifications.services.firebase;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import io.flutter.Log;

import com.google.common.reflect.TypeToken;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.google.gson.Gson;

import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.enumerators.NotificationSource;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.MapUtils;


class FCMParserException extends Exception {
    FCMParserException(String s){
        super(s);
    }
}

public class FCMService extends FirebaseMessagingService {

    private static final String TAG = "FCMService";
    private static Context applicationContext;

    @Override
    public void onCreate() {
        super.onCreate();
        applicationContext = getApplicationContext();
    }

    /// Called when a new token for the default Firebase project is generated.
    @Override
    public void onNewToken(String token) {
        BroadcastSender.SendBroadcastNewFcmToken(applicationContext, token);
    }

    @Override
    public void onMessageSent(String s) {
        super.onMessageSent(s);
        Log.d(TAG, "onMessageSent: upstream message");
    }

    private void printIntentExtras(Intent intent){
        Bundle bundle;
        if ((bundle = intent.getExtras()) != null) {
            for (String key : bundle.keySet()) {
                System.out.println(key + " : " + (bundle.get(key) != null ? bundle.get(key) : "NULL"));
            }
        }
    }

    @Override
    // Thank you Google, for that brilliant idea to treat notification message and notification data
    // differently on Android, depending of what app life cycle is. Because of that, all the developers
    // are doing "workarounds", using data to send push notifications, and that's not what you planned for.
    // Let the developers decide what to do on their apps and always deliver the notification
    // to "onMessageReceived" method. Its simple, is freedom and its what the creative ones need.
    public void handleIntent(Intent intent){

        //printIntentExtras(intent);

        intent.removeExtra("gcm.notification.e");
        intent.removeExtra("gcm.notification.title");
        intent.removeExtra("gcm.notification.body");
        intent.removeExtra("google.c.a.e");
        intent.removeExtra("collapse_key");

        intent.putExtra("gcm.notification.mutable_content", true);
        intent.putExtra("gcm.notification.content_available", true);

        //printIntentExtras(intent);

        super.handleIntent(intent);
    }

    ///
    ///  Called when message is received.
    ///
    ///  @param remoteMessage Object representing the message received from Firebase Cloud Messaging.
    ///
    @Override
    public void onMessageReceived(final RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);

        if (remoteMessage.getData().size() == 0) return;
        Log.d(TAG, "FCM received");

        try {
            // FCM frame is discarded, only data is processed
            Map<String, String> remoteData = remoteMessage.getData();

            Map<String, Object> parsedNotificationContent = extractNotificationData(Definitions.NOTIFICATION_MODEL_CONTENT, remoteData);
            if(MapUtils.isNullOrEmpty(parsedNotificationContent)){
                Log.d(TAG, "Invalid notification content");
                return;
            }

            Map<String, Object> parsedSchedule = extractNotificationData(Definitions.NOTIFICATION_MODEL_SCHEDULE, remoteData);
            List<Map<String, Object>> parsedActionButtons = extractNotificationDataList(Definitions.NOTIFICATION_MODEL_BUTTONS, remoteData);

            HashMap<String, Object> parsedRemoteMessage = new HashMap<>();
            parsedRemoteMessage.put(Definitions.NOTIFICATION_MODEL_CONTENT, parsedNotificationContent);

            if(!MapUtils.isNullOrEmpty(parsedSchedule))
                parsedRemoteMessage.put(Definitions.NOTIFICATION_MODEL_SCHEDULE, parsedSchedule);

            if(!ListUtils.isNullOrEmpty(parsedActionButtons))
                parsedRemoteMessage.put(Definitions.NOTIFICATION_MODEL_BUTTONS, parsedActionButtons);

            NotificationModel notificationModel = new NotificationModel().fromMap(parsedRemoteMessage);
            //notificationModel.validate(applicationContext);

            NotificationSender.send(
                applicationContext,
                NotificationSource.Firebase,
                notificationModel
            );

        } catch (Exception e) {
            Log.d(TAG, "Invalid push notification content");
            e.printStackTrace();
        }

    }

    private HashMap<String, Object> extractNotificationData(String reference, Map<String, String> remoteData) throws FCMParserException {
        String jsonData = remoteData.get(reference);
        HashMap<String, Object> notification = null;
        try {
            if (jsonData != null) {
                Type mapType = new TypeToken<HashMap<String, Object>>(){}.getType();
                notification = new Gson().fromJson(jsonData, mapType);
            }
        } catch (Exception e) {
            throw new FCMParserException("Invalid Firebase notification content");
        }
        return notification;
    }

    private List<Map<String, Object>> extractNotificationDataList(String reference, Map<String, String> remoteData) throws FCMParserException {
        String jsonData = remoteData.get(reference);
        List<Map<String, Object>> list = null;
        try {
            if (jsonData != null) {
                Type mapType = new TypeToken<List<Map<String, Object>>>(){}.getType();
                list = new Gson().fromJson(jsonData, mapType);
            }
        } catch (Exception e) {
            throw new FCMParserException("Invalid Firebase notification content");
        }
        return list;
    }
}
*/