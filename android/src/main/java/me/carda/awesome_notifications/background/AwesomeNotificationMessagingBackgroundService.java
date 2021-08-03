// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package me.carda.awesome_notifications.background;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.app.JobIntentService;
import io.flutter.embedding.engine.FlutterShellArgs;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

public class AwesomeNotificationMessagingBackgroundService extends JobIntentService {
  private static final String TAG = "AWNmBackgroundService";
  static final int JOB_ID = 2021;


  private static final List<Intent> messagingQueue = Collections.synchronizedList(new LinkedList<>());

  /** Background Dart execution context. */
  private static AwesomeNotificationMessagingBackgroundExecutor flutterBackgroundExecutor;

  /**
   * Schedule the message to be handled by the {@link AwesomeNotificationMessagingBackgroundService}.
   */
  public static void enqueueMessageProcessing(Context context, Intent messageIntent) {
    enqueueWork(
        context,
        AwesomeNotificationMessagingBackgroundService.class,
        JOB_ID,
        messageIntent);
  }

  /**
   * Starts the background isolate for the {@link AwesomeNotificationMessagingBackgroundService}.
   *
   * <p>Preconditions:
   *
   * <ul>
   *   <li>The given {@code callbackHandle} must correspond to a registered Dart callback. If the
   *       handle does not resolve to a Dart callback then this method does nothing.
   *   <li>A static {@link #pluginRegistrantCallback} must exist, otherwise a {@link
   *       PluginRegistrantException} will be thrown.
   * </ul>
   */
  @SuppressWarnings("JavadocReference")
  public static void startBackgroundIsolate(long callbackHandle, FlutterShellArgs shellArgs) {
    if (flutterBackgroundExecutor != null) {
      Log.w(TAG, "Attempted to start a duplicate background isolate. Returning...");
      return;
    }
    System.out.println("Start background isolate");
    flutterBackgroundExecutor = new AwesomeNotificationMessagingBackgroundExecutor();
    flutterBackgroundExecutor.startBackgroundIsolate(callbackHandle, shellArgs);
  }

  /**
   * Called once the Dart isolate ({@code flutterBackgroundExecutor}) has finished initializing.
   *
   * <p>Invoked by {@link } when it receives the {@code
   * FirebaseMessaging.initialized} message. Processes all messaging events that came in while the
   * isolate was starting.
   */
  /* package */
  static void onInitialized() {
    Log.i(TAG, "AwesomeNotificationMessagingBackgroundService started!");
    synchronized (messagingQueue) {
      // Handle all the message events received before the Dart isolate was
      // initialized, then clear the queue.
      for (Intent intent : messagingQueue) {
        flutterBackgroundExecutor.executeDartCallbackInBackgroundIsolate(intent, null);
      }
      messagingQueue.clear();
    }
  }

  /**
   * Sets the Dart callback handle for the Dart method that is responsible for initializing the
   * background Dart isolate, preparing it to receive Dart callback tasks requests.
   */
  public static void setCallbackDispatcher(long callbackHandle) {
    AwesomeNotificationMessagingBackgroundExecutor.setCallbackDispatcher(callbackHandle);
  }

  /**
   * Sets the Dart callback handle for the users Dart handler that is responsible for handling
   * messaging events in the background.
   */
  public static void setUserCallbackHandle(long callbackHandle) {
    AwesomeNotificationMessagingBackgroundExecutor.setUserCallbackHandle(callbackHandle);
  }

  /**
   * Sets the {@link io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback} used to
   * register the plugins used by an application with the newly spawned background isolate.
   *
   * <p>This should be invoked in {@link MainApplication.onCreate} with {@link
   * GeneratedPluginRegistrant} in applications using the V1 embedding API in order to use other
   * plugins in the background isolate. For applications using the V2 embedding API, it is not
   * necessary to set a {@link io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback} as
   * plugins are registered automatically.
   */
  @SuppressWarnings({"deprecation", "JavadocReference"})
  public static void setPluginRegistrant(
      io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback callback) {
    // Indirectly set in FlutterFirebaseMessagingBackgroundExecutor for backwards compatibility.
    AwesomeNotificationMessagingBackgroundExecutor.setPluginRegistrant(callback);
  }

  @Override
  public void onCreate() {
    super.onCreate();
    System.out.println("ON CREATE awsome notification service");
    if (flutterBackgroundExecutor == null) {
      flutterBackgroundExecutor = new AwesomeNotificationMessagingBackgroundExecutor();
    }
    flutterBackgroundExecutor.startBackgroundIsolate();
  }

  /**
   * Executes a Dart callback, as specified within the incoming {@code intent}.
   *
   * <p>Invoked by our {@link JobIntentService} superclass after a call to {@link
   * JobIntentService#enqueueWork(Context, Class, int, Intent);}.
   *
   * <p>If there are no pre-existing callback execution requests, other than the incoming {@code
   * intent}, then the desired Dart callback is invoked immediately.
   *
   * <p>If there are any pre-existing callback requests that have yet to be executed, the incoming
   * {@code intent} is added to the {@link #messagingQueue} to be invoked later, after all
   * pre-existing callbacks have been executed.
   */
  @Override
  protected void onHandleWork(@NonNull final Intent intent) {
    if (!flutterBackgroundExecutor.isDartBackgroundHandlerRegistered()) {
      Log.w(
          TAG,
          "A background message could not be handled in Dart as no onBackgroundMessage handler has been registered.");
      return;
    }

    // If we're in the middle of processing queued messages, add the incoming
    // intent to the queue and return.
    synchronized (messagingQueue) {
      if (flutterBackgroundExecutor.isNotRunning()) {
        Log.i(TAG, "Service has not yet started, messages will be queued.");
        messagingQueue.add(intent);
        return;
      }
    }

    // There were no pre-existing callback requests. Execute the callback
    // specified by the incoming intent.
    final CountDownLatch latch = new CountDownLatch(1);
    new Handler(getMainLooper())
        .post(() -> flutterBackgroundExecutor.executeDartCallbackInBackgroundIsolate(intent, latch));

    try {
      latch.await();
    } catch (InterruptedException ex) {
      Log.i(TAG, "Exception waiting to execute Dart callback", ex);
    }
  }
}
