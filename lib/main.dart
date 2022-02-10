import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
      ),
      home: myHomePage(),
    );
  }
}

class myHomePage extends StatefulWidget {
  const myHomePage({Key? key}) : super(key: key);

  @override
  _myHomePageState createState() => _myHomePageState();
}

class _myHomePageState extends State<myHomePage> {
  late FirebaseMessaging firebaseMessaging;
  // state api url
  final stateUrl = "http://10.0.2.2:7979/api/save-my-token";

  late String noti_token;

  void apiSaveData() async {
    var send = await http.post(
      Uri.parse(stateUrl),
      headers: {
        'User': 'phyo',
        'Authentication': 'asd123!',
      },
      body: {
        'device_name': 'phyo',
        'device_token': noti_token,
      },
    );

    // var decodedData = json.decode(send.body);
    print(send.body);
  }

  // ? Register Notification
  void registerNotification() async {
    // * instance for firebase messaging
    firebaseMessaging = FirebaseMessaging.instance;
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      provisional: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted");
      // ? main message
      FirebaseMessaging.onMessage.listen((message) {
        if (message != null) {
          print(message.notification!.title);
          print(message.notification!.body);
          print(message.data);
        }
        IconicLoalNotificationService.display(message);
      });
    } else {
      print('prmission denied');
    }
  }

  @override
  void initState() {
    super.initState();
    firebaseMessaging = FirebaseMessaging.instance;
    firebaseMessaging.getToken().then(
      (value) {
        print('my token: $value');
        setState(
          () {
            if (value != null) {
              noti_token = value;
              // apiSaveData();
            }
          },
        );
      },
    );
    IconicLoalNotificationService.initilalize(context);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final routeFromMessage = message.data["routePath"];
        Navigator.of(context).pushNamed(routeFromMessage);
      }
    });
    // * foreground
    registerNotification();
    // * app in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final routeFromMessage = message.data["routePath"];
      print(routeFromMessage);
      Navigator.of(context).pushNamed(routeFromMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello World'),
      ),
    );
  }
}

class IconicLoalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static initilalize(BuildContext context) {
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/ic_launcher"));
    _notificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? route) async {
      print(route);
      // if (route != null) {
      //   Navigator.of(context).pushNamed(route);
      // }
    });
  }

  static void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "general-noti",
          "General Notifications",
          channelDescription: "This channel is for general notifications.",
          importance: Importance.max,
          priority: Priority.high,
          ticker: "ticker",
          // sound: RawResourceAndroidNotificationSound('default'),
          playSound: true,
        ),
      );
      await _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data['routePath'],
      );
      print(message);
    } on Exception catch (e) {
      print(e);
    }
  }
}
