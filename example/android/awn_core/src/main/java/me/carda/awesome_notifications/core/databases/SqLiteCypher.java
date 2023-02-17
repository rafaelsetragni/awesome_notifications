package me.carda.awesome_notifications.core.databases;

import android.annotation.SuppressLint;
import android.content.Context;
import android.provider.Settings;

//import net.sqlcipher.database.SQLiteDatabase;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class SqLiteCypher {

    static boolean isInitialized = false;
    public static void initializeEncryption(Context context) {
        if (isInitialized) return;
        isInitialized = true;

        // Initialize the SQLCipher library with the encryption key
//        SQLiteDatabase.loadLibs(context);
    }

    @SuppressLint("HardwareIds")
    public static String getDatabaseSecret(Context context) {
        // ANDROID_ID will be different for each new App installation + user installation
        String androidId = Settings.Secure.getString(
                context.getContentResolver(),
                Settings.Secure.ANDROID_ID);

        String secret = getInstallationSecret(androidId + context.getPackageName());
        System.out.println("SqLiteCypher secret = "+secret);
        return secret;
    }

    private static String getInstallationSecret(String str) {
        MessageDigest md = null;
        try {
            md = MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            return str;
        }
        md.update(str.getBytes());
        byte[] digest = md.digest();
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < digest.length; i++) {
            sb.append(Integer.toString((digest[i] & 0xff) + 0x100, 16).substring(1));
        }
        return sb.toString();
    }
}
