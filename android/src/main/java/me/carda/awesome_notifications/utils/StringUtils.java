package me.carda.awesome_notifications.utils;

import java.math.BigInteger;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class StringUtils {

    public static Boolean isNullOrEmpty(String string){
        return string == null || string.trim().isEmpty();
    }

    public static String getValueOrDefault(String value, String defaultValue){
        return isNullOrEmpty(value) ? defaultValue : value;
    }

    public static String digestString(String reference){

        MessageDigest md = null;
        final String MD5 = "MD5";

        try {
            reference = reference.replaceAll("\\W+", "");

            byte[] bytes = reference.getBytes(StandardCharsets.UTF_8);

            md = MessageDigest.getInstance(MD5);
            md.reset();
            md.update(bytes);

            final BigInteger bigInt = new BigInteger(1, md.digest());
            return String.format("%032x", bigInt);

        } catch (Exception ex) {
            //("MD5 Cryptography Not Supported");
            return reference;
        }
    }

    public static <T extends Enum<T>> T getEnumFromString(Class<T> clazz, String string) {
        if( clazz != null && string != null ) {
            try {
                return Enum.valueOf(clazz, string.trim());
            } catch(IllegalArgumentException ex) {
            }
        }
        return null;
    }
}
