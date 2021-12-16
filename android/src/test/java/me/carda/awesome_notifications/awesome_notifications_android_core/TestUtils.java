package me.carda.awesome_notifications.awesome_notifications_android_core;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.AbstractModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.CompareUtils;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

public class TestUtils {

    public static Object getDefaultValue(String reference) {
        return Definitions.initialValues.get(reference);
    }

    public static void testModelField(AbstractModel model, String fieldName) {

        switch (fieldName) {

            case Definitions.NOTIFICATION_SCHEDULE_TIMEZONE:
            case Definitions.NOTIFICATION_TITLE:
            case Definitions.NOTIFICATION_BODY:
            case Definitions.NOTIFICATION_SUMMARY:
            case Definitions.NOTIFICATION_BUTTON_KEY_PRESSED:
            case Definitions.NOTIFICATION_BUTTON_KEY_INPUT:
            case Definitions.NOTIFICATION_BUTTON_KEY:
            case Definitions.NOTIFICATION_BUTTON_ICON:
            case Definitions.NOTIFICATION_BUTTON_LABEL:
            case Definitions.NOTIFICATION_CRONTAB_EXPRESSION:
                //case Definitions.NOTIFICATION_ICON:
            case Definitions.NOTIFICATION_SOUND_SOURCE:
            case Definitions.NOTIFICATION_GROUP_KEY:
            case Definitions.NOTIFICATION_CUSTOM_SOUND:
            case Definitions.NOTIFICATION_PRIVATE_MESSAGE:
            case Definitions.NOTIFICATION_CHANNEL_KEY:
            case Definitions.NOTIFICATION_CHANNEL_NAME:
            case Definitions.NOTIFICATION_CHANNEL_DESCRIPTION:
            case Definitions.NOTIFICATION_CHANNEL_GROUP_NAME:
            case Definitions.NOTIFICATION_CHANNEL_GROUP_KEY:
            case Definitions.NOTIFICATION_APP_ICON:
            case Definitions.NOTIFICATION_LARGE_ICON:
            case Definitions.NOTIFICATION_BIG_PICTURE:
            case Definitions.NOTIFICATION_TICKER:
                testStringField(model, fieldName);
                break;

            case Definitions.NOTIFICATION_SCHEDULE_REPEATS:
            case Definitions.NOTIFICATION_SCHEDULE_PRECISE_ALARM:
            case Definitions.NOTIFICATION_SHOW_WHEN:
            case Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT:
            case Definitions.NOTIFICATION_ENABLED:
            case Definitions.NOTIFICATION_AUTO_DISMISSIBLE:
            case Definitions.NOTIFICATION_IS_DANGEROUS_OPTION:
            case Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW:
            case Definitions.NOTIFICATION_LOCKED:
            case Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND:
            case Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND:
            case Definitions.NOTIFICATION_FULL_SCREEN_INTENT:
            case Definitions.NOTIFICATION_WAKE_UP_SCREEN:
            case Definitions.NOTIFICATION_PLAY_SOUND:
            case Definitions.NOTIFICATION_ENABLE_VIBRATION:
            case Definitions.NOTIFICATION_GROUP_SORT:
            case Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR:
            case Definitions.NOTIFICATION_PRIVACY:
            case Definitions.NOTIFICATION_CATEGORY:
            case Definitions.NOTIFICATION_DEFAULT_PRIVACY:
            case Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE:
            case Definitions.NOTIFICATION_ONLY_ALERT_ONCE:
            case Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE:
            case Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS:
            case Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND:
            case Definitions.NOTIFICATION_ENABLE_LIGHTS:
            case Definitions.NOTIFICATION_ALLOW_WHILE_IDLE:
                testBooleanField(model, fieldName);
                break;

            case Definitions.SILENT_HANDLE:
            case Definitions.DART_BG_HANDLE:
            case Definitions.NOTIFICATION_ID:
            case Definitions.NOTIFICATION_TIMESTAMP:
            case Definitions.NOTIFICATION_PROGRESS:
            case Definitions.NOTIFICATION_LED_ON_MS:
            case Definitions.NOTIFICATION_LED_OFF_MS:
            case Definitions.NOTIFICATION_SCHEDULE_ERA:
            case Definitions.NOTIFICATION_SCHEDULE_YEAR:
            case Definitions.NOTIFICATION_SCHEDULE_INTERVAL:
            case Definitions.NOTIFICATION_SCHEDULE_MONTH:
            case Definitions.NOTIFICATION_SCHEDULE_DAY:
            case Definitions.NOTIFICATION_SCHEDULE_HOUR:
            case Definitions.NOTIFICATION_SCHEDULE_MINUTE:
            case Definitions.NOTIFICATION_SCHEDULE_SECOND:
            case Definitions.NOTIFICATION_SCHEDULE_MILLISECOND:
            case Definitions.NOTIFICATION_SCHEDULE_WEEKDAY:
            case Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH:
            case Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR:
                testNumberField(model, fieldName);
                break;

            case Definitions.NOTIFICATION_CREATED_SOURCE:
            case Definitions.NOTIFICATION_CREATED_LIFECYCLE:
            case Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE:
            case Definitions.NOTIFICATION_DISMISSED_LIFECYCLE:
            case Definitions.NOTIFICATION_ACTION_LIFECYCLE:
            case Definitions.NOTIFICATION_LAYOUT:
            case Definitions.NOTIFICATION_ACTION_TYPE:
            case Definitions.NOTIFICATION_IMPORTANCE:
                testEnumField(model, fieldName);
                break;

            //case Definitions.NOTIFICATION_SCHEDULE_CREATED_DATE:
            case Definitions.NOTIFICATION_CREATED_DATE:
            case Definitions.NOTIFICATION_ACTION_DATE:
            case Definitions.NOTIFICATION_DISPLAYED_DATE:
            case Definitions.NOTIFICATION_DISMISSED_DATE:
            case Definitions.NOTIFICATION_INITIAL_FIXED_DATE:
            case Definitions.NOTIFICATION_INITIAL_DATE_TIME:
            case Definitions.NOTIFICATION_EXPIRATION_DATE_TIME:
                testDateField(model, fieldName);
                break;

            case Definitions.NOTIFICATION_PAYLOAD:
                testMapField(model, fieldName);
                break;

            case Definitions.NOTIFICATION_COLOR:
            case Definitions.NOTIFICATION_DEFAULT_COLOR:
            case Definitions.NOTIFICATION_BACKGROUND_COLOR:
            case Definitions.NOTIFICATION_LED_COLOR:
                testColorField(model, fieldName);
                break;

            case Definitions.NOTIFICATION_PRECISE_SCHEDULES:
            case Definitions.NOTIFICATION_VIBRATION_PATTERN:
                testListField(model, fieldName);
                break;
        }
    }

    public static void testStringField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testFieldValue(model, fieldName, "test", String.class);
        testDefaultFieldValue(model, fieldName);
    }

    public static void testBooleanField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testFieldValue(model, fieldName, true, Boolean.class);
        testFieldValue(model, fieldName, true, Boolean.class);
        testDefaultFieldValue(model, fieldName);
    }

    public static void testNumberField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testFieldValue(model, fieldName, 1, Integer.class);
        testFieldValue(model, fieldName, 1.0, Integer.class);
        testFieldValue(model, fieldName, Integer.MIN_VALUE, Integer.class);
        testFieldValue(model, fieldName, Integer.MAX_VALUE, Integer.class);
        testDefaultFieldValue(model, fieldName);
    }

    public static void testColorField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testFieldValue(model, fieldName, 1, Integer.class);
        testFieldValue(model, fieldName, 1.0, Integer.class);
        testFieldValue(model, fieldName, Integer.MIN_VALUE, Integer.class);
        testFieldValue(model, fieldName, Integer.MAX_VALUE, Integer.class);
        testDefaultFieldValue(model, fieldName);
    }

    public static void testDateField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testFieldValue(model, fieldName, "2000-01-01 00:00:00", String.class);
        testDefaultFieldValue(model, fieldName);
    }

    public static void testEnumField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testDefaultFieldValue(model, fieldName);
    }

    public static void testListField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testFieldValue(model, fieldName, Collections.singletonList(1), List.class);
        testFieldValue(model, fieldName, Arrays.asList(1,2,3), List.class);
        testDefaultFieldValue(model, fieldName);
    }

    public static void testMapField(@NonNull AbstractModel model, @NonNull String fieldName) {
        testDefaultFieldValue(model, fieldName);
    }

    public static void testFieldValue(@NonNull AbstractModel model, @NonNull String fieldName, @NonNull Object testValue, @NonNull Class type) {
        Map<String, Object> testMap = new HashMap<>();
        testMap.put(fieldName, testValue);
        AbstractModel clonedModel = model.getClone();

        clonedModel.fromMap(testMap);
        Map<String, Object> mapData = clonedModel.toMap();
        Object valueReturned = mapData.get(fieldName);

        assertNotNull("Field value of '" + fieldName + "' could not be recovered using map converters.", valueReturned);

        assertTrue("Field value of '" + fieldName + "' is not the same as expected using map converters.",
                type.isAssignableFrom(valueReturned.getClass()));

        testEqualValuesWithAwesomeTolerance(fieldName, valueReturned, testValue);
    }

    private static void testEqualValuesWithAwesomeTolerance(String fieldName, Object value1, Object value2) {
        if (!CompareUtils.assertEqualObjects(value1, value2))
            assertEquals(
                    "Field value of '" + fieldName + "' is not the same as expected using map converters.",
                    value1, value2);
    }

    public static void testInvalidFieldValue(@NonNull AbstractModel model, @NonNull String fieldName, @NonNull Object invalidValue, @NonNull Class type) {
        Map<String, Object> testMap = new HashMap<>();
        testMap.put(fieldName, invalidValue);

        model.fromMap(testMap);
        Map<String, Object> mapData = model.toMap();
        Object valueReturned = mapData.get(fieldName);

        assertNull("The invalid field value of '" + fieldName + "' was not dropped from map converters.", valueReturned);
    }

    public static void testNullFieldValue(@NonNull AbstractModel model, @NonNull String fieldName) {
        Map<String, Object> testMap = new HashMap<>();
        testMap.put(fieldName, null);

        model.fromMap(testMap);
        Map<String, Object> mapData = model.toMap();
        Object valueReturned = mapData.get(fieldName);

        assertNotNull("Default value of field '" + fieldName + "' could not be recovered " +
                "in case of null values or missing fields.", valueReturned);
    }

    public static boolean testDefaultFieldValue(@NonNull AbstractModel model, @NonNull String fieldName) {
        Object defaultValue = getDefaultValue(fieldName);
        if (defaultValue == null) return true;

        Map<String, Object> testMap = new HashMap<>();

        testMap.put(fieldName, defaultValue);
        model.fromMap(testMap);
        Map<String, Object> mapData = model.toMap();
        Object valueReturned = mapData.get(fieldName);

        if (!defaultValue.equals(valueReturned))
            return false;

        testMap.put(fieldName, null);
        model.fromMap(testMap);
        mapData = model.toMap();
        valueReturned = mapData.get(fieldName);

        return defaultValue.equals(valueReturned);
    }

    public static void testValidateDateComponentField(@NonNull AbstractModel model, @NonNull String fieldName, @Nullable Integer min, @Nullable Integer max) throws AwesomeNotificationException {
        min = min == null ? Integer.MIN_VALUE : min;
        max = max == null ? Integer.MAX_VALUE : max;

        putTestFieldValue(model, fieldName, min).validate(null);
        putTestFieldValue(model, fieldName, max).validate(null);
        putTestFieldValue(model, fieldName, min + 1).validate(null);
        putTestFieldValue(model, fieldName, max - 1).validate(null);

        if(min != Integer.MIN_VALUE) {
            Integer finalMin = min;
            assertThrows(AwesomeNotificationException.class,() -> {
                putTestFieldValue(model, fieldName, Integer.valueOf(finalMin) - 1).validate(null);
            });
        }

        if(max != Integer.MAX_VALUE) {
            Integer finalMax = max;
            assertThrows(AwesomeNotificationException.class, () -> {
                putTestFieldValue(model, fieldName, Integer.valueOf(finalMax) + 1).validate(null);
            });
        }

        TestUtils.testDefaultFieldValue(model, fieldName);
    }

    public static AbstractModel putTestFieldValue(@NonNull AbstractModel model, @NonNull String fieldName, @Nullable Integer value){
        AbstractModel clonedModel = model.getClone();
        Map<String, Object> originalMap = model.toMap();
        originalMap.put(fieldName, value);
        clonedModel.fromMap(originalMap);
        return clonedModel;
    }
}
