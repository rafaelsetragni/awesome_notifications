package me.carda.awesome_notifications.awesome_notifications_core.models;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.function.ThrowingRunnable;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.TestUtils;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

import static org.hamcrest.CoreMatchers.instanceOf;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.*;
import static org.mockito.AdditionalMatchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;

public class NotificationScheduleModelTest {

    Calendar testCalendar;
    Calendar invalidCalendar;

    @Before
    public void setUp() throws Exception {

        AbstractModel
                .defaultValues
                .putAll(Definitions.initialValues);

        testCalendar = Calendar.getInstance();
        testCalendar.setTime(TestUtils.exampleDate);

        invalidCalendar = (Calendar) testCalendar.clone();
        invalidCalendar.add(Calendar.SECOND, -1);

        TestUtils.startMockedDateUtils();
    }

    @After
    public void tearDown() throws Exception {
        Definitions
                .initialValues
                .clear();

        TestUtils.stopMockedDateUtils();
    }

    @Test
    public void fromJsonAndToJson() {
        NotificationIntervalModel intervalModel = new NotificationIntervalModel();

        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_SCHEDULE_TIMEZONE);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_CREATED_DATE);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_SCHEDULE_REPEATS);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_ALLOW_WHILE_IDLE);
        TestUtils.testModelField(intervalModel, Definitions.NOTIFICATION_SCHEDULE_PRECISE_ALARM);

        intervalModel.fromMap(new HashMap<String, Object>());
        assertNotNull("In case where createdDate wasn't defined, it must be updated " +
                "with nowDate to backward compatibility", intervalModel.createdDate);
    }

    @Test
    public void getNextValidDate() {
    }

    @Test
    public void hasNextValidDate() throws Exception {

        final NotificationScheduleModel testScheduleModel = new NotificationScheduleModel() {

            @Override
            public Calendar getNextValidDate(@NonNull Calendar fixedNowDate) {
                return fixedNowDate == null || fixedNowDate != TestUtils.exampleDate ? null : testCalendar;
            }

            @Override
            public String toJson() { return null; }
            @Override
            public AbstractModel fromJson(String json) { return null; }
            @Override
            public void validate(Context context) { }
        };

        assertFalse("Without a nextValidDate, hasNextValidDate must return false",
                testScheduleModel.hasNextValidDate(null));

        assertTrue("With a nextValidDate, hasNextValidDate must return true",
                testScheduleModel.hasNextValidDate(TestUtils.exampleDate));

        testScheduleModel.timeZone = "invalid";
        assertThrows(AwesomeNotificationsException.class, new ThrowingRunnable() {
            @Override
            public void run() throws Throwable {
                testScheduleModel.hasNextValidDate();
            }
        });
        testScheduleModel.timeZone = null;

        assertFalse("Without created date, non-repeated calendars cannot determine" +
                        " if next date is in future or not and must return false.",
                    testScheduleModel.hasNextValidDate());

        testScheduleModel.repeats = true;
        testScheduleModel.createdDate = null;
        assertTrue("Without created date, repeated calendars can determine a reference date",
                testScheduleModel.hasNextValidDate());
        testScheduleModel.repeats = false;

        testScheduleModel.createdDate = TestUtils.exampleStringDate;
        assertFalse("Without a nextValidDate, hasNextValidDate must return false",
                testScheduleModel.hasNextValidDate(invalidCalendar.getTime()));

    }

    @Test
    public void getScheduleModelFromMap() {
        assertNull("", NotificationScheduleModel.getScheduleModelFromMap(null));
        assertNull("", NotificationScheduleModel.getScheduleModelFromMap(new HashMap<String, Object>()));
        assertNull("", NotificationScheduleModel.getScheduleModelFromMap(new HashMap<String, Object>(){{put("INVALID","test");}}));

        NotificationScheduleModel scheduleModel1 = NotificationScheduleModel.getScheduleModelFromMap(new HashMap<String, Object>(){{
          put(Definitions.NOTIFICATION_CRONTAB_EXPRESSION, "* * * * * ");
          put(Definitions.NOTIFICATION_PRECISE_SCHEDULES, null);
          put(Definitions.NOTIFICATION_EXPIRATION_DATE_TIME, null);
        }});

        assertThat("", scheduleModel1, instanceOf(NotificationCrontabModel.class));

        NotificationScheduleModel scheduleModel2 = NotificationScheduleModel.getScheduleModelFromMap(new HashMap<String, Object>(){{
            put(Definitions.NOTIFICATION_SCHEDULE_SECOND, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_MINUTE, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_HOUR, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_DAY, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_MONTH, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_YEAR, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_ERA, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_MILLISECOND, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH, 1);
            put(Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR, 1);
        }});

        assertThat("", scheduleModel2, instanceOf(NotificationCalendarModel.class));

        NotificationScheduleModel scheduleModel3 = NotificationScheduleModel.getScheduleModelFromMap(new HashMap<String, Object>(){{
            put(Definitions.NOTIFICATION_SCHEDULE_INTERVAL, 60);
        }});

        assertThat("", scheduleModel3, instanceOf(NotificationIntervalModel.class));
    }
}