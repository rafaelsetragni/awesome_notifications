package me.carda.awesome_notifications.awesome_notifications_core.utils;

import android.icu.text.TimeZoneNames;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.Calendar;
import java.util.Date;


import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.externalLibs.CronExpression;

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
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void applyToleranceDate() throws AwesomeNotificationsException {
        Date nowDate = DateUtils.stringToDate("2020-08-20 13:30:00", localTimeZone);
        String toleranceError = "Tolerance was not applied returning 1 second to the past";

        assertNotEquals(
                toleranceError,
                DateUtils.stringToDate("2020-08-20 13:29:58", localTimeZone),
                CronUtils.applyToleranceDate(nowDate, DateUtils.localTimeZone));

        assertEquals(
                toleranceError,
                DateUtils.stringToDate("2020-08-20 13:29:59", localTimeZone),
                CronUtils.applyToleranceDate(nowDate, DateUtils.localTimeZone));

        assertNotEquals(
                toleranceError,
                DateUtils.stringToDate("2020-08-20 13:30:00", localTimeZone),
                CronUtils.applyToleranceDate(nowDate, DateUtils.localTimeZone));
    }

    @Test
    public void isValidExpression(){

        String validExpressionErrorMessage = "A valid cron expression was erroneously identified as invalid";
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 20 8 ? 2020"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 20 8 ? *"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 20 * ? *"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 ? 8 THU *"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 * * ? *"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 * * * ? *"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 * * * * ? *"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 ? * MON-FRI *"));
        assertTrue(validExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 ? * SAT,SUN *"));

        String invalidExpressionErrorMessage = "An invalid cron expression was erroneously identified as valid";
        assertFalse(invalidExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 20 8 0 2020"));
        assertFalse(invalidExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 20 8 2020"));
        assertFalse(invalidExpressionErrorMessage, CronExpression.isValidExpression("5 38 20 ? 8 ? 2020"));
        assertFalse(invalidExpressionErrorMessage, CronExpression.isValidExpression("05 38 20 ? 08 ? 2020"));
    }

    @Test
    public void getNextCalendar() throws AwesomeNotificationsException {

        assertNull(
                "getNextCalendar without the required parameters must return null",
                CronUtils.getNextCalendar(
                        null,
                        null,
                        null,
                        DateUtils.localTimeZone));

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(DateUtils.utcTimeZone);

        String cronRule = "5 29 13 20 8 ? 2020",
               initialDateTime = "2020-08-20 13:29:05";

        assertNull(
                "getNextCalendar without cron rule must return null",
                CronUtils.getNextCalendar(
                initialDateTime,
                null,
                DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone),
                DateUtils.localTimeZone));

        calendar.setTime(DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone));
        assertEquals(
                "getNextCalendar must return valid values if initial date wasn't defined",
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        null,
                        cronRule,
                        DateUtils.stringToDate("2020-08-20 13:29:04", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        assertEquals(
                "getNextCalendar failed to return valid date on lower border",
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        "2020-08-20 13:29:04",
                        cronRule,
                        DateUtils.stringToDate("2020-08-20 13:29:04", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        assertEquals(
                "getNextCalendar failed to return valid date on initial date lower border",
                calendar.getTime(),
                CronUtils.getNextCalendar(
                "2020-08-20 13:29:05",
                        cronRule,
                        DateUtils.stringToDate("2020-08-20 13:29:04", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        assertEquals(
                "getNextCalendar failed to return valid date on middle border",
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        "2020-08-20 13:29:05",
                        cronRule,
                        DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        assertNull(
                "getNextCalendar failed to return invalid date on initial date upper border",
                CronUtils.getNextCalendar(
                        "2020-08-20 13:29:06",
                        cronRule,
                        DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone),
                        DateUtils.localTimeZone));

        assertNull(
                "getNextCalendar failed to return invalid date on upper border",
                CronUtils.getNextCalendar(
                        "2020-08-20 13:29:05",
                        cronRule,
                        DateUtils.stringToDate("2020-08-20 13:29:06", localTimeZone),
                        DateUtils.localTimeZone));

        Date fixedNowDate = DateUtils.stringToDate("2020-08-20 13:29:05", localTimeZone);

        String invalidCronRuleMessage = "Invalid cron rules must return a valid calendar";
        assertNull(invalidCronRuleMessage, CronUtils.getNextCalendar(null, "", fixedNowDate, DateUtils.localTimeZone));
        assertNull(invalidCronRuleMessage, CronUtils.getNextCalendar(null, null, fixedNowDate, DateUtils.localTimeZone));
        assertNull(invalidCronRuleMessage, CronUtils.getNextCalendar(null, "* * * * *", fixedNowDate, DateUtils.localTimeZone));
        assertNull(invalidCronRuleMessage, CronUtils.getNextCalendar(null, "* * * * * *", fixedNowDate, DateUtils.localTimeZone));
        assertNull(invalidCronRuleMessage, CronUtils.getNextCalendar(null, "0 0 12 * * ? 2017", fixedNowDate, DateUtils.localTimeZone));

        String cronRangeLowerBorderMessage = "getNextCalendar failed on lower border test of cron range rule";
        calendar.setTime(DateUtils.stringToDate("2020-08-20 13:00:00", localTimeZone));
        assertEquals(
                cronRangeLowerBorderMessage,
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        null,
                        "0 0-30 13 * * ? *",
                        DateUtils.stringToDate("2020-08-20 12:59:59", localTimeZone),
                        DateUtils.localTimeZone).getTime());
        assertEquals(
                cronRangeLowerBorderMessage,
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        null,
                        "0 0-30 13 * * ? *",
                        DateUtils.stringToDate("2020-08-20 13:00:00", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        calendar.setTime(DateUtils.stringToDate("2020-08-20 13:01:00", localTimeZone));
        assertEquals(
                cronRangeLowerBorderMessage,
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        null,
                        "0 0-30 13 * * ? *",
                        DateUtils.stringToDate("2020-08-20 13:00:01", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        String cronRangeUpperBorderMessage = "getNextCalendar failed on lower border test of cron range rule";
        calendar.setTime(DateUtils.stringToDate("2020-08-20 13:30:00", localTimeZone));
        assertEquals(
                cronRangeUpperBorderMessage,
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        null,
                        "0 0-30 13 * * ? *",
                        DateUtils.stringToDate("2020-08-20 13:29:59", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        assertEquals(
                cronRangeUpperBorderMessage,
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        null,
                        "0 0-30 13 * * ? *",
                        DateUtils.stringToDate("2020-08-20 13:30:00", localTimeZone),
                        DateUtils.localTimeZone).getTime());

        calendar.setTime(DateUtils.stringToDate("2020-08-21 13:00:00", localTimeZone));
        assertEquals(
                cronRangeUpperBorderMessage,
                calendar.getTime(),
                CronUtils.getNextCalendar(
                        null,
                        "0 0-30 13 * * ? *",
                        DateUtils.stringToDate("2020-08-20 13:30:01", localTimeZone),
                        DateUtils.localTimeZone).getTime());
    }
}