package me.carda.awesome_notifications.awesome_notifications_android_core.utils;

import android.icu.text.TimeZoneNames;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.Calendar;
import java.util.Date;


import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.externalLibs.CronExpression;

import static org.junit.Assert.*;

public class CronUtilsTest {

    String testValidDate;
    String testInvalidDate;
    String localTimeZone;
    String utcTimeZone;
    Date validDate;

    @Before
    public void setUp() throws Exception {

        testValidDate = "2020-08-20 13:29:05";
        testInvalidDate = "2020-20-08 13:29:06";
        localTimeZone = DateUtils.localTimeZone.toString();
        utcTimeZone = DateUtils.utcTimeZone.toString();
        validDate = DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone);
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void getDateFromString() {
        try {
            assertEquals(validDate, DateUtils.stringToDate(testValidDate, localTimeZone));
            assertNotEquals(validDate, DateUtils.stringToDate(testInvalidDate, localTimeZone));
            assertEquals(validDate, DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone));
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void applyToleranceDate() {
        String nowDate = "2020-08-20 13:28:59";

        try {
            assertNotEquals(
                    DateUtils.stringToDate("2020-08-20 13:28:59", localTimeZone),
                    CronUtils.applyToleranceDate(DateUtils.stringToDate(nowDate, localTimeZone), DateUtils.localTimeZone)
            );

            assertEquals(
                    DateUtils.stringToDate("2020-08-20 13:29:00", localTimeZone),
                    CronUtils.applyToleranceDate(DateUtils.stringToDate(nowDate, localTimeZone), DateUtils.localTimeZone)
            );

            assertNotEquals(
                    DateUtils.stringToDate("2020-08-20 13:29:01", localTimeZone),
                    CronUtils.applyToleranceDate(DateUtils.stringToDate(nowDate, localTimeZone), DateUtils.localTimeZone)
            );
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void isValidExpression(){
        assertTrue(CronExpression.isValidExpression("5 38 20 20 8 ? 2020"));
        assertTrue(CronExpression.isValidExpression("5 38 20 20 8 ? *"));
        assertTrue(CronExpression.isValidExpression("5 38 20 20 * ? *"));
        assertTrue(CronExpression.isValidExpression("5 38 20 ? 8 THU *"));
        assertTrue(CronExpression.isValidExpression("5 38 20 * * ? *"));
        assertTrue(CronExpression.isValidExpression("5 38 * * * ? *"));
        assertTrue(CronExpression.isValidExpression("5 * * * * ? *"));
        assertTrue(CronExpression.isValidExpression("5 38 20 ? * MON-FRI *"));
        assertTrue(CronExpression.isValidExpression("5 38 20 ? * SAT,SUN *"));

        assertFalse(CronExpression.isValidExpression("5 38 20 20 8 0 2020"));
        assertFalse(CronExpression.isValidExpression("5 38 20 20 8 2020"));
        assertFalse(CronExpression.isValidExpression("5 38 20 ? 8 ? 2020"));
        assertFalse(CronExpression.isValidExpression("05 38 20 ? 08 ? 2020"));
    }

    @Test
    public void getNextCalendar() {
        try {
            assertNull(CronUtils.getNextCalendar(null, null, null, DateUtils.localTimeZone));

            Date fixedNowDate = DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone);

            Calendar calendar = Calendar.getInstance();
            calendar.setTimeZone(DateUtils.utcTimeZone);

            String
                    cronRule = "5 29 13 20 8 ? 2020",
                    initialDateTime = "2020-08-20 13:29:05";

            assertNull(CronUtils.getNextCalendar(initialDateTime, null, fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate(initialDateTime, localTimeZone));
            assertNull(CronUtils.getNextCalendar(initialDateTime, cronRule, fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate(initialDateTime, localTimeZone));
            assertNull(CronUtils.getNextCalendar(initialDateTime, cronRule, fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate(initialDateTime, localTimeZone));
            assertNull(CronUtils.getNextCalendar(initialDateTime, cronRule, fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar("2020-08-20 13:29:05", cronRule, fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate("2020-08-20 13:29:06", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar("2020-08-20 13:29:06", cronRule, fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate("2020-08-20 13:30:00", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar("2020-08-20 13:30:00", cronRule, fixedNowDate, DateUtils.localTimeZone));

            assertNull(CronUtils.getNextCalendar(null, "", fixedNowDate, DateUtils.localTimeZone));
            assertNull(CronUtils.getNextCalendar(null, "", fixedNowDate, DateUtils.localTimeZone));
            assertNull(CronUtils.getNextCalendar(null, "* * * * *", fixedNowDate, DateUtils.localTimeZone));
            assertNull(CronUtils.getNextCalendar(null, "* * * * * *", fixedNowDate, DateUtils.localTimeZone));
            assertNull(CronUtils.getNextCalendar(null, "0 0 12 * * ? 2017", fixedNowDate, DateUtils.localTimeZone));

            fixedNowDate = DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone);
            calendar.setTime(DateUtils.stringToDate("2020-08-20 13:30:00", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar(null, "0 0-30 13 * * ? *", fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate("2020-08-20 13:29:06", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar(null, "0-10 * * * * ? *", fixedNowDate, DateUtils.localTimeZone));

            calendar.setTime(DateUtils.stringToDate("2021-01-01 00:00:00", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar(null, "0 * * * * ? 2021", fixedNowDate, DateUtils.localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar(null, "0 * * ? * * 2021", fixedNowDate, DateUtils.localTimeZone));

            /// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
            calendar.setTime(DateUtils.stringToDate("2020-08-20 14:45:05", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar(testValidDate, "5 45 14 20 08 ? 2020", fixedNowDate, DateUtils.localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar(null, "5 45 14 20 08 ? 2020", fixedNowDate, DateUtils.localTimeZone));

            fixedNowDate = DateUtils.stringToDate("2020-08-20 14:45:05", localTimeZone);
            assertNull(CronUtils.getNextCalendar(null, "5 45 14 20 08 ? 2020", fixedNowDate, DateUtils.localTimeZone));
            assertNull(CronUtils.getNextCalendar(testValidDate, "5 45 14 20 08 ? 2020", fixedNowDate, DateUtils.localTimeZone));

            fixedNowDate = DateUtils.stringToDate("2020-08-20 14:45:04", localTimeZone);
            calendar.setTime(DateUtils.stringToDate("2020-08-20 14:45:05", localTimeZone));
            assertEquals(calendar, CronUtils.getNextCalendar(testValidDate, "5 45 14 20 08 ? 2020", fixedNowDate, DateUtils.localTimeZone));
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
    }
}