package me.carda.awesome_notifications.core.managers;

import android.content.Context;
import android.content.SharedPreferences;

import org.checkerframework.checker.nullness.qual.NonNull;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.databases.SQLitePrimitivesDB;
import me.carda.awesome_notifications.core.databases.SqLiteCypher;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.models.AbstractModel;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class RepositoryManager<T extends AbstractModel> {
    private final Class<T> clazz;

    private static final String TAG = "SharedManager";
    private static String packageName;

    private SQLitePrimitivesDB sqLitePrimitives;

    private String hashedReference = "default";
    private final StringUtils stringUtils;

    public RepositoryManager(
            @NonNull StringUtils stringUtils,
            @NonNull String fileIdentifier,
            @NonNull Class<T> targetClass,
            @NonNull String className
    ){
        this.clazz = targetClass;
        this.stringUtils = stringUtils;
        String reference = Definitions.SHARED_MANAGER + "." + fileIdentifier + "." + className;
        try {
            hashedReference = stringUtils.digestString(reference);
            //LogUtils.d(TAG, fileIdentifier+": file initialized = "+ hashedReference);
        } catch (Exception e) {
            this.hashedReference = reference;
            // TODO change register exception to throw exception
            ExceptionFactory
                .getInstance()
                .registerNewAwesomeException(
                        TAG,
                        ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                        "SharedManager could not be correctly initialized: "+ e.getMessage(),
                        ExceptionCode.DETAILED_INITIALIZATION_FAILED+"."+ reference);
        }
    }

    private SQLitePrimitivesDB getDbInstance(
            @NonNull Context context
    ) throws AwesomeNotificationsException {

        SqLiteCypher.initializeEncryption(context);
        if(packageName == null)
            packageName = AwesomeNotifications.getPackageName(context);

        SharedPreferences preferences = context.getSharedPreferences(
                hashedReference,
                Context.MODE_PRIVATE);

        if(preferences == null){
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            "SharedPreferences.getSharedPreferences is not available",
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".getSharedInstance");
        }

        if (sqLitePrimitives == null) {
            sqLitePrimitives = SQLitePrimitivesDB.getInstance(context);
        }

        // CONVERSION FROM SHARED PREFERENCES TO SQLITE
        return convertOldSharedPreferencesIntoSqLite(context, preferences);
    }

    private SQLitePrimitivesDB convertOldSharedPreferencesIntoSqLite(
            @NonNull Context context,
            @NonNull SharedPreferences preferences
    ) throws AwesomeNotificationsException {
        boolean isConvertedTable = sqLitePrimitives.getBoolean(
                context, "conv", hashedReference, false);
        if (isConvertedTable) return sqLitePrimitives;

        if (sqLitePrimitives.stringCount(context, hashedReference) == 0) {
            try {
                Map<String, ?> tempMap = preferences.getAll();
                if(tempMap != null){
                    for (Map.Entry<String, ?> entry : tempMap.entrySet()) {
                        String key = entry.getKey();
                        Object value = entry.getValue();

                        if(value instanceof String){
                            sqLitePrimitives.setString(context, hashedReference, key, (String) value);
                        }
                    }
                }
            } catch (Exception e){
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                                ExceptionCode.DETAILED_SHARED_PREFERENCES+".getAllObjects",
                                e);
            }
        }

        sqLitePrimitives.setBoolean(context, "conv", hashedReference, true);
        return sqLitePrimitives;
    }

    private String generateSharedKey(String tag, String referenceKey){
        return tag+'_'+referenceKey;
    }

    public boolean commit(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        try {

            SQLitePrimitivesDB primitivesDB = getDbInstance(context);
            primitivesDB.commit(context);
            return true;

        } catch (Exception e){
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".commit",
                            e);
        }
    }

    @SuppressWarnings("unchecked")
    public List<T> getAllObjects(
            @NonNull Context context,
            @NonNull String tag
    ) throws AwesomeNotificationsException {
        List<T> returnedList = new ArrayList<>();
        try {
            SQLitePrimitivesDB primitivesDB = getDbInstance(context);
            Map<String, String> tempMap = primitivesDB.getAllStringValues(context, tag);

            for (Map.Entry<String, ?> entry : tempMap.entrySet()) {
                Object value = entry.getValue();
                if(!(value instanceof String)) continue;
                try {
                    T object = clazz.newInstance();
                    returnedList.add((T) object.fromJson((String) value));
                } catch (Exception e){
                    ExceptionFactory
                        .getInstance()
                        .registerNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                                ExceptionCode.DETAILED_SHARED_PREFERENCES+".getAllObjects",
                                e);
                }
            }
        } catch (Exception e){
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".getAllObjects",
                            e);
        }

        return returnedList;
    }

    @SuppressWarnings("unchecked")
    public List<T> getAllObjectsStartingWith(
            @NonNull Context context,
            @NonNull String tag,
            @NonNull String fractionalKey
    ) throws AwesomeNotificationsException {
        List<T> returnedList = new ArrayList<>();
        try {
            SQLitePrimitivesDB primitivesDB = getDbInstance(context);
            Map<String, String> tempMap = primitivesDB
                    .getStringsStartingWith(context, tag, fractionalKey);

            for (Map.Entry<String, ?> entry : tempMap.entrySet()) {
                String key = entry.getKey();
                Object value = entry.getValue();

                if (key.startsWith(tag)) {
                    T object = null;
                    try {
                        object = clazz.newInstance();
                    } catch (InstantiationException | IllegalAccessException e) {
                        ExceptionFactory
                            .getInstance()
                            .registerNewAwesomeException(
                                    TAG,
                                    ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                                    ExceptionCode.DETAILED_SHARED_PREFERENCES+".getAllObjectsStartingWith",
                                    e);
                    }
                    if (object != null) {
                        returnedList.add((T) object.fromJson((String) value));
                    }
                }
            }
        } catch (Exception e){
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".getAllObjectsStartingWith",
                            e);
        }

        return returnedList;
    }


    @SuppressWarnings("unchecked")
    public T get(
            @NonNull Context context,
            @NonNull String tag,
            @NonNull String referenceKey
    ) throws AwesomeNotificationsException {

        try {
            SQLitePrimitivesDB primitivesDB = getDbInstance(context);
            String json = primitivesDB.getString(context, tag, referenceKey, null);

            T returnedObject = null;
            if (!stringUtils.isNullOrEmpty(json)) {
                T genericModel = clazz.newInstance();

                AbstractModel parsedModel = genericModel.fromJson(json);
                if(parsedModel != null){
                    returnedObject = (T) parsedModel;
                }
            }

            return returnedObject;

        } catch (AwesomeNotificationsException awesomeException) {
            throw awesomeException;
        } catch (Exception exception) {
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".get",
                            exception);
        }
    }

    public Boolean set(
            @NonNull Context context,
            @NonNull String tag,
            @NonNull String referenceKey,
            @NonNull T data
    ) throws AwesomeNotificationsException {

        try {
            SQLitePrimitivesDB primitivesDB = getDbInstance(context);
            primitivesDB.setString(context, tag, referenceKey, data.toJson());
            return true;

        } catch (AwesomeNotificationsException awesomeException) {
            throw awesomeException;
        } catch (Exception e) {
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".set",
                            e);
        }
    }

    public Boolean remove(
            @NonNull Context context,
            @NonNull String tag,
            @NonNull String referenceKey
    ) throws AwesomeNotificationsException {

        try {
            SQLitePrimitivesDB primitivesDB = getDbInstance(context);
            primitivesDB.removeString(context, tag, referenceKey);
            return true;

        } catch (AwesomeNotificationsException awesomeException) {
            throw awesomeException;
        } catch (Exception e) {
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".remove",
                            e);
        }
    }

    public Boolean removeAll(
            @NonNull Context context,
            @NonNull String tag
    ) throws AwesomeNotificationsException {

        try {
            SQLitePrimitivesDB primitivesDB = getDbInstance(context);
            primitivesDB.removeAllString(context, tag);
            return true;

        } catch (AwesomeNotificationsException awesomeException) {
            throw awesomeException;
        } catch (Exception e) {
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".removeAll",
                            e);
        }
    }

    private void commitAsync(
            @NonNull String reference,
            SharedPreferences.Editor editor
    ) throws AwesomeNotificationsException {
        if(!editor.commit())
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_SHARED_PREFERENCES_NOT_AVAILABLE,
                            "Android function editor.commit failed",
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".commitAsync");
        /*
        new AsyncTask<Void, Void, Boolean>() {
            @Override
            protected Boolean doInBackground(Void... voids) {
                return editor.commit();
            }

            @Override
            protected void onPostExecute(Boolean value) {
                if(!value){
                    ExceptionFactory
                            .getInstance()
                            .registerNewAwesomeException(
                                    TAG,
                                    ExceptionCode.SHARED_PREFERENCES_NOT_AVAILABLE,
                                    "Android function editor.commit failed",
                                    ExceptionCode.DETAILED_SHARED_PREFERENCES+".commitAsync");
                }
            }
        }.execute();*/
    }
}
