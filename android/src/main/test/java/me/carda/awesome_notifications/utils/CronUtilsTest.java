package android.src.main.test.java.me.carda.awesome_notifications.utils;

import android.icu.text.TimeZoneNames;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.sql.Time;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import me.carda.push_notifications.externalLibs.CronExpression;

import static org.junit.Assert.*;

public class CronUtilsTest {

    String testValidDate;
    String testInvalidDate;
    Date validDate;

    @Before
    public void setUp() throws Exception {

        testValidDate = "2020-08-20 13:29:05";
        testInvalidDate = "2020-20-08 13:29:06";
        validDate = DateUtils.parseDate("2020-08-20 13:29:05");
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void getDateFromString() {
        assertEquals(validDate, DateUtils.parseDate(testValidDate));
        assertNotEquals(validDate, DateUtils.parseDate(testInvalidDate));
        assertEquals(validDate, DateUtils.parseDate("2020-08-20 13:29:05"));
    }

    @Test
    public void applyToleranceDate() {
        String nowDate = "2020-08-20 13:29:05";

        assertNotEquals(
            DateUtils.parseDate("2020-08-20 13:28:59"),
            CronUtils.applyToleranceDate(DateUtils.parseDate(nowDate))
        );

        assertEquals(
            DateUtils.parseDate("2020-08-20 13:29:00"),
            CronUtils.applyToleranceDate(DateUtils.parseDate(nowDate))
        );

        assertNotEquals(
            DateUtils.parseDate("2020-08-20 13:29:01"),
            CronUtils.applyToleranceDate(DateUtils.parseDate(nowDate))
        );
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
    }

    @Test
    public void getNextCalendar() {
        assertNull(CronUtils.getNextCalendar(null, null));

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(DateUtils.utcTimeZone);

        CronUtils.fixedNowDate = DateUtils.parseDate("2020-08-20 13:29:05");
        assertNull(CronUtils.getNextCalendar("2020-08-20 13:28:59", null));

        calendar.setTime(DateUtils.parseDate("2020-08-20 13:29:00"));
        assertNull(CronUtils.getNextCalendar("2020-08-20 13:29:00", null));

        calendar.setTime(DateUtils.parseDate("2020-08-20 13:29:01"));
        assertNull(CronUtils.getNextCalendar("2020-08-20 13:29:01", null));

        calendar.setTime(DateUtils.parseDate("2020-08-20 13:29:04"));
        assertNull(CronUtils.getNextCalendar("2020-08-20 13:29:04", null));

        calendar.setTime(DateUtils.parseDate("2020-08-20 13:29:05"));
        assertEquals(calendar, CronUtils.getNextCalendar("2020-08-20 13:29:05", null));

        calendar.setTime(DateUtils.parseDate("2020-08-20 13:29:06"));
        assertEquals(calendar, CronUtils.getNextCalendar("2020-08-20 13:29:06", null));

        calendar.setTime(DateUtils.parseDate("2020-08-20 13:30:00"));
        assertEquals(calendar, CronUtils.getNextCalendar("2020-08-20 13:30:00", null));


        assertNull(CronUtils.getNextCalendar(null, ""));
        assertNull(CronUtils.getNextCalendar(null, ""));
        assertNull(CronUtils.getNextCalendar(null, "* * * * *"));
        assertNull(CronUtils.getNextCalendar(null, "* * * * * *"));
        assertNull(CronUtils.getNextCalendar(null, "0 0 12 * * ? 2017"));

        CronUtils.fixedNowDate = DateUtils.parseDate("2020-08-20 13:29:05");
        calendar.setTime(DateUtils.parseDate("2020-08-20 13:30:00"));
        assertEquals(calendar, CronUtils.getNextCalendar(null, "0 0-30 13 * * ? *"));

        calendar.setTime(DateUtils.parseDate("2020-08-20 13:29:06"));
        assertEquals(calendar, CronUtils.getNextCalendar(null, "0-10 * * * * ? *"));

        calendar.setTime(DateUtils.parseDate("2021-01-01 00:00:00"));
        assertEquals(calendar, CronUtils.getNextCalendar(null, "0 * * * * ? 2021"));
        assertEquals(calendar, CronUtils.getNextCalendar(null, "0 * * ? * * 2021"));

        /// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
        calendar.setTime(DateUtils.parseDate("2020-08-20 14:45:05"));
        assertEquals(calendar, CronUtils.getNextCalendar(testValidDate, "5 45 14 20 08 ? 2020"));
        assertEquals(calendar, CronUtils.getNextCalendar(null, "5 45 14 20 08 ? 2020"));

        CronUtils.fixedNowDate = DateUtils.parseDate("2020-08-20 14:45:05");
        assertNull(CronUtils.getNextCalendar(null, "5 45 14 20 08 ? 2020"));
        assertNull(CronUtils.getNextCalendar(testValidDate, "5 45 14 20 08 ? 2020"));

        CronUtils.fixedNowDate = DateUtils.parseDate("2020-08-20 14:45:04");
        calendar.setTime(DateUtils.parseDate("2020-08-20 14:45:05"));
        assertEquals(calendar, CronUtils.getNextCalendar(testValidDate, "5 45 14 20 08 ? 2020"));
    }
}