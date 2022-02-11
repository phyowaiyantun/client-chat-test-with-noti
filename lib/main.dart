import 'dart:convert';

import 'package:admin_to_client_chat_app/utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

// ? Notification background handler
Future<void> backgroundnotiHandler(RemoteMessage message) async {
  // IconicLoalNotificationService.display(message);
  print(message.data);
  print("+++++++++++++++");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backgroundnotiHandler);
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

  final GlobalKey webViewKey = GlobalKey();

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
        print("hi");
        IconicLoalNotificationService.display(message);
      });
    } else {
      print('prmission denied');
    }
  }

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
      ),
      android: AndroidInAppWebViewOptions(
        allowFileAccess: true,
        allowContentAccess: true,
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

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
      print('object');
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
      Navigator.of(context).pushNamed(routeFromMessage);
    });

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.green,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FCM Test")),
      body: buildaddProduct(context),
    );
  }

  @override
  Widget buildaddProduct(BuildContext context) {
    return SafeArea(
      child: ScreenUtilInit(
        builder: () => WillPopScope(
          onWillPop: () async {
            if (await webViewController!.canGoBack()) {
              webViewController!.goBack();
              return false;
            } else {
              return true;
            }
          },
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                        url: Uri.parse("https://phyo.iconicmyanmar.com/"),
                      ),
                      initialOptions: options,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      androidOnPermissionRequest:
                          (controller, origin, resources) async {
                        return PermissionRequestResponse(
                            resources: resources,
                            action: PermissionRequestResponseAction.GRANT);
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;

                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          if (await canLaunch(url)) {
                            // Launch the App
                            await launch(
                              url,
                            );
                            // and cancel the request
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onLoadError: (controller, url, code, message) {
                        pullToRefreshController.endRefreshing();
                        setState(() {});
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          pullToRefreshController.endRefreshing();
                        }
                        setState(() {
                          this.progress = progress / 100;
                          urlController.text = this.url;
                        });
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        print(consoleMessage);
                      },
                    ),
                    progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container(),
                  ],
                ),
              ),
              // ButtonBar(
              //   alignment: MainAxisAlignment.center,
              //   children: <Widget>[
              //     ElevatedButton(
              //       child: Icon(Icons.arrow_back),
              //       onPressed: () {
              //         webViewController?.goBack();
              //       },
              //     ),
              //     ElevatedButton(
              //       child: Icon(Icons.arrow_forward),
              //       onPressed: () {
              //         webViewController?.goForward();
              //       },
              //     ),
              //     ElevatedButton(
              //       child: Icon(Icons.refresh),
              //       onPressed: () {
              //         webViewController?.reload();
              //       },
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
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
      print(".....");
      print(message.data);
      String channel = message.data['default_channel'];
      final bigPicturePath =
          await Utils.downloadFile(message.data['big_pic'], 'bigPicture');
      final largeIconPath =
          await Utils.downloadFile(message.data['icon'], 'largeIcon');

      final styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        largeIcon: FilePathAndroidBitmap(largeIconPath),
        contentTitle: 'Testing',
        summaryText: 'symmaryTest',
      );
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "general-noti",
          // channel,
          "General Notifications",
          channelDescription: "This channel is for general notifications.",
          importance: Importance.high,
          priority: Priority.high,
          ticker: "ticker",
          // sound: RawResourceAndroidNotificationSound('default'),
          playSound: true,
          styleInformation: styleInformation,
        ),
      );
      await _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data['routePath'],
      );
    } on Exception catch (e) {
      print(e);
    }
  }
}
