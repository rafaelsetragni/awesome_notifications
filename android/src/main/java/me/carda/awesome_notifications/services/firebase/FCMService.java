package me.carda.awesome_notifications.services.firebase;

import android.content.Context;
import android.util.Log;

import com.google.common.reflect.TypeToken;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.google.gson.Gson;

import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.notifications.PushNotification;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationSource;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.utils.JsonUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.StringUtils;


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
    public void handleIntent(Intent intent){

        if(intent.hasExtra("google.message_id")){
            intent = handleFirebaseIntent(intent);
        }

        super.handleIntent(intent);
    }

    // Thank you Google, for that brilliant idea to treat notification message and notification data
    // differently on Android, depending of what app life cycle is. Because of that, all the developers
    // are doing "workarounds", using data to send push notifications, and that's not what you planned for.
    // Let the developers decide what to do on their apps and ALWAYS deliver the notification
    // to "onMessageReceived" method. Its simple, is freedom and its what the creative ones need.
    private Intent handleFirebaseIntent(Intent intent){

        //printIntentExtras(intent);

        String FCM_TITLE_KEY = "gcm.notification.title";
        String FCM_BODY_KEY = "gcm.notification.body";
        String FCM_IMAGE_KEY = "gcm.notification.image";

        String title = intent.getStringExtra(FCM_TITLE_KEY);
        String body = intent.getStringExtra(FCM_BODY_KEY);
        String image = intent.getStringExtra(FCM_IMAGE_KEY);

        // Remove the key extras that identifies an Notification type message
        Bundle bundle = intent.getExtras();
        if (bundle != null) {
            for (String key : bundle.keySet()) {
                if (key.startsWith("gcm.notification.") || key.startsWith("gcm.n."))
                {
                    intent.removeExtra(key);
                }
            }
        }

        Boolean isTitleEmpty = StringUtils.isNullOrEmpty(title);
        Boolean isBodyEmpty = StringUtils.isNullOrEmpty(body);
        Boolean isImageEmpty = StringUtils.isNullOrEmpty(image);

        // Notification title and body has prevalence over Data title and body
        if(
            !isTitleEmpty || !isBodyEmpty || !isImageEmpty
        ){
            String contentData = intent.getStringExtra(Definitions.PUSH_NOTIFICATION_CONTENT);

            Map<String, Object> content;
            if(StringUtils.isNullOrEmpty(contentData)){

                content = new HashMap<String, Object>();

                content.put(Definitions.NOTIFICATION_ID, new Random().nextInt(65536) - 32768);
                content.put(Definitions.NOTIFICATION_CHANNEL_KEY, "basic_channel" );

            } else {
                content = JsonUtils.fromJson(new TypeToken<Map<String, Object>>(){}.getType(),contentData);
            }

            if(!isTitleEmpty) content.put(Definitions.NOTIFICATION_TITLE, title);
            if(!isBodyEmpty) content.put(Definitions.NOTIFICATION_BODY, body);
            if(!isImageEmpty){
                content.put(Definitions.NOTIFICATION_BIG_PICTURE, image);
                content.put(Definitions.NOTIFICATION_LAYOUT, NotificationLayout.BigPicture.toString());
            }

            contentData = JsonUtils.toJson(content);
            intent.putExtra(Definitions.PUSH_NOTIFICATION_CONTENT, contentData);
        }

        //printIntentExtras(intent);

        return intent;
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
