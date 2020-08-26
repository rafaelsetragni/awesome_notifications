package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.utils.JsonUtils;

public class SharedManager<T> {
    private T t;

    private static String TAG = "SharedManager";

    private static SharedPreferences _sharedInstance = null;

    public SharedManager(){
    }

    private SharedPreferences getSharedInstance(Context context){
        if(_sharedInstance == null){
            _sharedInstance = context.getSharedPreferences(
                Definitions.SHARED_MANAGER,
                Context.MODE_PRIVATE
            );
        }
        return _sharedInstance;
    }

    private T parseJson(
        Type typeToken,
        String json
    ){
       //return JsonUtils.fromJson(new TypeToken<T>(getClass()){}.getType(), json);
       return JsonUtils.fromJson(typeToken, json);
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
            Log.d(TAG, e.toString());
        }
        return returnedList;
    }

    private String generateSharedKey(String tag, String referenceKey){
        return tag+'_'+referenceKey;
    }

    public T get(Context context, Type typeToken, String tag, String referenceKey){
        SharedPreferences shared = getSharedInstance(context);
        String sharedKey = generateSharedKey(tag, referenceKey);
        String json = shared.getString(sharedKey, null);

        T returnedObject = null;
        if (json != null) {
            returnedObject = parseJson(typeToken, json);
        }
        return returnedObject;
    }

    public Boolean set(Context context, String tag, String referenceKey, T data){
        SharedPreferences shared = getSharedInstance(context);
        String sharedKey = generateSharedKey(tag, referenceKey);

        String json = JsonUtils.toJson(data);
        SharedPreferences.Editor editor = shared.edit();

        editor.putString(sharedKey, json);

        editor.apply();
        return true;
    }

    public Boolean remove(Context context, String tag, String referenceKey){
        SharedPreferences shared = getSharedInstance(context);
        String sharedKey = generateSharedKey(tag, referenceKey);

        SharedPreferences.Editor editor = shared.edit();
        editor.remove(sharedKey);

        editor.apply();
        return true;
    }
}
