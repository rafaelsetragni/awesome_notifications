package me.carda.awesome_notifications;

import android.content.Intent;

import androidx.annotation.NonNull;
import io.flutter.plugin.common.PluginRegistry;
import me.carda.awesome_notifications.notifications.managers.PermissionManager;

public class AwesomePermissionHandler implements
        PluginRegistry.ActivityResultListener,
        PluginRegistry.RequestPermissionsResultListener  {

    private static AwesomePermissionHandler instance;
    public String value;

    private AwesomePermissionHandler() {
    }

    public static AwesomePermissionHandler getInstance() {
        if (instance == null) {
            instance = new AwesomePermissionHandler();
        }
        return instance;
    }

    @Override
    public boolean onRequestPermissionsResult(final int requestCode, @NonNull final String[] permissions, @NonNull final int[] grantResults) {
        return PermissionManager.handlePermissionResult(requestCode, permissions, grantResults);
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        return PermissionManager.handleActivityResult(requestCode, resultCode, data);
    }
}
