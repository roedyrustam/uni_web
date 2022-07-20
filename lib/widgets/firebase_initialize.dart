import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uni_web/helpers/Constant.dart';

import '../main.dart';

class FirebaseInitialize {
  static void initFirebaseState() async {
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    Future<void> generateSimpleNotication(String title, String msg) async {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        playSound: true,
        icon: notificationIcon,
      );
      var iosDetail = IOSNotificationDetails();

      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics, iOS: iosDetail);
      await flutterLocalNotificationsPlugin.show(
          0, title, msg, platformChannelSpecifics);
    }

    // Future<String> _downloadAndSaveImage(String url, String fileName) async {
    //   var directory = await getApplicationDocumentsDirectory();
    //   var filePath = '${directory.path}/$fileName';
    //   var response = await http.get(Uri.parse(url));

    //   var file = File(filePath);
    //   await file.writeAsBytes(response.bodyBytes);
    //   return filePath;
    // }

    Future<void> generateImageNotication(
        String title, String msg, String image) async {
      // var largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
      // var bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
      var bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(image),
          hideExpandedLargeIcon: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: msg,
          htmlFormatSummaryText: true);
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          channel.id, channel.name,
          channelDescription: channel.description,
          playSound: true,
          icon: notificationIcon,
          largeIcon: FilePathAndroidBitmap(image),
          styleInformation: bigPictureStyleInformation);

      var platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        msg,
        platformChannelSpecifics,
      );
    }

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('messgae1 $message.data');
      }
    });

    _firebaseMessaging.getToken().then((value) {});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('received----${message.data}');

      var title = message.data['title'];
      var body = message.data['message'];
      var image = message.data['image'] ?? '';
      if (image != null && image != 'null' && image != '') {
        generateImageNotication(title, body, image);
      } else {
        generateSimpleNotication(title, body);
      }
      // RemoteNotification notification = message.notification!;
      // AndroidNotification android = message.notification!.android!;
      // if (notification != null &&
      //     android != null &&
      //     message.data["user_id"]
      //         .toString()
      //         .split(',')
      //         .contains(getIntData(sessionUserId).toString())) {
      //   flutterLocalNotificationsPlugin.show(
      //       notification.hashCode,
      //       notification.title,
      //       notification.body,
      //       NotificationDetails(
      //           android: AndroidNotificationDetails(
      //             channel.id,
      //             channel.name,
      //             channelDescription: channel.description,
      //             color: Colors.blue,
      //             playSound: true,
      //             icon: notificationIcon,
      //           ),
      //           iOS: const IOSNotificationDetails()),
      //       payload: message.data['message']);
      // }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(message.data);
    });
  }
}
