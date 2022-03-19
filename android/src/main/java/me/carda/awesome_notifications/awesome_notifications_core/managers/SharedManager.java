package me.carda.awesome_notifications.awesome_notifications_core.managers;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import me.carda.awesome_notifications.awesome_notifications_core.logs.Logger;


import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.models.AbstractModel;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class SharedManager<T extends AbstractModel> {
    private Class<T> clazz;
    private String className;

    private static String TAG = "SharedManager";

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
            Logger.e(TAG, "SharedManager could not be correctly initialized: "+ e.getMessage());
            e.printStackTrace();
        }
    }

    private SharedPreferences getSharedInstance(Context context) throws AwesomeNotificationsException {

        SharedPreferences preferences = context.getSharedPreferences(
                context.getPackageName() + "." + hashedReference,
                Context.MODE_PRIVATE
        );

        if(preferences == null){
            throw new AwesomeNotificationsException("SharedPreferences.getSharedPreferences return null");
        }

        return preferences;
    }

    private String generateSharedKey(String tag, String referenceKey){
        return tag+'_'+referenceKey;
    }

    public void commit(Context context){
        try {

            SharedPreferences shared = getSharedInstance(context);
            SharedPreferences.Editor editor = shared.edit();

            commitAsync(reference, editor);

        } catch (Exception e){
            e.printStackTrace();
            Logger.e(TAG, e.toString());
        }
    }

    @SuppressWarnings("unchecked")
    public List<T> getAllObjects(Context context, String tag){
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
            e.printStackTrace();
            Logger.e(TAG, e.toString());
        }

        return returnedList;
    }

    @SuppressWarnings("unchecked")
    public T get(Context context, String tag, String referenceKey){

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

        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
            Logger.e(TAG, e.toString());
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    public Boolean set(Context context, String tag, String referenceKey, T data){

        try {

            SharedPreferences shared = getSharedInstance(context);

            String sharedKey = generateSharedKey(tag, referenceKey);

            String json = data.toJson();

            SharedPreferences.Editor editor = shared.edit();

            editor.putString(sharedKey, json);
            editor.apply();

            return true;

        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
            Logger.e(TAG, e.toString());
        }

        return false;
    }

    public Boolean remove(Context context, String tag, String referenceKey){

        try {

            SharedPreferences shared = getSharedInstance(context);

            String sharedKey = generateSharedKey(tag, referenceKey);

            SharedPreferences.Editor editor = shared.edit();
            editor.remove(sharedKey);

            editor.apply();

            return true;

        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
            Logger.e(TAG, e.toString());
        }

        return false;
    }

    public Boolean removeAll(Context context){

        try {
            SharedPreferences shared = getSharedInstance(context);
            SharedPreferences.Editor editor = shared.edit();
            editor.clear();

            editor.apply();

            return true;

        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
            Logger.e(TAG, e.toString());
        }

        return false;
    }

    private static void commitAsync(final String reference, final SharedPreferences.Editor editor) {
        new AsyncTask<Void, Void, Boolean>() {
            @Override
            protected Boolean doInBackground(Void... voids) {
                return editor.commit();
            }

            @Override
            protected void onPostExecute(Boolean value) {
                if(!value){
                    Logger.d(reference,"shared data could not be saved");
                }
            }
        }.execute();
    }
}
