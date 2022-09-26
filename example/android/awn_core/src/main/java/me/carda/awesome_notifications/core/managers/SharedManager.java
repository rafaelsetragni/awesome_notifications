package me.carda.awesome_notifications.core.managers;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.models.AbstractModel;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class SharedManager<T extends AbstractModel> {
    private Class<T> clazz;
    private String className;

    private static String TAG = "SharedManager";
    private static String packageName;

    private String reference;
    private String hashedReference = "default";
    private StringUtils stringUtils;

    public SharedManager(StringUtils stringUtils, String fileIdentifier, Class<T> targetClass, String className){
        this.clazz = targetClass;
        this.stringUtils = stringUtils;
        this.className = className;
        this.reference = Definitions.SHARED_MANAGER +"."+ fileIdentifier +"."+ className;
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
                        ExceptionCode.DETAILED_INITIALIZATION_FAILED+"."+reference);
        }
    }

    private SharedPreferences getSharedInstance(Context context) throws AwesomeNotificationsException {

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

        return preferences;
    }

    private String generateSharedKey(String tag, String referenceKey){
        return tag+'_'+referenceKey;
    }

    public void commit(Context context) throws AwesomeNotificationsException {
        try {

            SharedPreferences shared = getSharedInstance(context);
            SharedPreferences.Editor editor = shared.edit();

            commitAsync(reference, editor);

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
    public List<T> getAllObjects(Context context, String tag) throws AwesomeNotificationsException {
        List<T> returnedList = new ArrayList<>();
        try {
            SharedPreferences shared = getSharedInstance(context);

            Map<String, ?> tempMap = shared.getAll();

            if(tempMap != null){
                for (Map.Entry<String, ?> entry : tempMap.entrySet()) {
                    String key = entry.getKey();
                    Object value = entry.getValue();

                    if(key.startsWith(tag) && value instanceof String){
                        T object = clazz.newInstance();
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
                            ExceptionCode.DETAILED_SHARED_PREFERENCES+".getAllObjects",
                            e);
        }

        return returnedList;
    }

    @SuppressWarnings("unchecked")
    public T get(Context context, String tag, String referenceKey) throws AwesomeNotificationsException {

        try {
            SharedPreferences shared = getSharedInstance(context);

            String sharedKey = generateSharedKey(tag, referenceKey);
            String json = shared.getString(sharedKey, null);

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

    public Boolean set(Context context, String tag, String referenceKey, T data) throws AwesomeNotificationsException {

        try {

            SharedPreferences shared = getSharedInstance(context);

            String sharedKey = generateSharedKey(tag, referenceKey);

            String json = data.toJson();

            SharedPreferences.Editor editor = shared.edit();

            editor.putString(sharedKey, json);
            editor.apply();

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

    public Boolean remove(Context context, String tag, String referenceKey) throws AwesomeNotificationsException {

        try {

            SharedPreferences shared = getSharedInstance(context);

            String sharedKey = generateSharedKey(tag, referenceKey);

            SharedPreferences.Editor editor = shared.edit();
            editor.remove(sharedKey);

            editor.apply();

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

    public Boolean removeAll(Context context) throws AwesomeNotificationsException {

        try {
            SharedPreferences shared = getSharedInstance(context);
            SharedPreferences.Editor editor = shared.edit();
            editor.clear();

            editor.apply();

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

    private static void commitAsync(final String reference, final SharedPreferences.Editor editor) throws AwesomeNotificationsException {
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
