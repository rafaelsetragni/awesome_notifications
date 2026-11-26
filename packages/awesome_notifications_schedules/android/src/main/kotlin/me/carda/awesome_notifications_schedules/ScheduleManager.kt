package me.carda.awesome_notifications_schedules

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import me.carda.android_awn_core.JsonUtils

/**
 * Persistent store of the pending schedules — port of 0.12's `SQLiteSchedulesDB`.
 * Same database file, table and columns as 0.12 ("AwesomeSchedules.db" /
 * `schedules(id, group_key, channel_key, content)`), so schedules registered by
 * an app still on 0.12 survive the upgrade to 1.0.
 */
internal class SchedulesDatabase private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        const val DATABASE_VERSION = 1
        const val DATABASE_NAME = "AwesomeSchedules.db"

        private const val TABLE_NAME = "schedules"
        private const val COLUMN_ID = "id"
        private const val COLUMN_GROUP_KEY = "group_key"
        private const val COLUMN_CHANNEL_KEY = "channel_key"
        private const val COLUMN_CONTENT = "content"

        private val lock = Any()

        @Volatile private var instance: SchedulesDatabase? = null

        fun getInstance(context: Context): SchedulesDatabase =
            instance ?: synchronized(this) {
                instance ?: SchedulesDatabase(context).also { instance = it }
            }

        /** Test-only: drops the cached helper so each test gets a fresh database. */
        internal fun resetForTest() {
            synchronized(this) {
                instance?.close()
                instance = null
            }
        }
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS $TABLE_NAME(" +
                "$COLUMN_ID INTEGER PRIMARY KEY," +
                "$COLUMN_GROUP_KEY TEXT," +
                "$COLUMN_CHANNEL_KEY TEXT," +
                "$COLUMN_CONTENT TEXT)"
        )
        db.execSQL("CREATE INDEX IF NOT EXISTS group_key_index  ON $TABLE_NAME($COLUMN_GROUP_KEY);")
        db.execSQL("CREATE INDEX IF NOT EXISTS channel_key_index  ON $TABLE_NAME($COLUMN_CHANNEL_KEY);")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}

    fun saveSchedule(id: Int, channelKey: String?, groupKey: String?, content: String) =
        write { db ->
            val values = ContentValues().apply {
                put(COLUMN_ID, id)
                put(COLUMN_CHANNEL_KEY, channelKey)
                put(COLUMN_GROUP_KEY, groupKey)
                put(COLUMN_CONTENT, content)
            }
            db.insertWithOnConflict(TABLE_NAME, null, values, SQLiteDatabase.CONFLICT_REPLACE)
        }

    fun getAllSchedules(): Map<Int, String> =
        query("SELECT $COLUMN_ID, $COLUMN_CONTENT FROM $TABLE_NAME", null)

    fun getScheduleById(id: Int): Map<Int, String> =
        query(
            "SELECT $COLUMN_ID, $COLUMN_CONTENT FROM $TABLE_NAME WHERE $COLUMN_ID = ?",
            arrayOf(id.toString())
        )

    fun getSchedulesByChannelKey(channelKey: String): Map<Int, String> =
        query(
            "SELECT $COLUMN_ID, $COLUMN_CONTENT FROM $TABLE_NAME WHERE $COLUMN_CHANNEL_KEY = ?",
            arrayOf(channelKey)
        )

    fun getSchedulesByGroupKey(groupKey: String): Map<Int, String> =
        query(
            "SELECT $COLUMN_ID, $COLUMN_CONTENT FROM $TABLE_NAME WHERE $COLUMN_GROUP_KEY = ?",
            arrayOf(groupKey)
        )

    fun removeScheduleById(id: Int) =
        write { it.delete(TABLE_NAME, "$COLUMN_ID = ?", arrayOf(id.toString())) }

    fun removeSchedulesByChannelKey(channelKey: String) =
        write { it.delete(TABLE_NAME, "$COLUMN_CHANNEL_KEY = ?", arrayOf(channelKey)) }

    fun removeSchedulesByGroupKey(groupKey: String) =
        write { it.delete(TABLE_NAME, "$COLUMN_GROUP_KEY = ?", arrayOf(groupKey)) }

    fun removeAllSchedules() = write { it.execSQL("DELETE FROM $TABLE_NAME") }

    private fun write(block: (SQLiteDatabase) -> Unit) {
        synchronized(lock) {
            val db = try { writableDatabase } catch (_: Exception) { return }
            db.beginTransaction()
            try {
                block(db)
                db.setTransactionSuccessful()
            } finally {
                db.endTransaction()
            }
        }
    }

    // A HashMap, like 0.12, so the listing order is the same.
    private fun query(sql: String, args: Array<String>?): Map<Int, String> {
        synchronized(lock) {
            val schedules = HashMap<Int, String>()
            val db = try { readableDatabase } catch (_: Exception) { return schedules }
            db.rawQuery(sql, args).use { cursor ->
                while (cursor.moveToNext()) schedules[cursor.getInt(0)] = cursor.getString(1)
            }
            return schedules
        }
    }
}

/**
 * Port of 0.12's `ScheduleManager`: the schedule store keyed by notification id,
 * holding each scheduled notification model as JSON.
 */
object ScheduleManager {

    private fun db(context: Context) = SchedulesDatabase.getInstance(context)

    private fun parse(json: String): Map<String, Any?>? =
        try { JsonUtils.getInstance().fromJson(json) } catch (_: Exception) { null }

    fun listSchedules(context: Context): List<Map<String, Any?>> =
        db(context).getAllSchedules().values.mapNotNull { parse(it) }

    fun getScheduleById(context: Context, id: Int): Map<String, Any?>? =
        db(context).getScheduleById(id).values.firstOrNull()?.let { parse(it) }

    fun listScheduledIds(context: Context): List<Int> =
        ArrayList(db(context).getAllSchedules().keys)

    fun listScheduledIdsFromChannel(context: Context, channelKey: String): List<Int> =
        ArrayList(db(context).getSchedulesByChannelKey(channelKey).keys)

    fun listScheduledIdsFromGroup(context: Context, groupKey: String): List<Int> =
        ArrayList(db(context).getSchedulesByGroupKey(groupKey).keys)

    fun saveSchedule(context: Context, model: Map<String, Any?>) {
        val content = contentOf(model)
        val id = (content[ScheduleKeys.ID] as? Number)?.toInt() ?: return
        db(context).saveSchedule(
            id,
            content[ScheduleKeys.CHANNEL_KEY] as? String,
            content[ScheduleKeys.GROUP_KEY] as? String,
            JsonUtils.getInstance().toJson(model)
        )
    }

    fun removeSchedule(context: Context, model: Map<String, Any?>) {
        val id = (contentOf(model)[ScheduleKeys.ID] as? Number)?.toInt() ?: return
        db(context).removeScheduleById(id)
    }

    fun cancelScheduleById(context: Context, id: Int) = db(context).removeScheduleById(id)

    fun cancelSchedulesByChannelKey(context: Context, channelKey: String) =
        db(context).removeSchedulesByChannelKey(channelKey)

    fun cancelSchedulesByGroupKey(context: Context, groupKey: String) =
        db(context).removeSchedulesByGroupKey(groupKey)

    fun cancelAllSchedules(context: Context) = db(context).removeAllSchedules()

    @Suppress("UNCHECKED_CAST")
    internal fun contentOf(model: Map<String, Any?>): Map<String, Any?> =
        model[ScheduleKeys.CONTENT] as? Map<String, Any?> ?: emptyMap()
}
