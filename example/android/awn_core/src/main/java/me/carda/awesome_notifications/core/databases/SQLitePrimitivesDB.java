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

import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public class SQLitePrimitivesDB extends SQLiteOpenHelper {
    private static final int DATABASE_VERSION = 1;
    private static final String DATABASE_NAME = "AwesomePrimitivesDB.db";

    private static final String TABLE_STRING = "string_prefs";
    private static final String TABLE_INT = "int_prefs";
    private static final String TABLE_FLOAT = "float_prefs";
    private static final String TABLE_BOOLEAN = "boolean_prefs";
    private static final String TABLE_LONG = "long_prefs";

    private static final String TAG = "tag";
    private static final String KEY = "key";
    private static final String VALUE = "value";

    private SQLitePrimitivesDB(Context context, String databasePath) {
        super(context, databasePath, null, DATABASE_VERSION);
    }

    @SuppressLint("StaticFieldLeak")
    private static SQLitePrimitivesDB instance;
    public static SQLitePrimitivesDB getInstance(Context context) {
        if (instance == null) {
//            SqLiteCypher.initializeEncryption(context);
            try
//            (SQLiteDatabase db = SQLiteDatabase.openOrCreateDatabase(
//                    context.getDatabasePath(DATABASE_NAME),
//                    SqLiteCypher.getDatabaseSecret(context),
//                    null,
//                    null
//            ))
            {
                instance = new SQLitePrimitivesDB(context, DATABASE_NAME);
//                instance = new SQLitePrimitivesDB(context, db.getPath());
            } catch (Exception e) {
                ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                        "SQLitePrimitivesDB",
                        ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                        "SQLitePrimitivesDB could not be correctly initialized: "+ e.getMessage(),
                        ExceptionCode.DETAILED_INITIALIZATION_FAILED+".SQLitePrimitivesDB");
            }
        }
        return instance;
    }

    private SQLiteDatabase getWritableDatabase(Context context) {
        try {
            return super.getWritableDatabase();
//            return this.getWritableDatabase(SqLiteCypher.getDatabaseSecret(context));
        } catch (Exception e) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            "SQLitePrimitivesDB",
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            "Could not delivery writable database: "+ e.getMessage(),
                            ExceptionCode.DETAILED_INITIALIZATION_FAILED+".SQLitePrimitivesDB");
        }
        return null;
    }

    private SQLiteDatabase getReadableDatabase(Context context) {
        try {
            return super.getReadableDatabase();
//            return this.getReadableDatabase(SqLiteCypher.getDatabaseSecret(context));
        } catch (Exception e) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            "SQLitePrimitivesDB",
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            "Could not delivery readable database: "+ e.getMessage(),
                            ExceptionCode.DETAILED_INITIALIZATION_FAILED+".SQLitePrimitivesDB");
        }
        return null;
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        String createStringTable = "CREATE TABLE IF NOT EXISTS " + TABLE_STRING + "("
                + TAG + " TEXT, "
                + KEY + " TEXT, "
                + VALUE + " TEXT, "
                + " PRIMARY KEY (" + TAG + ", " + KEY + "));";
        db.execSQL(createStringTable);

        String createIntTable = "CREATE TABLE IF NOT EXISTS " + TABLE_INT + "("
                + TAG + " TEXT, "
                + KEY + " TEXT, "
                + VALUE + " INTEGER, "
                + " PRIMARY KEY (" + TAG + ", " + KEY + "));";
        db.execSQL(createIntTable);

        String createFloatTable = "CREATE TABLE IF NOT EXISTS " + TABLE_FLOAT + "("
                + TAG + " TEXT, "
                + KEY + " TEXT, "
                + VALUE + " REAL, "
                + " PRIMARY KEY (" + TAG + ", " + KEY + "));";
        db.execSQL(createFloatTable);

        String createBooleanTable = "CREATE TABLE IF NOT EXISTS " + TABLE_BOOLEAN + "("
                + TAG + " TEXT, "
                + KEY + " TEXT, "
                + VALUE + " INTEGER, "
                + " PRIMARY KEY (" + TAG + ", " + KEY + "));";
        db.execSQL(createBooleanTable);

        String createLongTable = "CREATE TABLE IF NOT EXISTS " + TABLE_LONG + "("
                + TAG + " TEXT, "
                + KEY + " TEXT, "
                + VALUE + " LONG, "
                + " PRIMARY KEY (" + TAG + ", " + KEY + "));";
        db.execSQL(createLongTable);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
//        if (newVersion > oldVersion) {
//            // Use ALTER TABLE statements to add new columns or update the schema.
//            db.execSQL("ALTER TABLE " + TABLE_BOOLEAN + " ADD COLUMN new_column INTEGER DEFAULT 0");
//            db.execSQL("ALTER TABLE " + TABLE_FLOAT + " ADD COLUMN new_column REAL DEFAULT 0.0");
//            db.execSQL("ALTER TABLE " + TABLE_INT + " ADD COLUMN new_column INTEGER DEFAULT 0");
//            db.execSQL("ALTER TABLE " + TABLE_LONG + " ADD COLUMN new_column INTEGER DEFAULT 0");
//            db.execSQL("ALTER TABLE " + TABLE_STRING + " ADD COLUMN new_column TEXT DEFAULT ''");
//        }
//
//        onCreate(db);
    }

    public void setBoolean(Context context, String tag, String key, boolean value) {
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.beginTransaction();
            ContentValues values = new ContentValues();
            values.put(TAG, tag);
            values.put(KEY, key);
            values.put(VALUE, value ? 1 : 0);
            db.insertWithOnConflict(
                TABLE_BOOLEAN,
                null,
                values,
                SQLiteDatabase.CONFLICT_REPLACE
            );
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public void setInt(Context context, String tag, String key, int value) {
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.beginTransaction();
            ContentValues values = new ContentValues();
            values.put(TAG, tag);
            values.put(KEY, key);
            values.put(VALUE, value);
            db.insertWithOnConflict(
                TABLE_INT,
                null,
                values,
                SQLiteDatabase.CONFLICT_REPLACE
            );
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public void setLong(Context context, String tag, String key, long value) {
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.beginTransaction();
            ContentValues values = new ContentValues();
            values.put(TAG, tag);
            values.put(KEY, key);
            values.put(VALUE, value);
            db.insertWithOnConflict(
                TABLE_LONG,
                null,
                values,
                SQLiteDatabase.CONFLICT_REPLACE
            );
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public void setFloat(Context context, String tag, String key, float value) {
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.beginTransaction();
            ContentValues values = new ContentValues();
            values.put(TAG, tag);
            values.put(KEY, key);
            values.put(VALUE, value);
            db.insertWithOnConflict(
                TABLE_FLOAT,
                null,
                values,
                SQLiteDatabase.CONFLICT_REPLACE
            );
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public void setString(Context context, String tag, String key, String value) {
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.beginTransaction();
            ContentValues values = new ContentValues();
            values.put(TAG, tag);
            values.put(KEY, key);
            values.put(VALUE, value);
            db.insertWithOnConflict(
                TABLE_STRING,
                null,
                values,
                SQLiteDatabase.CONFLICT_REPLACE
            );
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public int getInt(Context context, String tag, String key, int defaultValue) {
        return getRow(context, TABLE_INT, tag, key, defaultValue, Cursor::getInt);
    }

    public long getLong(Context context, String tag, String key, long defaultValue) {
        return getRow(context, TABLE_LONG, tag, key, defaultValue, Cursor::getLong);
    }

    public float getFloat(Context context, String tag, String key, float defaultValue) {
        return getRow(context, TABLE_FLOAT, tag, key, defaultValue, Cursor::getFloat);
    }

    public boolean getBoolean(Context context, String tag, String key, boolean defaultValue) {
        return getRow(context, TABLE_BOOLEAN, tag, key, defaultValue,
            (cursor, index) -> cursor.getInt(index) == 1
        );
    }

    public String getString(Context context, String tag, String key, String defaultValue) {
        return getRow(context, TABLE_STRING, tag, key, defaultValue, Cursor::getString);
    }

    private interface iGetRow<T> {
        T execute(Cursor cursor, int index);
    }

    private <T> T getRow(
            Context context,
            String tableName,
            String tag,
            String key,
            T defaultValue,
            iGetRow<T> getterValue
    ){
        String sqlQuery = "SELECT "+VALUE+" FROM "+tableName+
                " WHERE "+TAG+" = ?"+
                " AND "+KEY+" = ?";

        try (SQLiteDatabase db = getReadableDatabase(context)) {
            try (Cursor cursor = db.rawQuery(sqlQuery, new String[]{tag, key})) {
                T value = defaultValue;
                if (cursor.moveToNext()) {
                    value = getterValue.execute(cursor, 0);
                }
                return value;
            }
        }
    }


    public int stringCount(Context context, String tag) { return countRows(context, tag, TABLE_STRING); }
    public int floatCount(Context context, String tag) { return countRows(context, tag, TABLE_FLOAT); }
    public int intCount(Context context, String tag) { return countRows(context, tag, TABLE_INT); }
    public int booleanCount(Context context, String tag) { return countRows(context, tag, TABLE_BOOLEAN); }
    public int longCount(Context context, String tag) { return countRows(context, tag, TABLE_LONG); }

    private int countRows(Context context, String tag, String tableName) {
        String sqlQuery = "SELECT count(*) FROM "+tableName+
                " WHERE "+TAG+" = ?";
        try (SQLiteDatabase db = getReadableDatabase(context)) {
            try (Cursor cursor = db.rawQuery(sqlQuery, new String[]{tag})) {
                int count = 0;
                if (cursor.moveToNext()) {
                    count = cursor.getInt(0);
                }
                return count;
            }
        }
    }

    public Map<String, String> getAllStringValues(Context context, String tag) {
        return getAll(context, tag, TABLE_STRING, (iGetAll<String>) Cursor::getString);
    }

    public Map<String, Float> getAllFloatValues(Context context, String tag) {
        return getAll(context, tag, TABLE_FLOAT, (iGetAll<Float>) Cursor::getFloat);
    }

    public Map<String, Integer> getAllIntValues(Context context, String tag) {
        return getAll(context, tag, TABLE_INT, (iGetAll<Integer>) Cursor::getInt);
    }

    public Map<String, Boolean> getAllBooleanValues(Context context, String tag) {
        return getAll(context, tag, TABLE_BOOLEAN, (iGetAll<Boolean>) (cursor, index) -> cursor.getInt(index) == 1);
    }

    public Map<String, Long> getAllLongValues(Context context, String tag) {
        return getAll(context, tag, TABLE_LONG, (iGetAll<Long>) Cursor::getLong);
    }

    private interface iGetAll<T> {
        T execute(Cursor cursor, int index);
    }

    private <T> Map<String, T> getAll(Context context, String tag, String tableName, iGetAll<T> getterValue) {
        Map<String, T> values = new HashMap<>();
        String sqlQuery = "SELECT " + KEY + ", " + VALUE + " FROM " + tableName + " WHERE " + TAG + " = ?";

        try (SQLiteDatabase db = getReadableDatabase(context)) {
            try (Cursor cursor = db.rawQuery(sqlQuery, new String[]{tag})) {
                if (cursor.moveToFirst()) {
                    do {
                        values.put(
                            cursor.getString(0),
                            getterValue.execute(cursor, 1)
                        );
                    } while (cursor.moveToNext());
                }
                return values;
            }
        }
    }

    public void setAllIntValues(Context context, String tag, Map<String, Integer> intValues) {
        setAll(
            context,
            tag,
            TABLE_INT,
            intValues,
            ((contentValues, value) -> contentValues.put(VALUE, value))
        );
    }

    public void setAllStringValues(Context context, String tag, Map<String, String> stringValues) {
        setAll(
            context,
            tag,
            TABLE_STRING,
            stringValues,
            ((contentValues, value) -> contentValues.put(VALUE, value))
        );
    }

    public void setAllFloatValues(Context context, String tag, Map<String, Float> floatValues) {
        setAll(
            context,
            tag,
            TABLE_FLOAT,
            floatValues,
            ((contentValues, value) -> contentValues.put(VALUE, value))
        );
    }

    public void setAllBooleanValues(Context context, String tag, Map<String, Boolean> booleanValues) {
        setAll(
            context,
            tag,
            TABLE_BOOLEAN,
            booleanValues,
            ((contentValues, value) -> contentValues.put(VALUE, value ? 1 : 0))
        );
    }

    public void setAllLongValues(Context context, String tag, Map<String, Long> longValues) {
        setAll(
            context,
            tag,
            TABLE_LONG,
            longValues,
            ((contentValues, value) -> contentValues.put(VALUE, value))
        );
    }

    private interface iSetAll<T> {
        void execute(ContentValues contentValues, T value);
    }

    private <T> void setAll(
            Context context,
            String tag,
            String tableName,
            Map<String, T> values,
            iSetAll<T> setterValue
    ){
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.beginTransaction();
            for (Map.Entry<String, T> entry : values.entrySet()) {
                ContentValues contentValues = new ContentValues();
                contentValues.put(TAG, tag);
                contentValues.put(KEY, entry.getKey());
                setterValue.execute(contentValues, entry.getValue());
                db.insertWithOnConflict(
                    tableName,
                    null,
                    contentValues,
                    SQLiteDatabase.CONFLICT_REPLACE
                );
            }
            db.setTransactionSuccessful();
            db.endTransaction();
        }
    }

    public void removeString(Context context, String tag, String key){ remove(context, TABLE_STRING, tag, key); }
    public void removeFloat(Context context, String tag, String key){ remove(context, TABLE_FLOAT, tag, key); }
    public void removeInt(Context context, String tag, String key){ remove(context, TABLE_INT, tag, key); }
    public void removeBoolean(Context context, String tag, String key){ remove(context, TABLE_BOOLEAN, tag, key); }
    public void removeLong(Context context, String tag, String key){ remove(context, TABLE_LONG, tag, key); }

    private void remove(Context context, String tableName, String tag, String key) {
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.delete(
                tableName,
                TAG + " = ? AND " + KEY + " = ?",
                new String[]{tag, key}
            );
        }
    }

    public void removeAllString(Context context, String tag){ removeAll(context, TABLE_STRING, tag); }
    public void removeAllFloat(Context context, String tag){ removeAll(context, TABLE_FLOAT, tag); }
    public void removeAllInt(Context context, String tag){ removeAll(context, TABLE_INT, tag); }
    public void removeAllBoolean(Context context, String tag){ removeAll(context, TABLE_BOOLEAN, tag); }
    public void removeAllLong(Context context, String tag){ removeAll(context, TABLE_LONG, tag); }

    private void removeAll(Context context, String tableName, String tag) {
        try (SQLiteDatabase db = getWritableDatabase(context)) {
            db.delete(tableName, TAG + " = ?", new String[]{tag});
        }
    }

    public void commit(Context context) {
//        SQLiteDatabase db = getWritableDatabase(context);
//        db.close();
    }
}
