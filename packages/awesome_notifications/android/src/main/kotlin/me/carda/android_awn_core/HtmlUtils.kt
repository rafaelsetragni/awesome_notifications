package me.carda.android_awn_core

import android.os.Build
import android.text.Html
import android.text.Spanned
import java.util.regex.Pattern

/**
 * 0.12 `HtmlUtils`: the notification texts (title, body, summary, the
 * layouts' lines) are HTML, so `<b>`, `<i>`, `<font color=…>` and the like
 * render as styles. A Flutter color (`color="4294901760"` or `0x…` decimal)
 * is first turned into the signed int Java's HTML parser reads.
 */
object HtmlUtils {

    private val colorPattern = Pattern.compile(
        "(<(\\S+\\s+)*)(color=)('|\")(0x|#)?(\\d+)('|\")((\\s+[^\\s>]+)*\\/?>)",
        Pattern.MULTILINE
    )

    /** 0.12 `fromHtml`: null for a null / blank text. */
    fun fromHtml(html: String?): Spanned? {
        if (StringUtils.getInstance().isNullOrEmpty(html)) return null
        val adapted = adaptFlutterColorsToJava(html!!)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            Html.fromHtml(adapted, Html.FROM_HTML_MODE_LEGACY)
        } else {
            @Suppress("DEPRECATION")
            Html.fromHtml(adapted)
        }
    }

    /** 0.12 `adaptFlutterColorsToJava`, verbatim. */
    fun adaptFlutterColorsToJava(htmlText: String): String {
        if (StringUtils.getInstance().isNullOrEmpty(htmlText)) return htmlText
        val matcher = colorPattern.matcher(htmlText)
        var converted = false
        val buffer = StringBuffer()
        while (matcher.find()) {
            try {
                val beforeBody = matcher.group(1)
                val tag = matcher.group(3)
                val quoteTypeStart = matcher.group(4)
                val parsed = java.lang.Long.parseLong(matcher.group(6)!!)
                val quoteTypeEnd = matcher.group(7)
                val afterBody = matcher.group(8)
                val parsedInt = parsed.toInt()
                matcher.appendReplacement(
                    buffer,
                    beforeBody + tag + quoteTypeStart + parsedInt.toString() + quoteTypeEnd + afterBody
                )
                converted = true
            } catch (_: Exception) {
            }
        }
        if (converted) {
            matcher.appendTail(buffer)
            return buffer.toString()
        }
        return htmlText
    }
}
