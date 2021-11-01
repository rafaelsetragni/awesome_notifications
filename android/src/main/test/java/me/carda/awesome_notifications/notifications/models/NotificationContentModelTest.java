package android.src.main.test.java.me.carda.awesome_notifications.notifications.models;

import com.google.common.reflect.TypeToken;

import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

import me.carda.push_notifications.Definitions;
import me.carda.push_notifications.notifications.NotificationModel;
import me.carda.push_notifications.utils.JsonUtils;

import static org.junit.Assert.*;

public class NotificationContentModelTest {

    @Test
    public void fromJson() {
        assertNull(JsonUtils.fromJson(new TypeToken<NotificationModel>(){}.getType(),null));
        assertNull(JsonUtils.fromJson(new TypeToken<NotificationModel>(){}.getType(),""));
    }

    @Test
    public void toJson() {
        HashMap<String, Object> standardMap = (HashMap<String, Object>) Definitions.initialValues;
        Map<String, Object> notificationMap = (HashMap<String, Object>) standardMap.clone();

        // Variables always returned
        notificationMap.put(Definitions.NOTIFICATION_TITLE, "title");
        notificationMap.put(Definitions.NOTIFICATION_BODY, "body");
        notificationMap.put(Definitions.NOTIFICATION_SUMMARY, "summary");
        notificationMap.put(Definitions.NOTIFICATION_ICON_RESOURCE_ID, null);

        NotificationContentModel contentModel = NotificationContentModel.fromMap(notificationMap);
        assertEquals(notificationMap, contentModel.toMap());
    }

    @Test
    public void fromMap() {
        NotificationContentModel contentModel;

        contentModel = NotificationContentModel.fromMap(null);
        assertNotNull(contentModel);
        assertNull(contentModel.title);
        assertNull(contentModel.body);

        contentModel = NotificationContentModel.fromMap(new HashMap<String, Object>() {{
            put("title", null);
        }});
        assertNull(contentModel.title);

        contentModel = NotificationContentModel.fromMap(new HashMap<String, Object>() {{
            put("title", "");
        }});
        assertNull(contentModel.title);

        contentModel = NotificationContentModel.fromMap(new HashMap<String, Object>() {{
            put("title", "title");
            put("body", "body");
        }});

        assertEquals("title", contentModel.title);
        assertEquals("body", contentModel.body);
    }
}