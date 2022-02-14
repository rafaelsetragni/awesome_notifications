package me.carda.awesome_notifications.awesome_notifications_core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.TestUtils;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

import static org.junit.Assert.*;

public class NotificationCalendarModelTest {

    @Before
    public void setUp() throws Exception {
        AbstractModel
                .defaultValues
                .putAll(Definitions.initialValues);
    }

    @After
    public void tearDown() throws Exception {
        Definitions
                .initialValues
                .clear();
    }

    // Starts on Monday
    interface IsoWeekDay {
        Integer Monday = 1;
        Integer Tuesday = 2;
        Integer Wednesday = 3;
        Integer Thursday = 4;
        Integer Friday = 5;
        Integer Saturday = 6;
        Integer Sunday = 7;
    }

    // Starts on Sunday
    interface InternationalWeekDay {
        Integer Sunday = 1;
        Integer Monday = 2;
        Integer Tuesday = 3;
        Integer Wednesday = 4;
        Integer Thursday = 5;
        Integer Friday = 6;
        Integer Saturday = 7;
    }

    @Test
    public void weekDayISO8601ToStandard() {

        assertNull("Weekday returned value when no value was defined",
                NotificationCalendarModel.weekDayISO8601ToStandard(null));

        String errorMessage = "Weekday was incorrectly converted between the patterns ISO 8601 and international standard";

        assertEquals(errorMessage,
                InternationalWeekDay.Monday,
                NotificationCalendarModel.weekDayISO8601ToStandard(
                        IsoWeekDay.Monday));

        assertEquals(errorMessage,
                InternationalWeekDay.Tuesday,
                NotificationCalendarModel.weekDayISO8601ToStandard(
                        IsoWeekDay.Tuesday));

        assertEquals(errorMessage,
                InternationalWeekDay.Wednesday,
                NotificationCalendarModel.weekDayISO8601ToStandard(
                        IsoWeekDay.Wednesday));

        assertEquals(errorMessage,
                InternationalWeekDay.Thursday,
                NotificationCalendarModel.weekDayISO8601ToStandard(
                        IsoWeekDay.Thursday));

        assertEquals(errorMessage,
                InternationalWeekDay.Friday,
                NotificationCalendarModel.weekDayISO8601ToStandard(
                        IsoWeekDay.Friday));

        assertEquals(errorMessage,
                InternationalWeekDay.Saturday,
                NotificationCalendarModel.weekDayISO8601ToStandard(
                        IsoWeekDay.Saturday));

        assertEquals(errorMessage,
                InternationalWeekDay.Sunday,
                NotificationCalendarModel.weekDayISO8601ToStandard(
                        IsoWeekDay.Sunday));

        String invalidValueMustPersistMsg =
                "Invalid values must persist, because this method must not have validation responsibility";
        assertEquals(invalidValueMustPersistMsg, Integer.valueOf(0),
                NotificationCalendarModel.weekDayISO8601ToStandard(0));
        assertEquals(invalidValueMustPersistMsg, Integer.valueOf(8),
                NotificationCalendarModel.weekDayISO8601ToStandard(8));
    }

    @Test
    public void weekDayStandardToISO8601() {

        assertNull("Weekday returned value when no value was defined",
                NotificationCalendarModel.weekDayStandardToISO8601(null));

        String errorMessage = "Weekday was incorrectly converted between the patterns ISO 8601 and international standard";

        assertEquals(errorMessage,
                IsoWeekDay.Monday,
                NotificationCalendarModel.weekDayStandardToISO8601(
                        InternationalWeekDay.Monday));

        assertEquals(errorMessage,
                IsoWeekDay.Tuesday,
                NotificationCalendarModel.weekDayStandardToISO8601(
                        InternationalWeekDay.Tuesday));

        assertEquals(errorMessage,
                IsoWeekDay.Wednesday,
                NotificationCalendarModel.weekDayStandardToISO8601(
                        InternationalWeekDay.Wednesday));

        assertEquals(errorMessage,
                IsoWeekDay.Thursday,
                NotificationCalendarModel.weekDayStandardToISO8601(
                        InternationalWeekDay.Thursday));

        assertEquals(errorMessage,
                IsoWeekDay.Friday,
                NotificationCalendarModel.weekDayStandardToISO8601(
                        InternationalWeekDay.Friday));

        assertEquals(errorMessage,
                IsoWeekDay.Saturday,
                NotificationCalendarModel.weekDayStandardToISO8601(
                        InternationalWeekDay.Saturday));

        assertEquals(errorMessage,
                IsoWeekDay.Sunday,
                NotificationCalendarModel.weekDayStandardToISO8601(
                        InternationalWeekDay.Sunday));

        String invalidValueMustPersistMsg =
                "Invalid values must persist, because this method must not have validation responsibility";
        assertEquals(invalidValueMustPersistMsg, Integer.valueOf(0),
                NotificationCalendarModel.weekDayStandardToISO8601(0));
        assertEquals(invalidValueMustPersistMsg, Integer.valueOf(8),
                NotificationCalendarModel.weekDayStandardToISO8601(8));
    }

    @Test
    public void fromJsonAndToJson() {
        NotificationCalendarModel calendarModel = new NotificationCalendarModel();

        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_TIMEZONE);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_ERA);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_YEAR);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_MONTH);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_DAY);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_HOUR);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_MINUTE);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_SECOND);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_MILLISECOND);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR);
        TestUtils.testModelField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_WEEKDAY);
    }

    @Test
    public void validate() throws AwesomeNotificationsException {
        NotificationCalendarModel calendarModel = new NotificationCalendarModel();

        assertThrows( "Must throw exception case the required files are empty",
                AwesomeNotificationsException.class,() -> {
                    calendarModel.validate(null);
                });

        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_ERA, 0, null);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_YEAR, 0, null);

        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_MONTH, 1, 12);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_DAY, 1, 31);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_HOUR, 0, 23);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_MINUTE, 0, 59);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_SECOND, 0, 59);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_MILLISECOND, 0, 999);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, 1, 7);
        TestUtils.testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH, 1, 6);
        TestUtils. testValidateDateComponentField(calendarModel, Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR, 1, 53);
    }
}