
# Awesome Notifications - Flutter

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications.jpg)



### Features

- Create **Local Notifications** on Android, iOS and Web using Flutter.
- Create **Push notifications** using services as **Firebase** or any another one, **simultaneously**;
- Easy to use and highly customizable.
- Add **images**, **sounds**, **buttons** and different layouts on your notifications.
- Notifications could be created at **any moment** (on Foreground, Background or even when the application is killed).
- **High trustble** on receive notifications in any Application lifecycle.
- High quality **data analytics** about when the notification was created, where it came from and when the user taps on it. A perfect solution to apply **AB tests** aproachings, etc, increasing the users engadgement.
- Notifications are received on **Flutter level code** when they are created, displayed or even tapped by the user.
- Notifications could be **scheduled** repeatly using **Cron rules**, such linux does, including seconds precision.

### Notification Types Available

- Basic notification
- Big picture notification
- Media notification
- Big Text notification
- Inbox notification
- Notifications with action buttons
- Grouped notifications
- Progress bar notifications

All notifications could be created localy or via Firebase services, with all the features.

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-example.jpg)

*Some examples of notifications produced using awesome notifications*

<br>

## ATENTION - PLUGIN UNDER CONSTRUCTION

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-atention.jpg)
![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-progress.jpg)
*Working progress percentages of awesome notifications plugin*

<br>

## Main Philosophy

Considering all the many different devices available, with different hardware and software resources, this plugin ALWAYS shows the notification, trying to use the maximum resources available. If the resource is not available, the notification ignores that specifc resource, but it shows anyway.

**Example**: If the device has LED colored lights, use it. Otherwise, ignore the lights, but shows the notification with all another resources available. In last case, shows at least the most basic notification.

Also, the Noification Channels follows the same rule. If there is no channel segregation of notifications, use the channel configuration as only defaults configuration. If the device has channels, use it as expected to be.

And all notifications sent while the app was killed are registered and delivered as soon as possible to the Application, after the plugin initialziation, respecting the delivery order.

This way, your Application will receive **all notifications at Flutter level code**.

<br>

## A very simple example

<br>
1. Add *awesome_notifications* as a dependency in your pubspec.yaml file.

		awesome_notifications: any

2. import the plugin package to your dart code

		import 'package:awesome_notifications/awesome_notifications.dart';

3. Initialize the plugin on main.dart, with at least one native icon and one channel
        
		AwesomeNotifications().initialize(
			'resource://drawable/app_icon',
			[
				NotificationChannel(
					channelKey: 'basic_channel',
					channelName: 'Basic notifications',
					channelDescription: 'Notification channel for basic tests',
					defaultColor: Color(0xFF9D50DD),
					ledColor: Colors.white
				)
			]
         );

4. On your main page, starts to listen the notification actions (to detect tap)
        
		AwesomeNotifications().actionNotificationStream.listen(
			(receivedNotification){

				Navigator.of(context).pushName(context,
					'/NotificationPage',
					arguments: { id: receivedNotification.id } // your page params. I recomend to you to pass all *receivedNotification* object
				);

			}
		);

5. In any place of your app, create a new notification

		  AwesomeNotifications().createNotification(
			  content: NotificationContent(
				  id: 10,
				  channelKey: 'basic_channel',
				  title: 'Simple Notification',
				  body: 'Simple body'
			  )
		  );

**THATS IT! CONGRATZ MY FRIEND!!!**

<br>

## Using Firebase Services (Optional)

To activate the Firebase Cloud Messaging service, please follow these steps:

### Android

First things first, to create your Firebase Cloud Message and send notifications even when your app is terminated (killed), go to the [[Firebase Console]][firebase_link] and create a new project.

After that, go to "Cloud Messaging" option and add an "Android app", put the packge name of your project (**certifies to put the correct one**) to generate the file ***google-services.json***.

Download the file and place it inside your android/app folder.

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/google-json-path.jpg)

Add the classpath to the [project]/android/build.gradle file. (Firebase ones was already added by the plugin)

	dependencies {
		classpath 'com.android.tools.build:gradle:3.5.0'
		// Add the google services classpath
		classpath 'com.google.gms:google-services:4.3.3'
	}

Add the apply plugin to the [project]/android/app/build.gradle file.

	// ADD THIS AT THE BOTTOM
	apply plugin: 'com.google.gms.google-services'


### iOS

In construction... 

I will deploy the other platforms as soon as possible. Im doing all by my own, with a lack of resources.
Please, be patient.

<br>

## Firebase Token

The firebase token is necessary to your sever send Push Notifications to the remote device. The token could eventualy change and is created to every device instalation on each application.

Every token created could be captured on Flutter by this plugin listen to ``

<br>

## Notification Life Cycle

Notifications are received by local code or FCM using native code, so the messages will appears immediately or at schedule time, independent of your application state.

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/notification-life-cycle.jpeg)

<br>

## Flutter Streams

The Flutter code will be called as soon as possible using [[Streams]][stream_dart].

**createdNotificationStream**: Fires when a notification is created
**displayedNotificationStream**: Fires when a notification is displayed on system status bar
**actionNotificationStream**: Fires when a notification is tapped by the user

<br>

|                             | App in Foreground | App in Background | App Terminated (Killed) |
| --------------------------: | ----------------- | ----------------- | -------------- |
| **Android** | Fires all streams imeadtly after occours | Fires all streams imeadtly after occours | Fires `created` and `displayed` after the plugin initializes, but fires `action` imeadtly after occours |
| **iOS**     | Fires all streams imeadtly after occours | Fires all streams imeadtly after occours | Fires `created` and `displayed` after the plugin initializes, but fires `action` imeadtly after occours |

<br>


## FCM data example

To send a notification using Awesome Notifications, use only the data field.

		{
			"to" : "[YOUR APP TOKEN]",
			"collapse_key" : "type_a",
			"data" : {
				"content": {
					"id": 100,
					"channelKey": "big_picture",
					"title": "Huston!\nThe eagle has landed!",
					"body": "A small step for a man, but a giant leap to Flutter's community!",
					"notificationLayout": "BigPicture",
					"largeIcon": "https://avidabloga.files.wordpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg",
					"bigPicture": "https://www.dw.com/image/49519617_303.jpg",
					"showWhen": true,
					"autoCancel": true,
					"privacy": "Private"
				},
				"actionButtons": [  /* OPTIONAL */
					{
						"key": "REPLY",
						"label": "Reply",
						"autoCancel": true,
						"buttonType":  "InputField",
					},
					{
						"key": "ARCHIVE",
						"label": "Archive",
						"autoCancel": true
					}
				],
				"schedule": [  /* OPTIONAL */
					"initialDateTime": "2020-08-30 11:00:00",
					"crontabSchedule": "5 38 20 ? * MON-FRI *"
				],
			}
		}

Read me construction in progress... please be patient
[firebase_link]: https://console.firebase.google.com/ "Firebase Console"
[stream_dart]: https://dart.dev/tutorials/language/streams "Streams"