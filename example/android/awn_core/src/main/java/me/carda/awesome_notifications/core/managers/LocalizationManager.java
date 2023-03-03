package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import java.util.Locale;

import me.carda.awesome_notifications.core.databases.SQLitePrimitivesDB;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public class LocalizationManager {
    private static final String TAG = "LocalizationManager";

    private static LocalizationManager instance;
    public static LocalizationManager getInstance(){
        if (instance == null) instance = new LocalizationManager();
        return instance;
    }

    public boolean setLocalization(Context context, String languageCode){
        try {
            if (languageCode == null) {
                Locale currentLocale = context.getResources().getConfiguration().locale;
                languageCode = currentLocale.toLanguageTag().toLowerCase();
            }
            SQLitePrimitivesDB
                    .getInstance(context)
                    .setString(
                        context,
                        "localization",
                        "languageCode",
                        languageCode.toLowerCase()
                    );
            return true;
        } catch (Exception e) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                            "SQLitePrimitivesDB is not available",
                            ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".setLocalization");
            return false;
        }
    }

    public String getLocalization(Context context){
        String languageCode = null;

        try {
            Locale currentLocale = context.getResources().getConfiguration().locale;
            languageCode = currentLocale.toLanguageTag().toLowerCase();
            languageCode = SQLitePrimitivesDB
                    .getInstance(context)
                    .getString(
                            context,
                            "localization",
                            "languageCode",
                            languageCode
                    );

        } catch (Exception e) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                            "SQLitePrimitivesDB is not available",
                            ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".getLocalization");
            return languageCode;
        }

        return languageCode;
    }
}
