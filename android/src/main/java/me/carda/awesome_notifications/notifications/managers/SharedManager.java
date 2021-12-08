package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.AsyncTask;

import io.flutter.Log;

import java.security.*;
import java.math.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.AbstractModel;
import me.carda.awesome_notifications.utils.StringUtils;

public class SharedManager<T extends AbstractModel> {
    private Class<T> clazz;
    private String className;

    private static String TAG = "SharedManager";

    private String reference;
    private String hashedReference = "default";

    public SharedManager(String fileIdentifier, Class<T> targetClass, String className){
        this.clazz = targetClass;
        this.className = className;
        this.reference = Definitions.SHARED_MANAGER +"."+ fileIdentifier +"."+ className;
        try {
            hashedReference = StringUtils.digestString(reference);
            //Log.d(TAG, fileIdentifier+": file initialized = "+ hashedReference);
        } catch (Exception e) {
            this.hashedReference = reference;
            Log.e(TAG, "SharedManager could not be correctly initialized: "+ e.getMessage());
            e.printStackTrace();
        }
    }

    private SharedPreferences getSharedInstance(Context context) throws AwesomeNotificationException {

        SharedPreferences preferences = context.getSharedPreferences(
                context.getPackageName() + "." + hashedReference,
                Context.MODE_PRIVATE
        );

        if(preferences == null){
            throw new AwesomeNotificationException("SharedPreferences.getSharedPreferences return null");
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
            Log.e(TAG, e.toString());
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
            Log.e(TAG, e.toString());
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
            if (!StringUtils.isNullOrEmpty(json)) {
                T genericModel = clazz.newInstance();

                AbstractModel parsedModel = genericModel.fromJson(json);
                if(parsedModel != null){
                    returnedObject = (T) parsedModel;
                }
            }

            return returnedObject;

        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
            Log.e(TAG, e.toString());
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

        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
            Log.e(TAG, e.toString());
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

        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
            Log.e(TAG, e.toString());
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
                    Log.d(reference,"shared data could not be saved");
                }
            }
        }.execute();
    }
}
