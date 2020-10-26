package me.carda.awesome_notifications.services.firebase;

import android.content.Context;
import io.flutter.Log;

import com.google.common.reflect.TypeToken;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.google.gson.Gson;

import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.notifications.PushNotification;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationSource;
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

    /**
     * Called when message is received.
     *
     * @param remoteMessage Object representing the message received from Firebase Cloud Messaging.
     */
    @Override
    public void onMessageReceived(final RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);

        if (remoteMessage.getData().size() == 0) return;
        Log.d(TAG, "FCM received");

        try {
            // FCM frame is discarded, only data is processed
            Map<String, String> remoteData = remoteMessage.getData();

            Map<String, Object> parsedNotificationContent = extractNotificationData(Definitions.PUSH_NOTIFICATION_CONTENT, remoteData);
            if(MapUtils.isNullOrEmpty(parsedNotificationContent)){
                Log.d(TAG, "Invalid notification content");
                return;
            }

            Map<String, Object> parsedSchedule = extractNotificationData(Definitions.PUSH_NOTIFICATION_SCHEDULE, remoteData);
            List<Map<String, Object>> parsedActionButtons = extractNotificationDataList(Definitions.PUSH_NOTIFICATION_BUTTONS, remoteData);

            HashMap<String, Object> parsedRemoteMessage = new HashMap<>();
            parsedRemoteMessage.put(Definitions.PUSH_NOTIFICATION_CONTENT, parsedNotificationContent);

            if(!MapUtils.isNullOrEmpty(parsedSchedule))
                parsedRemoteMessage.put(Definitions.PUSH_NOTIFICATION_SCHEDULE, parsedSchedule);

            if(!ListUtils.isNullOrEmpty(parsedActionButtons))
                parsedRemoteMessage.put(Definitions.PUSH_NOTIFICATION_BUTTONS, parsedActionButtons);


            PushNotification pushNotification = PushNotification.fromMap(parsedRemoteMessage);

            NotificationSender.send(
                applicationContext,
                NotificationSource.Firebase,
                pushNotification
            );

            return;

        } catch (Exception e) {
            e.printStackTrace();
        }

        Log.d(TAG, "Invalid push notification content");
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
