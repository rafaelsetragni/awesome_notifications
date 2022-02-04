package me.carda.awesome_notifications.awesome_notifications_core.utils;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Iterator;
import java.util.Objects;

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

        if(reference == null)
            reference = "";

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
            } catch(IllegalArgumentException ignored) {
            }
        }
        return null;
    }

    public static String join(final Iterator<?> iterator, final String separator) {

        // handle null, zero and one elements before building a buffer
        if (iterator == null) {
            return null;
        }
        if (!iterator.hasNext()) {
            return "";
        }
        final Object first = iterator.next();
        if (!iterator.hasNext()) {
            return Objects.toString(first, "");
        }

        // two or more elements
        final StringBuilder buf = new StringBuilder(256);
        if (first != null) {
            buf.append(first);
        }

        while (iterator.hasNext()) {
            if (separator != null) {
                buf.append(separator);
            }
            final Object obj = iterator.next();
            if (obj != null) {
                buf.append(obj);
            }
        }
        return buf.toString();
    }
}
