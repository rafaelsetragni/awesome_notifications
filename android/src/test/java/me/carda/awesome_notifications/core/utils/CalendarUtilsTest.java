package me.carda.awesome_notifications.core.utils;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

public class CalendarUtilsTest {

    String localTimeZoneId = "America/Sao_Paulo";
    Calendar millennialBugCalendarUTC, millennialBugCalendarLocal;
    Date millennialBugDate;

    @Before
    public void setUp() throws Exception {

        CalendarUtils.getInstance().getNowCalendar();

        SimpleDateFormat sdf = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.ENGLISH);

        millennialBugDate = sdf.parse("2000-01-01 00:00:00");
        assert millennialBugDate != null;

        millennialBugCalendarUTC = Calendar.getInstance();
        millennialBugCalendarUTC.setTimeZone(TimeZone.getTimeZone("UTC"));
        setCalendarMillennialBugValues(millennialBugCalendarUTC);

        millennialBugCalendarLocal = Calendar.getInstance();
        millennialBugCalendarLocal.setTimeZone(TimeZone.getTimeZone(localTimeZoneId));
        setCalendarMillennialBugValues(millennialBugCalendarLocal);
    }

    private void setCalendarMillennialBugValues(Calendar calendar){
        calendar.set(Calendar.MILLISECOND, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.HOUR, 0);
        calendar.set(Calendar.DAY_OF_MONTH, 1);
        calendar.set(Calendar.MONTH, 0);
        calendar.set(Calendar.YEAR, 2000);
    }

    @After
    public void tearDown() throws Exception {
    }

    private static String printCalendar(Calendar calendar){
        SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy");
        return sdf.format(calendar.getTime());
    }

    @Test
    public void getUtcTimeZone() throws AwesomeNotificationsException {

        CalendarUtils originalSUT = CalendarUtils.getInstance();
        CalendarUtils SUT = spy(originalSUT);

        doReturn(millennialBugCalendarUTC.clone()).when(SUT).getNowCalendar();
        doReturn(millennialBugCalendarUTC.clone()).when(SUT).getCurrentCalendar(anyString());

        Calendar calendar1 = SUT.getCurrentCalendar();

        assertNotNull(calendar1);
        assertNotNull(calendar1.getTimeZone());

        assertEquals("UTC", calendar1.getTimeZone().getID());
        assertEquals(0, calendar1.get(Calendar.SECOND));
        assertEquals(0, calendar1.get(Calendar.MINUTE));
        assertEquals(0, calendar1.get(Calendar.HOUR));
        assertEquals(1, calendar1.get(Calendar.AM));
        assertEquals(1, calendar1.get(Calendar.DAY_OF_MONTH));
        assertEquals(0, calendar1.get(Calendar.MONTH));
        assertEquals(2000, calendar1.get(Calendar.YEAR));
    }

    @Test
    public void getLocalTimeZone() throws AwesomeNotificationsException {

        CalendarUtils SUT = spy(CalendarUtils.class);
        when(SUT.getNowCalendar()).thenReturn(millennialBugCalendarUTC);

        Calendar calendar = SUT.getCurrentCalendar(localTimeZoneId);

        assertNotNull(calendar.getTimeZone());

        assertEquals(localTimeZoneId, calendar.getTimeZone().getID());
        assertEquals(0, calendar.get(Calendar.SECOND));
        assertEquals(0, calendar.get(Calendar.MINUTE));
        assertEquals(22, calendar.get(Calendar.HOUR_OF_DAY));
        assertEquals(10, calendar.get(Calendar.HOUR));
        assertEquals(1, calendar.get(Calendar.AM));
        assertEquals(31, calendar.get(Calendar.DAY_OF_MONTH));
        assertEquals(11, calendar.get(Calendar.MONTH));
        assertEquals(1999, calendar.get(Calendar.YEAR));
    }

    @Test
    public void stringToCalendar() throws AwesomeNotificationsException {

        String localTimeZoneId =
                CalendarUtils
                        .getInstance()
                        .getLocalTimeZone()
                        .getID();

    }

    @Test
    public void calendarToString() {
    }

    @Test
    public void getLocalCalendar() {
    }

    @Test
    public void shiftToTimeZone() {
    }

    @Test
    public void getUTCDate() {
    }

    @Test
    public void getUTCNowCalendar() {
    }

    @Test
    public void getLocalNowCalendar() {
    }

    @Test
    public void getTimeZone() {
    }

    @Test
    public void cleanTimeZoneIdentifier() {
    }
}