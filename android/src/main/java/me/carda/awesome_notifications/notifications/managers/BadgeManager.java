package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.preference.PreferenceManager;
import android.provider.Settings;

import me.carda.awesome_notifications.Definitions;
import me.leolin.shortcutbadger.ShortcutBadger;

public class BadgeManager {

    public static int getGlobalBadgeCounter(Context context) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        // Read previous value. If not found, use 0 as default value.
        return prefs.getInt(Definitions.BADGE_COUNT, 0);
    }

    public static void setGlobalBadgeCounter(Context context, int count) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        SharedPreferences.Editor editor = prefs.edit();

        editor.putInt(Definitions.BADGE_COUNT, count);
        ShortcutBadger.applyCount(context, count);

        editor.apply();
    }

    public static void resetGlobalBadgeCounter(Context context) {
        setGlobalBadgeCounter(context, 0);
    }

    public static int incrementGlobalBadgeCounter(Context context) {
        int totalAmount = getGlobalBadgeCounter(context);
        setGlobalBadgeCounter(context, ++totalAmount);
        return totalAmount;
    }

    public static int decrementGlobalBadgeCounter(Context context) {
        int totalAmount = Math.max(getGlobalBadgeCounter(context)-1, 0);
        setGlobalBadgeCounter(context, totalAmount);
        return totalAmount;
    }

    private static boolean isBadgeDeviceGloballyAllowed(Context context){
        try {
            return Settings.Secure.getInt(context.getContentResolver(), "notification_badging") == PermissionManager.ON;
        } catch (Settings.SettingNotFoundException e) {
            return true;
        }
    }

    private static boolean isBadgeNumberingAllowed(Context context){
        try {
            int currentBadgeCount = getGlobalBadgeCounter(context);
            ShortcutBadger.applyCountOrThrow(context, currentBadgeCount);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static boolean isBadgeAppGloballyAllowed(Context context){
        // TODO missing global badge checking for the current application scope
        //Settings.Secure.getInt(context.getContentResolver(), "notification_badging").contains(context.getPackageName());
        return true;
    }

    public static boolean isBadgeGloballyAllowed(Context context){

        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N /*Android 7*/) {
            if(!isBadgeDeviceGloballyAllowed(context))
                return false;

            if(isBadgeNumberingAllowed(context))
                return true;

            return isBadgeAppGloballyAllowed(context);
        }

        return true;
    }
}
