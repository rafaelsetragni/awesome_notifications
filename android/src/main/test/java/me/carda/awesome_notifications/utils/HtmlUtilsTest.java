package android.src.main.test.java.me.carda.awesome_notifications.utils;

import android.text.Html;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.regex.MatchResult;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.Assert.*;

public class HtmlUtilsTest {

    String htmlTest;
    String htmlDesiredTest;
    @Before
    public void setUp() throws Exception {
        htmlTest = "<font color='4294198070'>Red Notification</font>";
        htmlDesiredTest = "<font color='-769226'>Red Notification</font>";
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void fromHtml() {
        assertEquals(htmlDesiredTest, HtmlUtils.adaptFlutterColorsToJava(htmlTest));
    }
}