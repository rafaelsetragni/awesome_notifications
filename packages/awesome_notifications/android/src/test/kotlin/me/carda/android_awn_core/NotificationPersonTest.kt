package me.carda.android_awn_core

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The core person model shared by the chat and calls add-ons. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class NotificationPersonTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    private val full = mapOf(
        "key" to "ana", "name" to "Ana", "avatar" to "resource://drawable/none",
        "uri" to "tel:123", "isBot" to true, "isImportant" to true
    )

    @Test fun parsesEveryField() {
        val person = NotificationPerson.from(full)!!
        assertEquals("ana", person.key)
        assertEquals("Ana", person.name)
        assertEquals("resource://drawable/none", person.avatar)
        assertEquals("tel:123", person.uri)
        assertTrue(person.isBot)
        assertTrue(person.isImportant)
    }

    @Test fun onlyKeyAndNameAreRequired() {
        val person = NotificationPerson.from(mapOf("key" to "k", "name" to "N"))!!
        assertNull(person.avatar)
        assertNull(person.uri)
        assertFalse(person.isBot)
        assertFalse(person.isImportant)
    }

    @Test fun validation() {
        assertNull(NotificationPerson.from(null))
        assertNull(NotificationPerson.from("ana"))
        assertNull(NotificationPerson.from(mapOf("name" to "Ana")))
        assertNull(NotificationPerson.from(mapOf("key" to "ana")))
        assertNull(NotificationPerson.from(mapOf("key" to " ", "name" to "Ana")))
        assertNull(NotificationPerson.from(mapOf("key" to "ana", "name" to "")))
        assertNull(NotificationPerson.from(mapOf("key" to 1, "name" to "Ana")))
    }

    @Test fun looseTypesAreIgnored() {
        val person = NotificationPerson.from(
            mapOf("key" to "k", "name" to "N", "avatar" to 3, "uri" to false,
                "isBot" to "true", "isImportant" to 1)
        )!!
        assertNull(person.avatar)
        assertNull(person.uri)
        assertFalse(person.isBot)
        assertFalse(person.isImportant)
    }

    @Test fun toPersonCarriesTheFields() {
        val person = NotificationPerson.from(full)!!.toPerson(context)
        assertEquals("ana", person.key)
        assertEquals("Ana", person.name)
        assertEquals("tel:123", person.uri)
        assertTrue(person.isBot)
        assertTrue(person.isImportant)
        assertNull(person.icon) // the avatar does not load
    }

    @Test fun theAvatarIsCircleCropped() {
        val square = Bitmap.createBitmap(40, 20, Bitmap.Config.ARGB_8888)
            .apply { eraseColor(Color.RED) }
        val crop = BitmapUtils.getInstance().circleCrop(square)
        assertEquals(20, crop.width)
        assertEquals(20, crop.height)
        assertEquals(Color.TRANSPARENT, crop.getPixel(0, 0)) // corner outside the circle
    }

    @Test fun anAvatarThatLoadsBecomesTheIcon() {
        val file = java.io.File(context.cacheDir, "avatar.png")
        file.outputStream().use {
            Bitmap.createBitmap(30, 30, Bitmap.Config.ARGB_8888)
                .compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        val person = NotificationPerson("k", "N", "file://" + file.absolutePath, null, false, false)
        val avatar = person.avatarBitmap(context)
        assertNotNull(avatar)
        assertEquals(avatar!!.width, avatar.height)
        assertNotNull(person.toPerson(context).icon)
    }
}
