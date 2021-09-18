import 'dart:io';
import 'package:blab/pages/local_notification_service.dart';
import 'package:blab/pages/providers/connectivity_provider.dart';
import 'package:blab/pages/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';

Future<void>backGroundHandler(RemoteMessage message)async{
  print(message.data.toString());
  print(message.notification!.title);
}

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  // await Permission.camera.request();
  // await Permission.microphone.request();
  // await Permission.storage.request();
  LocalNotificationService.initialize();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backGroundHandler);

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

    var swAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
    var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

    if (swAvailable && swInterceptAvailable) {
      AndroidServiceWorkerController serviceWorkerController =
      AndroidServiceWorkerController.instance();

      serviceWorkerController.serviceWorkerClient = AndroidServiceWorkerClient(
        shouldInterceptRequest: (request) async {
          print(request);
          return null;
        },
      );
    }
  }
  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
        ChangeNotifierProvider(create: (context)=> ConnectivityProvider(),
          child: SplashScreen(),
        ),
      ],
        child: MaterialApp(
          title: 'Official blab mobile application',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            //   primaryColor: Color(0xFF1a1b1c), // for dark theme
            primaryColor: Color(0xFFffffff), //for light theme
            accentColor: Color(0xFF237b9e),
            fontFamily: "RobotoMono",
          ),
          home: SplashScreen(),
        ),
      );

  }
}