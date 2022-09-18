package me.carda.awesome_notifications.core.managers;

import static java.lang.Math.max;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.preference.PreferenceManager;
import android.provider.Settings;

import me.carda.awesome_notifications.core.Definitions;
import me.leolin.shortcutbadger.ShortcutBadger;

public class BadgeManager {

    // ************** SINGLETON PATTERN ***********************

    protected static BadgeManager instance;

    protected BadgeManager(){}

    public static BadgeManager getInstance() {
        if (instance == null)
            instance = new BadgeManager();
        return instance;
    }

    // ********************************************************

    public int getGlobalBadgeCounter(Context context) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        // Read previous value. If not found, use 0 as default value.
        return max(prefs.getInt(Definitions.BADGE_COUNT, 0),0);
    }

    public void setGlobalBadgeCounter(Context context, int count) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        SharedPreferences.Editor editor = prefs.edit();

        editor.putInt(Definitions.BADGE_COUNT, count);
        ShortcutBadger.applyCount(context, count);

        editor.apply();
    }

    public void resetGlobalBadgeCounter(Context context) {
        setGlobalBadgeCounter(context, 0);
    }

    public int incrementGlobalBadgeCounter(Context context) {
        int totalAmount = getGlobalBadgeCounter(context);
        totalAmount++;
        setGlobalBadgeCounter(context, totalAmount);
        return totalAmount;
    }

    public int decrementGlobalBadgeCounter(Context context) {
        int totalAmount = max(getGlobalBadgeCounter(context) - 1, 0);
        setGlobalBadgeCounter(context, totalAmount);
        return totalAmount;
    }

    boolean isBadgeDeviceGloballyAllowed(Context context){
        try {
            return Settings.Secure.getInt(context.getContentResolver(), "notification_badging") == PermissionManager.ON;
        } catch (Settings.SettingNotFoundException ignored) {
            return true;
        }
    }

    boolean isBadgeNumberingAllowed(Context context){
        try {
            int currentBadgeCount = getGlobalBadgeCounter(context);
            ShortcutBadger.applyCountOrThrow(context, currentBadgeCount);
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    boolean isBadgeAppGloballyAllowed(Context context){
        // TODO missing global badge checking for the current application scope
        //Settings.Secure.getInt(context.getContentResolver(), "notification_badging").contains(context.getPackageName());
        return true;
    }

    public boolean isBadgeGloballyAllowed(Context context){
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.N /*Android 7*/ ||
               isBadgeDeviceGloballyAllowed(context) &&
               isBadgeAppGloballyAllowed(context);
    }
}
