package me.carda.awesome_notifications.core.databases;

import android.annotation.SuppressLint;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;

//import net.sqlcipher.database.SQLiteDatabase;
//import net.sqlcipher.database.SQLiteOpenHelper;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Nullable;

import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public class SQLiteSchedulesDB extends SQLiteOpenHelper {

    private static final int DATABASE_VERSION = 1;
    private static final String DATABASE_NAME = "AwesomeSchedules.db";

    private static final String TABLE_NAME = "schedules";
    private static final String COLUMN_ID = "id";
    private static final String COLUMN_GROUP_KEY = "group_key";
    private static final String COLUMN_CHANNEL_KEY = "channel_key";
    private static final String COLUMN_CONTENT = "content";

    @SuppressLint("StaticFieldLeak")
    private static SQLiteSchedulesDB instance;
    public static synchronized SQLiteSchedulesDB getInstance(Context context) {
        if (instance == null) {
//            SQLiteDatabase.loadLibs(context);
//            SqLiteCypher.initializeEncryption(context);
            try
//            (SQLiteDatabase db = SQLiteDatabase.openOrCreateDatabase(
//                    context.getDatabasePath(DATABASE_NAME),
//                    SqLiteCypher.getDatabaseSecret(context),
//                    null
//            ))
            {
                instance = new SQLiteSchedulesDB(context, DATABASE_NAME);
//                instance = new SQLiteSchedulesDB(context, db.getPath());
            } catch (Exception e) {
                ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                        "SQLiteSchedulesDB",
                        ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                        "SQLiteSchedulesDB could not be correctly initialized: "+ e.getMessage(),
                        ExceptionCode.DETAILED_INITIALIZATION_FAILED+".SQLiteSchedulesDB");
            }
        }
        return instance;
    }

    private SQLiteSchedulesDB(Context context, String databasePath) {
        super(context, databasePath, null, DATABASE_VERSION);
    }

    @Nullable
    private SQLiteDatabase getWritableDatabase(Context context) {
        try {
            return super.getWritableDatabase();
//            return this.getWritableDatabase(SqLiteCypher.getDatabaseSecret(context));
        } catch (Exception e) {
            ExceptionFactory
                .getInstance()
                .registerNewAwesomeException(
                    "SQLiteSchedulesDB",
                    ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                    "Writable database could not be delivered: "+ e.getMessage(),
                    ExceptionCode.DETAILED_INITIALIZATION_FAILED+".SQLiteSchedulesDB");
        }
        return null;
    }

    @Nullable
    private SQLiteDatabase getReadableDatabase(Context context) {
        try {
            return super.getReadableDatabase();
//            return this.getReadableDatabase(SqLiteCypher.getDatabaseSecret(context));
        } catch (Exception e) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            "SQLiteSchedulesDB",
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            "Readable database could not be delivered: "+ e.getMessage(),
                            ExceptionCode.DETAILED_INITIALIZATION_FAILED+".SQLiteSchedulesDB");
        }
        return null;
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        String CREATE_TABLE = "CREATE TABLE IF NOT EXISTS " + TABLE_NAME + "("
                + COLUMN_ID + " INTEGER PRIMARY KEY,"
                + COLUMN_GROUP_KEY + " TEXT,"
                + COLUMN_CHANNEL_KEY + " TEXT,"
                + COLUMN_CONTENT + " TEXT"
                + ")";
        db.execSQL(CREATE_TABLE);

        final String CREATE_INDEX_GROUP_KEY = "CREATE INDEX IF NOT EXISTS group_key_index "
                + " ON " + TABLE_NAME + "(" + COLUMN_GROUP_KEY + ");";

        final String CREATE_INDEX_CHANNEL_KEY = "CREATE INDEX IF NOT EXISTS channel_key_index "
                + " ON " + TABLE_NAME + "(" + COLUMN_CHANNEL_KEY + ");";

        db.execSQL(CREATE_INDEX_GROUP_KEY);
        db.execSQL(CREATE_INDEX_CHANNEL_KEY);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
//        db.execSQL("DROP TABLE IF EXISTS " + TABLE_NAME);
//        onCreate(db);
    }

    public synchronized void saveSchedule(
            Context context,
            Integer id,
            String channelKey,
            String groupKey,
            String content
    ) {
        try (SQLiteDatabase db = this.getWritableDatabase(context)) {
            if (db == null) return;
            db.beginTransaction();
            ContentValues values = new ContentValues();
            values.put(COLUMN_ID, id);
            values.put(COLUMN_CHANNEL_KEY, channelKey);
            values.put(COLUMN_GROUP_KEY, groupKey);
            values.put(COLUMN_CONTENT, content);
            db.insertWithOnConflict(
                    TABLE_NAME,
                    null,
                    values,
                    SQLiteDatabase.CONFLICT_REPLACE
            );
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public Map<Integer, String> getAllSchedules(Context context) {
        Map<Integer, String> schedules = new HashMap<>();

        // Select all query
        String selectQuery = "SELECT " + COLUMN_ID + ", " + COLUMN_CONTENT + " FROM " + TABLE_NAME;

        try (SQLiteDatabase db = this.getReadableDatabase(context)) {
            if (db == null) return schedules;
            try (Cursor cursor = db.rawQuery(selectQuery, null)) {
                if (cursor.moveToFirst()) {
                    do {
                        schedules.put(cursor.getInt(0), cursor.getString(1));
                    } while (cursor.moveToNext());
                }
                return schedules;
            }
        }
    }

    public Map<Integer, String> getScheduleById(Context context, Integer id) {
        Map<Integer, String> schedule = new HashMap<>();

        // Select all query
        String selectQuery = "SELECT " + COLUMN_ID + ", " + COLUMN_CONTENT +
                " FROM " + TABLE_NAME + " WHERE " + COLUMN_ID + " = ?";

        try (SQLiteDatabase db = this.getReadableDatabase(context)) {
            if (db == null) return schedule;
            try (Cursor cursor = db.rawQuery(selectQuery, new String[]{String.valueOf(id)})) {
                if (cursor.moveToFirst()) {
                    do {
                        schedule.put(cursor.getInt(0), cursor.getString(1));
                    } while (cursor.moveToNext());
                }
                return schedule;
            }
        }
    }

    public Map<Integer, String> getSchedulesByChannelKey(Context context, String channelKey) {
        Map<Integer, String> schedules = new HashMap<>();

        // Select all query
        String selectQuery = "SELECT " + COLUMN_ID + ", " + COLUMN_CONTENT +
                " FROM " + TABLE_NAME + " WHERE " + COLUMN_CHANNEL_KEY + " = ?";

        try (SQLiteDatabase db = this.getReadableDatabase(context)) {
            if (db == null) return schedules;
            try (Cursor cursor = db.rawQuery(selectQuery, new String[]{channelKey})) {
                if (cursor.moveToFirst()) {
                    do {
                        schedules.put(cursor.getInt(0), cursor.getString(1));
                    } while (cursor.moveToNext());
                }
                return schedules;
            }
        }
    }

    public Map<Integer, String> getSchedulesByGroupKey(Context context, String groupKey) {
        Map<Integer, String> schedules = new HashMap<>();

        // Select all query
        String selectQuery = "SELECT " + COLUMN_ID + ", " + COLUMN_CONTENT +
                " FROM " + TABLE_NAME + " WHERE " + COLUMN_GROUP_KEY + " = ?";

        try (SQLiteDatabase db = this.getReadableDatabase(context)) {
            if (db == null) return schedules;
            try (Cursor cursor = db.rawQuery(selectQuery, new String[]{groupKey})) {
                // Looping through all rows and adding to list
                if (cursor.moveToFirst()) {
                    do {
                        schedules.put(cursor.getInt(0), cursor.getString(1));
                    } while (cursor.moveToNext());
                }
                return schedules;
            }
        }
    }

    public synchronized void removeScheduleById(Context context, Integer id) {
        try (SQLiteDatabase db = this.getWritableDatabase(context)){
            if (db == null) return;
            db.beginTransaction();
            db.delete(TABLE_NAME, COLUMN_ID + " = ?", new String[]{String.valueOf(id)});
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public synchronized void removeSchedulesByChannelKey(Context context, String channelKey) {
        try (SQLiteDatabase db = this.getWritableDatabase(context)) {
            if (db == null) return;
            db.beginTransaction();
            db.delete(TABLE_NAME, COLUMN_CHANNEL_KEY + " = ?", new String[]{channelKey});
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public synchronized void removeSchedulesByGroupKey(Context context, String groupKey) {
        try (SQLiteDatabase db = this.getWritableDatabase(context)){
            if (db == null) return;
            db.beginTransaction();
            db.delete(TABLE_NAME, COLUMN_GROUP_KEY + " = ?", new String[]{groupKey});
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public synchronized void removeAllSchedules(Context context) {
        try (SQLiteDatabase db = this.getWritableDatabase(context)){
            if (db == null) return;
            db.beginTransaction();
            db.execSQL("DELETE FROM " + TABLE_NAME);
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public synchronized void commit(Context context){
//        SQLiteDatabase db = this.getWritableDatabase(context);
//        db.close();
    }
}