package me.carda.awesome_notifications.utils;

import android.os.Build;
import android.text.Html;
import android.text.Spanned;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class HtmlUtils {

    @SuppressWarnings("deprecation")
    public static Spanned fromHtml(String html) {
        if (StringUtils.isNullOrEmpty(html)) {
            return null;
        }

        html = adaptFlutterColorsToJava(html);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return Html.fromHtml(html, Html.FROM_HTML_MODE_LEGACY);
        } else {
            return Html.fromHtml(html);
        }
    }

    public static String adaptFlutterColorsToJava(String htmlText){
        if(!StringUtils.isNullOrEmpty(htmlText)){
            final String regex = "(<(\\S+\\s+)*)(color=)('|\")([^'\"]+)('|\")((\\s+[^\\s>]+)*\\/?>)";

            final Pattern pattern = Pattern.compile(regex, Pattern.MULTILINE);
            final Matcher matcher = pattern.matcher(htmlText);

            Boolean converted = false;
            StringBuffer sb = new StringBuffer();

            while (matcher.find()) {
                try {
                    String beforeBody = matcher.group(1);
                    String tag = matcher.group(3);
                    String quoteTypeStart = matcher.group(4);
                    String colorValue = matcher.group(5);
                    Long parsedLog = Long.parseLong(colorValue);
                    String quoteTypeEnd = matcher.group(6);
                    String afterBody = matcher.group(7);
                    Integer parsedInt = parsedLog.intValue();
                    matcher.appendReplacement(sb, beforeBody + tag + quoteTypeStart + parsedInt.toString() + quoteTypeEnd + afterBody);
                    converted = true;
                } catch (Exception e) {

                }
            }

            if(converted){
                matcher.appendTail(sb);
                return sb.toString();
            }
        }

        return htmlText;
    }
}
