package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.AsyncTask;

import io.flutter.Log;

import java.security.*;
import java.math.*;

import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.PushNotification;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.utils.JsonUtils;

public class SharedManager<T> {
    private T t;

    private static String TAG = "SharedManager";
    private String reference = "default";
    private String hashedReference = "default";

    public SharedManager(String fileIdentifier, Class targetClass){

        reference = Definitions.SHARED_MANAGER +"."+ fileIdentifier +"."+ targetClass.getName();
        try {

            MessageDigest m = MessageDigest.getInstance("MD5");
            m.update(reference.getBytes(),0,reference.length());
            hashedReference = new BigInteger(1,m.digest()).toString(16);

            Log.d(TAG, fileIdentifier+": file initialized = "+ hashedReference);

        } catch (Exception e) {

            this.reference = fileIdentifier;

            Log.e(TAG, "SharedManager could not be initialized: "+ e.getMessage());
            e.printStackTrace();
        }
    }

    private SharedPreferences getSharedInstance(Context context) throws PushNotificationException {

        SharedPreferences preferences = context.getSharedPreferences(
                context.getPackageName() + "." + (hashedReference == null ? reference : hashedReference),
                Context.MODE_PRIVATE
        );

        if(preferences == null){
            throw new PushNotificationException("SharedPreferences.getSharedPreferences return null");
        }

        return preferences;
    }

    private String generateSharedKey(String tag, String referenceKey){
        return tag+'_'+referenceKey;
    }

    private T parseJson(
        Type typeToken,
        String json
    ){
       //return JsonUtils.fromJson(new TypeToken<T>(getClass()){}.getType(), json);
       return JsonUtils.fromJson(typeToken, json);
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
    public List<T> getAllObjects(Context context, Type typeToken, String tag){
        List<T> returnedList = new ArrayList<>();
        try {
            SharedPreferences shared = getSharedInstance(context);

            Map<String, ?> tempMap = shared.getAll();

            if(tempMap != null){
                for (Map.Entry<String, ?> entry : tempMap.entrySet()) {
                    String key = entry.getKey();
                    Object value = entry.getValue();

                    if(key.startsWith(tag) && value instanceof String){
                        returnedList.add(parseJson(typeToken, (String) value));
                    }
                }
            }
        } catch (Exception e){
            e.printStackTrace();
            Log.e(TAG, e.toString());
        }

        return returnedList;
    }

    public T get(Context context, Type typeToken, String tag, String referenceKey){

        try {
            SharedPreferences shared = getSharedInstance(context);

            String sharedKey = generateSharedKey(tag, referenceKey);
            String json = shared.getString(sharedKey, null);

            T returnedObject = null;
            if (json != null) {
                returnedObject = parseJson(typeToken, json);
            }

            return returnedObject;

        } catch (PushNotificationException e) {
            e.printStackTrace();
            Log.e(TAG, e.toString());
        }

        return null;
    }

    public Boolean set(Context context, String tag, String referenceKey, T data){

        try {

            SharedPreferences shared = getSharedInstance(context);

            String sharedKey = generateSharedKey(tag, referenceKey);

            String json = JsonUtils.toJson(data);

            SharedPreferences.Editor editor = shared.edit();

            editor.putString(sharedKey, json);
            editor.apply();

            return true;

        } catch (PushNotificationException e) {
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

        } catch (PushNotificationException e) {
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
