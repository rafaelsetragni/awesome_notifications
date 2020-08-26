package android.src.main.test.java.me.carda.awesome_notifications.utils;

import com.google.common.reflect.TypeToken;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;

import me.carda.push_notifications.notifications.models.NotificationChannelModel;

import static org.junit.Assert.*;

public class JsonUtilsTest {

    HashMap channelData;
    NotificationChannelModel testModel;

    @Before
    public void setUp() throws Exception {
        channelData = new HashMap<String, Object>(){{
            put("channelDescription","Notification channel for basic tests");
            put("channelKey","basic_channel");
            put("channelName","Basic notifications");
            put("channelShowBadge",false);
            put("color",-16777216);
            put("enableLights",true);
            put("enableVibration",true);
            put("importance",3);
            put("ledColor",-1);
            put("ledOffMs",700);
            put("ledOnMs",300);
            put("locked",false);
            put("onlyAlertOnce",false);
            put("playSound",true);
        }};
        testModel = NotificationChannelModel.fromMap(channelData);
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void fromJsonList() {
        List<NotificationChannelModel> channels1 = new ArrayList<NotificationChannelModel>();
        channels1.add(testModel);

        List<NotificationChannelModel> channels2 = JsonUtils.fromJsonList(
            new TypeToken<ArrayList<NotificationChannelModel>>(){}.getType(),
             "[{'channelDescription':'Notification channel for basic tests','channelKey':'basic_channel','channelName':'Basic notifications','channelShowBadge':false,'color':-16777216,'enableLights':true,'enableVibration':true,'importance':3,'ledColor':-1,'ledOffMs':700,'ledOnMs':300,'locked':false,'onlyAlertOnce':false,'playSound':true}]"
        );

        assertEquals(channels1, channels2);
    }

    @Test
    public void fromJson() {
    }

    @Test
    public void toJson() {
    }

    @Test
    public void testToJson() {
    }
}