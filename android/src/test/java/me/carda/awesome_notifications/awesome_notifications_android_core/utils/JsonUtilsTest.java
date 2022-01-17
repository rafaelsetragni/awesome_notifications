package me.carda.awesome_notifications.awesome_notifications_android_core.utils;

import com.google.gson.reflect.TypeToken;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationChannelModel;

import static org.junit.Assert.*;

public class JsonUtilsTest {

    String channelJsonData;
    Map<String, Object> channelData;
    NotificationChannelModel testModel;

    @Before
    public void setUp() {

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

        List<Map.Entry<String, Integer>> entries = new ArrayList<Map.Entry<String, Integer>>();
        Collections.sort(entries, new Comparator<Map.Entry<String, Integer>>() {
            public int compare(Map.Entry<String, Integer> a,
                               Map.Entry<String, Integer> b) {
                return a.getValue().compareTo(b.getValue());
            }
        });

        Comparator<Map.Entry<String, Object>> valueComparator =
                Map.Entry.comparingByKey();

        channelData = channelData.entrySet().stream().
                        sorted(valueComparator).
                        collect( Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue,
                                (e1, e2) -> e1, LinkedHashMap::new));

        testModel = new NotificationChannelModel().fromMap(channelData);

        channelJsonData =
                "{'channelDescription':'Notification channel for basic tests','channelKey':'basic_channel'," +
                "'channelName':'Basic notifications','channelShowBadge':false,'color':-16777216,'enableLights':true," +
                "'enableVibration':true,'importance':3,'ledColor':-1,'ledOffMs':700,'ledOnMs':300,'locked':false," +
                "'onlyAlertOnce':false,'playSound':true}";
    }

    @After
    public void tearDown() {
    }

    @Test
    public void fromJson() {
        Map<String, Object> channels2 = JsonUtils.fromJson(channelJsonData);
        assertTrue("Maps with equal keys and respective values must be considered equals", CompareUtils.assertEqualObjects(channelData, channels2));

        Map<String, Object> test1 = new HashMap<>(channels2);
        test1.put("color", 1);
        assertFalse("Maps with different keys or values must be considered different", CompareUtils.assertEqualObjects(channelData, test1));

        Map<String, Object> test2 = new HashMap<>(channels2);
        test2.remove("color");
        assertFalse("Maps with different keys or values must be considered different", CompareUtils.assertEqualObjects(channelData, test2));
    }

    @Test
    public void testChainOfResponsibilityToJson() {
        assertEquals("", "null", JsonUtils.chainOfResponsibilityToJson(null));

        assertEquals("", "{}", JsonUtils.chainOfResponsibilityToJson(new HashMap<>()));
        assertEquals("", "{\"key1\":null}", JsonUtils.chainOfResponsibilityToJson(new HashMap<String, Object>(){{put("key1", null);}}));
        assertEquals("", "{\"key1\":1}", JsonUtils.chainOfResponsibilityToJson(new HashMap<String, Object>(){{put("key1", 1);}}));
        assertEquals("", "{\"key1\":[1,2,3]}", JsonUtils.chainOfResponsibilityToJson(new HashMap<String, Object>(){{put("key1", Arrays.asList(1,2,3));}}));


        Map<String, Object> cascadeMap = new HashMap<String, Object>(){{
            put("key1", new HashMap<String, Object>(){{
                put("key1", null);
            }});
            put("key2", 1);
            put("key3", 1.0f);
            put("key4", 1.0);
            put("key5", "");
            put("key6", "test\"\\test");
            put("key7", new HashMap<String, Object>(){{
                put("key8", "");
            }});
            put("key9", Arrays.asList(
                    "test",
                    new HashMap<String, Object>(){{
                        put("key8", "");
                    }})
            );
        }};

        assertEquals("Json chain responsibility to transform json fails on convert cascade maps",
                "{\"key1\":{\"key1\":null},\"key2\":1,\"key3\":1.0,\"key4\":1.0," +
                "\"key5\":\"\",\"key6\":\"test\\\"\\\\test\",\"key7\":{\"key8\":\"\"},\"key9\":[\"test\",{\"key8\":\"\"}]}",
                JsonUtils.chainOfResponsibilityToJson(cascadeMap));
    }

    @Test
    public void testChainOfResponsibilityMapToJson() {
        assertEquals("", "null", JsonUtils.chainOfResponsibilityMapToJson(null));

        assertEquals("", "{}", JsonUtils.chainOfResponsibilityMapToJson(new HashMap<>()));
        assertEquals("", "{\"key1\":null}", JsonUtils.chainOfResponsibilityMapToJson(new HashMap<String, Object>(){{put("key1", null);}}));
        assertEquals("", "{\"key1\":1}", JsonUtils.chainOfResponsibilityMapToJson(new HashMap<String, Object>(){{put("key1", 1);}}));
        assertEquals("", "{\"key1\":[1,2,3]}", JsonUtils.chainOfResponsibilityMapToJson(new HashMap<String, Object>(){{put("key1", Arrays.asList(1,2,3));}}));
        assertEquals("", "{\"key1\":{\"key1\":null}}", JsonUtils.chainOfResponsibilityMapToJson(new HashMap<String, Object>(){{put("key1", new HashMap<String, Object>(){{put("key1", null);}});}}));
    }

    @Test
    public void testChainOfResponsibilityListToJson() {
        assertEquals("", "null", JsonUtils.chainOfResponsibilityListToJson(null));

        assertEquals("", "[]", JsonUtils.chainOfResponsibilityListToJson(new ArrayList<>()));
        assertEquals("", "[1]", JsonUtils.chainOfResponsibilityListToJson(Arrays.asList(1)));
        assertEquals("", "[1,2]", JsonUtils.chainOfResponsibilityListToJson(Arrays.asList(1,2)));
        assertEquals("", "[1,2,3]", JsonUtils.chainOfResponsibilityListToJson(Arrays.asList(1,2,3)));
        assertEquals("", "[1,2,[1,2,3]]", JsonUtils.chainOfResponsibilityListToJson(Arrays.asList(1,2,Arrays.asList(1,2,3))));
    }

    @Test
    public void testChainOfResponsibilityGenericsToJson(){
        assertEquals("", "null", JsonUtils.chainOfResponsibilityGenericsToJson(null));
        assertEquals("", "null", JsonUtils.chainOfResponsibilityGenericsToJson(this));

        assertEquals("", "0", JsonUtils.chainOfResponsibilityGenericsToJson(0));
        assertEquals("", "0.0", JsonUtils.chainOfResponsibilityGenericsToJson(0.0f));
        assertEquals("", "0.0", JsonUtils.chainOfResponsibilityGenericsToJson(0.0));
        assertEquals("", "true", JsonUtils.chainOfResponsibilityGenericsToJson(true));
        assertEquals("", "1", JsonUtils.chainOfResponsibilityGenericsToJson((byte) 1));


        assertEquals("", "\"\"", JsonUtils.chainOfResponsibilityGenericsToJson(""));
        assertEquals("", "\"test\"", JsonUtils.chainOfResponsibilityGenericsToJson("test"));
        assertEquals("", "\"test\\\"\\\\\"", JsonUtils.chainOfResponsibilityGenericsToJson("test\"\\"));
    }

    @Test
    public void testJoinList() {
        assertEquals("", "", JsonUtils.joinList(null));
        assertEquals("", "", JsonUtils.joinList(new ArrayList<>()));
        assertEquals("", "1", JsonUtils.joinList(Arrays.asList("1")));
        assertEquals("", "1,2", JsonUtils.joinList(Arrays.asList("1","2")));
        assertEquals("", "1,2,3", JsonUtils.joinList(Arrays.asList("1","2","3")));
    }
}