package me.carda.awesome_notifications.awesome_notifications_core;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.models.AbstractModel;

public class TestModel extends AbstractModel {

    public boolean isValidModel = false;

    public TestModel() {
        super(stringUtils);
    }

    @Override
    public TestModel fromMap(Map<String, Object> arguments) {
        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        return new HashMap<String, Object>();
    }

    @Override
    public String toJson() {
        return "{}";
    }

    @Override
    public TestModel fromJson(String json) {
        return this;
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationsException {
        if(!isValidModel)
            throw new AwesomeNotificationsException("test");
    }
}
