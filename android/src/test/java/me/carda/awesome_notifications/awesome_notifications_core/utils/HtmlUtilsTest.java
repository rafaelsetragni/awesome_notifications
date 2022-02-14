package me.carda.awesome_notifications.awesome_notifications_core.utils;

import android.text.Html;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.regex.MatchResult;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.Assert.*;

public class HtmlUtilsTest {

    @Test
    public void testFromHtml() {
        assertNull("if a null value is passed, so it must return null as well",
                HtmlUtils.fromHtml(null));

        assertNull("if a empty value is passed, so it must return null as well",
                HtmlUtils.fromHtml(""));

        // TODO Android Html is not returning results on test mode
        /*assertEquals(
                "Color values must be converted to Android html pattern (Positive Integers)",
                "<font color='4294198070'>Red Notification</font>",
                HtmlUtils.fromHtml("<font color='-769226'>Red Notification</font>"));*/
    }

    @Test
    public void testAdaptFlutterColorsToJava(){
        assertNull("if a null value is passed, so it must return null as well",
                HtmlUtils.adaptFlutterColorsToJava(null));

        assertEquals("if text is empty, so the text must be preserved",
                "", HtmlUtils.adaptFlutterColorsToJava(""));

        assertEquals("If text does not contain colors, it must be preserved",
                "test", HtmlUtils.adaptFlutterColorsToJava("test"));

        assertEquals("",
                "<font color='0'>test</font>",
                HtmlUtils.adaptFlutterColorsToJava("<font color='#000000'>test</font>"));

        assertEquals("",
                "<font color='0'>test</font>",
                HtmlUtils.adaptFlutterColorsToJava("<font color='0x000000'>test</font>"));

        assertEquals(
                "Color values must be converted to Android html pattern (Positive Integers)",
                "<font color='-769226'>Red Notification</font>",
                HtmlUtils.adaptFlutterColorsToJava("<font color='4294198070'>Red Notification</font>"));
    }
}