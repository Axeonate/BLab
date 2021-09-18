import 'package:blab/pages/home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService{
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =FlutterLocalNotificationsPlugin();

  static void initialize(){
    final InitializationSettings initializationSettings =
    InitializationSettings(android: AndroidInitializationSettings("@mipmap/ic_launcher"));
    _notificationsPlugin.initialize(initializationSettings,onSelectNotification: (String? route)async{
      if(route!=null)
        {
          globalUrl=route;
        webViewController?.loadUrl(
              urlRequest: URLRequest(
                  url: Uri.parse(
                      route)));
        }
    });
  }
  static void display(RemoteMessage message)async{
    try {
      final id=DateTime.now().millisecondsSinceEpoch~/1000;
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "blab",
          "blab channel",
          "this is blab official channel",
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true
        )
      );
      await _notificationsPlugin.show(
          id,
          message.notification!.title,
          message.notification!.body,
          notificationDetails,
        payload: message.data["route"]
      );
    } on Exception catch (e) {
     print(e);
    }
  }

}