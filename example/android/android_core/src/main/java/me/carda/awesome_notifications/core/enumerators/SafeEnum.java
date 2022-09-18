package me.carda.awesome_notifications.core.enumerators;

import androidx.annotation.NonNull;

/// Protected Enums against minification and obfuscation
public interface SafeEnum {
     String getSafeName();

     static boolean charMatches(@NonNull String text, int stringLength, int pos, char match) {
          if (stringLength <= pos) return false;
          return match == Character.toLowerCase(text.charAt(pos));
     }
}
