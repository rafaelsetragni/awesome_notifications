
# Awesome Notifications - Flutter

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications.jpg)



### Features

- Create **Local Notifications** on Android, iOS and Web using Flutter.
- Create **Push notifications** using services as **Firebase** or any another one, **simultaneously**;
- Easy to use and highly customizable.
- Add **images**, **sounds**, **buttons** and different layouts on your notifications.
- Notifications could be created at **any moment** (on Foreground, Background or even when the application is killed).
- **High trustble** on receive notifications in any Application lifecycle.
- High quality **analytics data** to use on AB tests, etc.


![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-example.jpg)

**Some examples**

##ATENTION

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-atention.jpg)
![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-progress.jpg)

##Main Philosophy

Considering all the many different devices available, with different hardware and software resources, this plugin ALWAYS shows the notification, trying to use the maximum resources available. If the resource is not available, the notification ignores that specifc resource, but it shows anyway.

**Example**: If the device has LED colored lights, use it. Otherwise, ignore the lights, but shows the notification with all another resources. In last case, shows a most basic notification.

If the device does not have channels, ignore it and use as predefined configurations. If the device has channels, use it as i should be.

And all notifications sent while the app was killed are registered and delivered as soon as possible to the Application, after the plugin initialziation, respecting the delivery order.

This way, your Application will receive **all notifications at Flutter level code**.

##A very simple example


1. Add the plugin on your pubspec.yaml

		awesome_notifications: any

2. import the plugin package on your dart code

		import 'package:awesome_notifications/awesome_notifications.dart';

3. Initialize the plugin on main file, with at least one native icon and one channel
        
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

4. On your first page, starts to listen the notification actions (to detect tap)


		AwesomeNotifications().actionNotificationStream.listen(
			(receivedNotification){

				Navigator.of(context).pushName(context,
					'/NotificationPage',
					arguments: { id: receivedNotification.id } // your page params. I recomend to you to pass all *receivedNotification* object
				);

			}
		);

5. On your first page, starts to listen the notification actions (to detect tap)

		  AwesomeNotifications().createNotification(
			  content: NotificationContent(
				  id: 10,
				  channelKey: 'basic_channel',
				  title: 'Simple Notification',
				  body: 'Simple body'
			  )
		  );


**THATS IT! CONGRATZ!**

Read me construction in progress... please be patient