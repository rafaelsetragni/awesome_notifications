package me.carda.android_awn_core

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * BitmapUtils' guard paths: a null/empty/unknown-scheme reference yields no
 * bitmap (the network/file/asset/resource loaders themselves do real I/O and are
 * exercised on-device, not here).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BitmapUtilsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val bitmaps = BitmapUtils.getInstance()

    @Test fun nullReferenceReturnsNull() {
        assertNull(bitmaps.getBitmapFromSource(context, null))
    }

    @Test fun emptyReferenceReturnsNull() {
        assertNull(bitmaps.getBitmapFromSource(context, ""))
    }

    @Test fun unknownSchemeReturnsNull() {
        assertNull(bitmaps.getBitmapFromSource(context, "weird://nope"))
    }
}
