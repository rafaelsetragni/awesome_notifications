---
title: 👮‍♀️ Requesting Permissions
# description: Quidem magni aut exercitationem maxime rerum eos.
---

Permissions give transparency to the user of what you pretend to do with your app while its in use. To show any notification on device, you must obtain the user consent and keep in mind that this consent can be revoke at any time, in any platform. On Android, the basic permissions are always conceived to any new installed app, but for iOS, even the basic permission must be requested to the user.

The permissions can be defined in 3 types:

- **Normal permissions**: Are permissions not considered dangerous and do not require the explicit user consent to be enabled.
- **Execution permissions**: Are permissions considered more sensible to the user and you must obtain his explicit consent to use.
- **Special/Dangerous permissions**: Are permissions that can harm the user experience or his privacy and you must obtain his explicit consent and, depending of what platform are you running, you must obtain permission from the manufacture itself to use it.

As a good pratice, consider always to check if the permissions that you're desiring are conceived before create any new notification, independent of platform. To check if the permissions needs the explicity user consent, call the method shouldShowRationaleToRequest. The list of permissions that needs a rationale to the user can be different between platforms and O.S. versions. And if you app does not require extremely the permission to execute what you need, consider to not request the user permission and respect his will.

---

## Permissions:

### Alert

Alerts are notifications with high priority that pops up on the user screen. Notifications with normal priority only shows the icon on status bar.

### Sound

Sound allows the ability to play sounds for new displayed notifications. The notification sounds are limited to a few seconds and if you pretend to play a sound for more time, you must consider to play a background sound to do it simultaneously with the notification.

### Badge

Badge is the ability to display a badge alert over the app icon to alert the user about updates. The badges can be displayed on numbers or small dots, depending of platform or what the user defined in the device settings. Both Android and iOS can show numbers on badge, depending of its version and distribution.

### Light

The ability to display colorful small lights, blanking on the device while the screen is off to alert the user about updates. Only a few Android devices have this feature.

### Vibration

The ability to vibrate the device to alert the user about updates.

### FullScreenIntent

The ability to show the notifications on pop up even if the user is using another app.

### PreciseAlarms

Precise alarms allows the scheduled notifications to be displayed at the expected time. This permission can be revoke by special device modes, such as battery save mode, etc. Some manufactures can disable this feature if they decide that your app is consumpting many computational resources and decressing the baterry life (and without changing the permission status for your app). So, you must take in consideration that some schedules can be delayed or even not being displayed, depending of what platform are you running. You can increase the chances to display the notification at correct time, enable this permission and setting the correct notification category, but you never gonna have 100% sure about it.

### CriticalAlert

Critical alerts is a special permission that allows to play sounds and vibrate for new notifications displayed, even if the device is in Do Not Disturb / Silent mode. For iOS, you must request Apple a authorization to your app use it.

### OverrideDnD

Override DnD allows the notification to decrease the Do Not Disturb / Silent mode level enable to display critical alerts for Alarm and Call notifications. For Android, you must require the user consent to use it. For iOS, this permission is always enabled with CriticalAlert.

### Provisional

(Only has effect on iOS) The ability to display notifications temporarily without the user consent.

### Car

The ability to display notifications while the device is in car mode.

---

{% callout type="note" title="Note " %}
If none permission is requested through `requestPermissionToSendNotifications` method, the standard permissions requested are Alert, Badge, Sound, Vibrate and Light.
{% /callout %}

---

## Notification's Permission Level

A permission can be segregated in 3 different levels:

![image](https://user-images.githubusercontent.com/40064496/143137760-32b99fad-5827-4d0e-9d4f-c39c82ca6bfd.png)

- **Device level:** The permissions set at the global device configuration are applicable at any app installed on device, such as disable/enable all notifications, battery save mode / low power mode and silent / do not disturb mode.
- **Application level:** The permissions set at the global app configurations are applicable to any notification in any channel.
- **Channel level:** The permissions set on the channel has effect only for notifications displayed through that specific channel.

---

## Full example on how to request permissions

Below is a complete example of how to check if the desired permission is enabled and how to request it by showing a dialog with a rationale if necessary (this example is taken from our sample app):

```dart
static Future<List<NotificationPermission>> requestUserPermissions(
    BuildContext context,{
    // if you only intends to request the permissions until app level, set the channelKey value to null
    required String? channelKey,
    required List<NotificationPermission> permissionList}
  ) async {

  // Check if the basic permission was conceived by the user
  if(!await requestBasicPermissionToSendNotifications(context)) {
    return [];
  }

  // Check which of the permissions you need are allowed at this time
  List<NotificationPermission> permissionsAllowed = await AwesomeNotifications().checkPermissionList(
      channelKey: channelKey,
      permissions: permissionList
  );

  // If all permissions are allowed, there is nothing to do
  if(permissionsAllowed.length == permissionList.length) {
    return permissionsAllowed;
  }

  // Refresh the permission list with only the disallowed permissions
  var permissionsNeeded =
    permissionList.toSet().difference(permissionsAllowed.toSet()).toList();

  // Check if some of the permissions needed request user's intervention to be enabled
  List<NotificationPermission> lockedPermissions = await AwesomeNotifications().shouldShowRationaleToRequest(
      channelKey: channelKey,
      permissions: permissionsNeeded
  );

  // If there is no permissions depending on user's intervention, so request it directly
  if(lockedPermissions.isEmpty){

    // Request the permission through native resources.
    await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: channelKey,
        permissions: permissionsNeeded
    );

    // After the user come back, check if the permissions has successfully enabled
    permissionsAllowed = await AwesomeNotifications().checkPermissionList(
        channelKey: channelKey,
        permissions: permissionsNeeded
    );
  }
  else {
    // If you need to show a rationale to educate the user to conceived the permission, show it
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xfffbfbfb),
          title: Text('Awesome Notifications needs your permission',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/animated-clock.gif',
                height: MediaQuery.of(context).size.height * 0.3,
                fit: BoxFit.fitWidth,
              ),
              Text(
                'To proceed, you need to enable the permissions above'+
                    (channelKey?.isEmpty ?? true ? '' : ' on channel $channelKey')+':',
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
              Text(
                lockedPermissions.join(', ').replaceAll('NotificationPermission.', ''),
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: (){ Navigator.pop(context); },
                child: Text(
                  'Deny',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                )
            ),
            TextButton(
              onPressed: () async {

                // Request the permission through native resources. Only one page redirection is done at this point.
                await AwesomeNotifications().requestPermissionToSendNotifications(
                    channelKey: channelKey,
                    permissions: lockedPermissions
                );

                // After the user come back, check if the permissions has successfully enabled
                permissionsAllowed = await AwesomeNotifications().checkPermissionList(
                    channelKey: channelKey,
                    permissions: lockedPermissions
                );

                Navigator.pop(context);
              },
              child: Text(
                'Allow',
                style: TextStyle(color: Colors.deepPurple, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        )
    );
  }

  // Return the updated list of allowed permissions
  return permissionsAllowed;
}
```
