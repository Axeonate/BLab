import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui';
import 'package:blab/pages/local_notification_service.dart';
import 'package:blab/pages/no_internet.dart';
import 'package:blab/pages/providers/connectivity_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}
InAppWebViewController? webViewController;
String globalUrl = "https://blab.lk";
class _HomePageState extends State<HomePage> {
  String selectedNav = "init";
  bool navBarHidden = false;
  final GlobalKey webViewKey = GlobalKey();
  late PullToRefreshController pullToRefreshController;
  double progress = 0;
  final urlController = TextEditingController();
  int yAxis=0;
  late Timer _timer;
  final Stream<QuerySnapshot> maintainStream = FirebaseFirestore.instance.collection('blab').snapshots();
  RateMyApp _rateMyApp = RateMyApp (
    preferencesPrefix: 'rateMyApp_pro',
    minDays: 2,
    minLaunches: 5,
    remindDays: 2,
    remindLaunches: 1,
    appStoreIdentifier:'lk.mobileapp.blab',
    googlePlayIdentifier:'lk.mobileapp.blab'
  );

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowFileAccessFromFileURLs: true,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        allowFileAccess: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      setState(() {
        progress = 0;
      });
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> getPermissions() async {
    var statusLocation = await Permission.location.status;
    var statusStorage = await Permission.storage.status;

    if (statusLocation.isDenied) {
      showCupertinoDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: new Text("Location access needed"),
              content: new Text(
                  "Please accept the Location access for post sharing"),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text("Ok"),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (await Permission.location.request().isGranted) {
                      getPermissions();
                    }
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  isDestructiveAction: true,
                  child: Text("Cancel"),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
    } else if (statusStorage.isDenied) {
      showCupertinoDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: new Text("Storage access needed"),
              content:
                  new Text("Please accept the Storage access for post sharing"),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text("Ok"),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (await Permission.storage.request().isGranted) {
                      getPermissions();
                    }
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  isDestructiveAction: true,
                  child: Text("Cancel"),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
    }
  }
  void startTimerNavHide() {
    _timer= Timer(Duration(seconds: 3), () {
      if (navBarHidden!=true) {
        setState(() {
          navBarHidden=true;
        });
        _timer.cancel();
      }
      else
        {
          _timer.cancel();
        }
    });
  }
  void initFcmMessages(){
    FirebaseMessaging.instance.getInitialMessage().then((message){
      if(message!=null && message.data["route"]!=null){
        final rouFromMessage = message.data["route"];
        print(rouFromMessage);
        webViewController?.loadUrl(
            urlRequest: URLRequest(
                url: Uri.parse(
                    message.data["route"])));
      }
    });
    FirebaseMessaging.onMessage.listen((message) {
      if(message.notification!=null)
      {
        print(message.notification!.title);
        print(message.notification!.body);
      }
      LocalNotificationService.display(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final rouFromMessage = message.data["route"];
      print(rouFromMessage);
      webViewController?.loadUrl(
          urlRequest: URLRequest(
              url: Uri.parse(
                  message.data["route"])));
    });
  }

  @override
  void initState() {
    super.initState();
    Provider.of<ConnectivityProvider>(context, listen: false).startMonitoring();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.black,
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
    initFcmMessages();
    _rateMyApp.init().then((_){
      if(_rateMyApp.shouldOpenDialog){ //conditions check if user already rated the app
        _rateMyApp.showStarRateDialog(
          context,
          title: 'What do you think about BLab App?',
          message: 'Did you enjoy BLab? please leave your comment. your rating is our guider...',
          actionsBuilder: (_, stars){
            return [ // Returns a list of actions (that will be shown at the bottom of the dialog).
              FlatButton(
                child: Text('NOT NOW'),
                onPressed: ()  async {
                  Navigator.pop<RateMyAppDialogButton>(context, RateMyAppDialogButton.rate);
                },
              ),
              FlatButton(
                child: Text('SUBMIT'),
                onPressed: stars!=0? () async {
                  print('Thanks for the ' + (stars == null ? '0' : stars.round().toString()) + ' star(s) !');
                  if(stars != null && (stars == 4 || stars == 5)){
                    //if the user stars is equal to 4 or five
                    // you can redirect the use to playstore or appstore to enter their reviews
                    _rateMyApp.launchStore();
                    await _rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
                    Navigator.pop<RateMyAppDialogButton>(context, RateMyAppDialogButton.rate);
                  } else {
                    // else you can redirect the user to a page in your app to tell you how you can make the app better
                    await _rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
                    Navigator.pop<RateMyAppDialogButton>(context, RateMyAppDialogButton.rate);
                    // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => CustomerRatings(uid: user.uid,)));
                  }
                  // You can handle the result as you want (for instance if the user puts 1 star then open your contact page, if he puts more then open the store page, etc...).
                  // This allows to mimic the behavior of the default "Rate" button. See "Advanced > Broadcasting events" for more information :

                }:null,
              ),
            ];
          },
          dialogStyle: DialogStyle(
            titleAlign: TextAlign.center,
            messageAlign: TextAlign.center,
            messageStyle: TextStyle(fontFamily: 'Poppins',fontSize: 12),
            messagePadding: EdgeInsets.only(bottom: 20.0),
          ),
          starRatingOptions: StarRatingOptions(initialRating: 4,itemColor: Color(0xFF000000),borderColor: Color(0xFF1FAFAD)),
          onDismissed: () => _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset:
      //     globalUrl == "https://blab.lk/password-recover/" ||
      //             globalUrl == 'https://blab.lk/message-us/' ||
      //             globalUrl == 'https://blab.lk/register/' ||
      //             globalUrl.contains('https://blab.lk/profile/')
      //         ? true
      //         : false,
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text(
            'Tap back again to leave',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        child: SafeArea(child: Consumer<ConnectivityProvider>(
          builder: (context, model, child) {
            if (model.isOnline != null) {
              return model.isOnline
                  ?StreamBuilder(
                //message stream
                  stream: maintainStream,
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData){
                      return Center(
                        child: Container(
                          color: Color(0xffffffff),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SpinKitWave(
                                color: Color(0xFF393d3a),
                                size: 20.0,
                                duration: Duration(milliseconds: 1000),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    else if(snapshot.data!.docs[0]['available']==true)
                    {
                      return Container(
                          child: Stack(
                            children: <Widget>[
                              ConstrainedBox(
                                constraints: const BoxConstraints.expand(),
                                child: InAppWebView(
                                  key: webViewKey,
                                  initialUrlRequest:
                                  URLRequest(url: Uri.parse('https://blab.lk')),
                                  onScrollChanged: (controller,x,y){
                                    // if(y<yAxis)
                                    // {
                                    //   if(navBarHidden==false)
                                    //   {
                                    //     setState(() {
                                    //       navBarHidden=true;
                                    //     });
                                    //   }
                                    // }
                                    // else
                                    // {
                                    //   if(navBarHidden==true)
                                    //   {
                                    //     setState(() {
                                    //       navBarHidden=false;
                                    //     });
                                    //     startTimerNavHide();
                                    //   }
                                    //
                                    // }
                                    if(navBarHidden==true)
                                    {
                                      setState(() {
                                        navBarHidden=false;
                                      });
                                      startTimerNavHide();
                                    }
                                    yAxis=y;
                                  },
                                  initialUserScripts:
                                  UnmodifiableListView<UserScript>([]),
                                  initialOptions: options,
                                  pullToRefreshController: pullToRefreshController,
                                  onWebViewCreated: (controller) {
                                    webViewController = controller;
                                  },
                                  onLoadStart: (controller, url) {
                                    setState(() {
                                      globalUrl = url.toString();
                                      urlController.text =globalUrl;
                                      selectedNav==""||selectedNav=="init"?selectedNav="other":selectedNav=selectedNav;
                                    });
                                  },
                                  androidOnPermissionRequest:
                                      (controller, origin, resources) async {
                                    return PermissionRequestResponse(
                                        resources: resources,
                                        action:
                                        PermissionRequestResponseAction.GRANT);
                                  },
                                  shouldOverrideUrlLoading:
                                      (controller, navigationAction) async {
                                    var uri = navigationAction.request.url!;
                                    if (uri.toString().contains("https://blab.lk/") &&
                                        !uri.toString().contains("pdf")) {
                                      return NavigationActionPolicy.ALLOW;
                                    } else {
                                      _launchURL(uri.toString());
                                      return NavigationActionPolicy.CANCEL;
                                    }
                                    // if (![
                                    //   "http",
                                    //   "https",
                                    //   "file",
                                    //   "chrome",
                                    //   "data",
                                    //   "javascript",
                                    //   "about"
                                    // ].contains(uri.scheme)) {
                                    //   if (await canLaunch(url)) {
                                    //     // Launch the App
                                    //     await launch(
                                    //       url,
                                    //     );
                                    //     // and cancel the request
                                    //     return NavigationActionPolicy.CANCEL;
                                    //   }
                                    // }
                                    //
                                    // return NavigationActionPolicy.ALLOW;
                                  },
                                  onLoadStop: (controller, url) async {
                                    pullToRefreshController.endRefreshing();
                                    setState(() {
                                      globalUrl = url.toString();
                                      urlController.text = globalUrl;
                                    });
                                    startTimerNavHide();
                                  },
                                  onLoadError: (controller, url, code, message) {
                                    pullToRefreshController.endRefreshing();
                                  },
                                  onProgressChanged: (controller, progress) {
                                    if (progress == 100) {
                                      pullToRefreshController.endRefreshing();
                                    }
                                    setState(() {
                                      this.progress = progress / 100;
                                      urlController.text = globalUrl;
                                    });
                                  },
                                  onUpdateVisitedHistory:
                                      (controller, url, androidIsReload) {
                                    setState(() {
                                      globalUrl = url.toString();
                                      urlController.text = globalUrl;
                                    });
                                  },
                                  onConsoleMessage: (controller, consoleMessage) {
                                    print(consoleMessage);
                                  },
                                ),
                              ),
                              globalUrl == "" ||
                                  globalUrl.contains("https://blab.lk/home-page/")||
                                  globalUrl.contains("https://blab.lk/home") ||
                                  globalUrl.contains("blab.lk/home")
                                  ? Container()
                                  : globalUrl == "https://blab.lk/" ||
                                  globalUrl == "https://blab.lk/#"
                                  ? Positioned(
                                bottom: 0,
                                height: 70,
                                width: MediaQuery.of(context).size.width,
                                child: Visibility(
                                  visible: navBarHidden?false:true,
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        left: MediaQuery.of(context)
                                            .size
                                            .width /
                                            100 *
                                            6,
                                        right: MediaQuery.of(context)
                                            .size
                                            .width /
                                            100 *
                                            6,
                                        top: 10,
                                        bottom: 5),
                                    decoration: BoxDecoration(
                                        color: Color(0xffffffff),
                                        borderRadius:
                                        BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(blurRadius: 2)
                                        ]),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        //home
                                        Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  globalUrl =
                                                  "https://blab.lk/";
                                                  webViewController?.loadUrl(
                                                      urlRequest: URLRequest(
                                                          url: Uri.parse(
                                                              "https://blab.lk/")));
                                                });
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  color:
                                                  Color(0xfff1f1f1),
                                                ),
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets
                                                      .all(4.0),
                                                  child: Icon(
                                                      CupertinoIcons.home,
                                                      size: 30,
                                                      color: Color(
                                                          0xFF1FAFAD)),
                                                ),
                                              ),
                                            ),
                                            Text("Home",
                                                style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                        context)
                                                        .size
                                                        .width /
                                                        100 *
                                                        2.5))
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                              .size
                                              .width /
                                              100 *
                                              10,
                                        ),

                                        //profile
                                        Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (globalUrl !=
                                                    "https://blab.lk/profile/") {
                                                  setState(() {
                                                    globalUrl =
                                                    "https://blab.lk/profile/";
                                                    webViewController?.loadUrl(
                                                        urlRequest: URLRequest(
                                                            url: Uri.parse(
                                                                "https://blab.lk/profile/")));
                                                    selectedNav =
                                                    "Profile";
                                                  });
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  color:
                                                  Color(0xfff1f1f1),
                                                ),
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets
                                                      .all(4.0),
                                                  child: Icon(
                                                      CupertinoIcons
                                                          .profile_circled,
                                                      size: 30,
                                                      color: Color(
                                                          0xFF1FAFAD)),
                                                ),
                                              ),
                                            ),
                                            Text("Profile",
                                                style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                        context)
                                                        .size
                                                        .width /
                                                        100 *
                                                        2.5))
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                              .size
                                              .width /
                                              100 *
                                              10,
                                        ),

                                        //message
                                        Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (globalUrl !=
                                                    "https://blab.lk/messages/") {
                                                  setState(() {
                                                    globalUrl =
                                                    "https://blab.lk/messages/";
                                                    webViewController?.loadUrl(
                                                        urlRequest: URLRequest(
                                                            url: Uri.parse(
                                                                "https://blab.lk/messages/")));
                                                    selectedNav =
                                                    "Messages";
                                                  });
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  color:
                                                  Color(0xfff1f1f1),
                                                ),
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets
                                                      .all(4.0),
                                                  child: Icon(
                                                      CupertinoIcons.mail,
                                                      size: 30,
                                                      color: Color(
                                                          0xFF1FAFAD)),
                                                ),
                                              ),
                                            ),
                                            Text("Message",
                                                style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                        context)
                                                        .size
                                                        .width /
                                                        100 *
                                                        2.5))
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                              .size
                                              .width /
                                              100 *
                                              10,
                                        ),

                                        //more
                                        Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                showModalBottomSheet(
                                                    context: context,
                                                    // isScrollControlled: true,
                                                    backgroundColor:
                                                    Colors
                                                        .transparent,
                                                    builder: (context) {
                                                      return SafeArea(
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                              BorderRadius.vertical(
                                                                  top:
                                                                  Radius.circular(20))),
                                                          child: Column(
                                                            mainAxisSize:
                                                            MainAxisSize
                                                                .min,
                                                            children: [
                                                              attachMenuTile(
                                                                  EdgeInsets.only(left: 15.0, right: 15.0,top: 1), "Blog", "blog", context, BorderRadius.vertical(top: Radius.circular(20)),
                                                                  Colors
                                                                      .transparent,
                                                                  CupertinoIcons
                                                                      .doc_richtext),
                                                              attachMenuTile(
                                                                  EdgeInsets.only(
                                                                      left:
                                                                      15.0,
                                                                      right:
                                                                      15.0,
                                                                      top:
                                                                      0.5),
                                                                  "Members",
                                                                  "members",
                                                                  context,
                                                                  BorderRadius
                                                                      .zero,
                                                                  Colors
                                                                      .transparent,
                                                                  Icons
                                                                      .people_alt_outlined),
                                                              attachMenuTile(
                                                                  EdgeInsets.only(
                                                                      left:
                                                                      15.0,
                                                                      right:
                                                                      15.0,
                                                                      top:
                                                                      0.5),
                                                                  "Events",
                                                                  "events",
                                                                  context,
                                                                  BorderRadius
                                                                      .zero,
                                                                  Colors
                                                                      .transparent,
                                                                  CupertinoIcons
                                                                      .calendar),
                                                              attachMenuTile(
                                                                  EdgeInsets.only(
                                                                      left:
                                                                      15.0,
                                                                      right:
                                                                      15.0,
                                                                      top:
                                                                      0.5),
                                                                  "Groups",
                                                                  "groups",
                                                                  context,
                                                                  BorderRadius.vertical(
                                                                      bottom: Radius.circular(
                                                                          15)),
                                                                  Colors
                                                                      .transparent,
                                                                  CupertinoIcons
                                                                      .group),
                                                              dissmissMenuTile(
                                                                  EdgeInsets.only(
                                                                      left:
                                                                      15.0,
                                                                      right:
                                                                      15.0,
                                                                      top:
                                                                      10,
                                                                      bottom:
                                                                      10),
                                                                  "Dismiss",
                                                                  "Dismiss",
                                                                  context,
                                                                  BorderRadius.all(Radius.circular(
                                                                      15)),
                                                                  Colors
                                                                      .white),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    });
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  color:
                                                  Color(0xfff1f1f1),
                                                ),
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets
                                                      .all(4.0),
                                                  child: Icon(
                                                      CupertinoIcons.bars,
                                                      size: 30,
                                                      color: Color(
                                                          0xFF1FAFAD)),
                                                ),
                                              ),
                                            ),
                                            Text("More",
                                                style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                        context)
                                                        .size
                                                        .width /
                                                        100 *
                                                        2.5))
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              )
                                  : globalUrl.contains("https://blab.lk/about/") ||
                                  globalUrl.contains("https://blab.lk/message-us/")||
                                  globalUrl.contains("https://blab.lk/our-team/")||
                                  globalUrl.contains("https://blab.lk/our-privacy-policy/")||
                                  globalUrl.contains("https://blab.lk/terms-and-conditions/")||
                                  globalUrl.contains("https://blab.lk/password-recover/")||
                                  globalUrl.contains('https://blab.lk/register/')||
                                  globalUrl.contains(
                                      'https://blab.lk/password-recover/') ||
                                  globalUrl.contains(
                                      'https://blab.lk/register/')
                                  ? Positioned(
                                left: 0,
                                top: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      globalUrl =
                                      "https://blab.lk/home-page/";
                                      webViewController?.loadUrl(
                                          urlRequest: URLRequest(
                                              url: Uri.parse(
                                                  "https://blab.lk/home-page/")));
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.all(10),
                                    padding: EdgeInsets.only(
                                        left: 15,
                                        bottom: 10,
                                        top: 10,
                                        right: 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(blurRadius: 2)
                                        ]),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ),
                              )
                                  : selectedNav == "init"?Container(): selectedNav!="" && selectedNav !="other"
                                  ? Positioned(
                                  top: 0,
                                  width: MediaQuery.of(context)
                                      .size
                                      .width,
                                  child: Container(
                                      color: Color(0xFFFFFFFF),
                                      height: 60,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 0,
                                            top: 5,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.arrow_back_ios,
                                                color: Colors.black,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  webViewController?.loadUrl(
                                                      urlRequest: URLRequest(
                                                          url: Uri.parse(
                                                              "https://blab.lk/")));
                                                  selectedNav = "";
                                                  globalUrl =
                                                  "https://blab.lk/";
                                                });
                                              },
                                            ),
                                          ),
                                          Center(
                                              child: Text(
                                                selectedNav,
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18),
                                              ))
                                        ],
                                      )))
                                  : Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  padding:
                                  EdgeInsets.only(left: 20),
                                  color: Colors.white,
                                  width: MediaQuery.of(context)
                                      .size
                                      .width,
                                  height: 60,
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            globalUrl =
                                            "https://blab.lk/";
                                            webViewController?.loadUrl(
                                                urlRequest: URLRequest(
                                                    url: Uri.parse(
                                                        "https://blab.lk/")));
                                          });
                                        },
                                        child: Icon(
                                          Icons.arrow_back_ios,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "Back to home",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 18),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              progress < 1.0
                                  ? Center(
                                    child: Container(
                                      height: 55,
                                      width: 55,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          new BoxShadow(color: Color(0xFF545454), blurRadius: 2)
                                        ],
                                        borderRadius: BorderRadius.circular(200),
                                        color: Colors.white,
                                      ),
                                      child: SpinKitWave(
                                        color: Color(0xFF393d3a),
                                        size: 20.0,
                                        duration: Duration(milliseconds: 1000),
                                      ),
                                    ),
                                  )
                                  : Container(),
                            ],
                          ));
                    }
                    else
                      {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          color: Colors.white,
                          child: Align(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                width: MediaQuery.of(context).size.width*0.8,
                                    child: Image.asset('assets/images/construction.jpg',)),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Sorry we are not available at the movement",style: TextStyle(fontSize: 18),),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20,right: 20,top: 10),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      text:
                                      'The  ',
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 14.0),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: 'BLab ',
                                            style: TextStyle(
                                                color: Color(0xff1a3e57),
                                                fontSize: 16.0)),
                                        TextSpan(
                                            text: 'is currently under the maintain sorry for the inconvenience. ',
                                            style: TextStyle(
                                                fontSize: 14.0)),
                                        TextSpan(
                                            text: 'We will get back to you As soon as possible ',
                                            style: TextStyle(
                                                color: Color(0xff1a3e57),
                                                fontSize: 14.0)),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20,right: 20,top: 10),
                                  child: Text(
                                      '${snapshot.data!.docs[0]['desc']}',
                                      style: TextStyle(
                                          fontSize: 14.0)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                  })
                  : NoInternet();
            } else {
              return Center(
                child: Container(
                  color: Color(0xffffffff),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitWave(
                        color: Color(0xFF393d3a),
                        size: 20.0,
                        duration: Duration(milliseconds: 1000),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        )),
      ),
    );
  }

  Widget attachMenuTile(
      EdgeInsets tilePadding,
      String tileText,
      String clickRoute,
      BuildContext context,
      BorderRadius borderRadius,
      Color color,
      IconData icon) {
    return Padding(
      padding: tilePadding,
      child: AnimationLimiter(
          child: AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 500),
        child: SlideAnimation(
          child: Material(
            color: Color(0xFFECECED),
            borderRadius: borderRadius,
            child: InkWell(
              onTap: () async {
                switch (clickRoute) {
                  case "blog":
                    {
                      if (globalUrl != "https://blab.lk/blog/") {
                        setState(() {
                          selectedNav = "Blog";
                          globalUrl = "https://blab.lk/blog/";
                          webViewController?.loadUrl(
                              urlRequest: URLRequest(
                                  url: Uri.parse("https://blab.lk/blog/")));
                        });
                      }
                      Navigator.of(context).pop();
                    }
                    break;

                  case "members":
                    {
                      if (globalUrl != "https://blab.lk/members/") {
                        setState(() {
                          selectedNav = "Members";
                          globalUrl = "https://blab.lk/members/";
                          webViewController?.loadUrl(
                              urlRequest: URLRequest(
                                  url: Uri.parse("https://blab.lk/members/")));
                        });
                      }
                      Navigator.of(context).pop();
                    }
                    break;

                  case "events":
                    {
                      if (globalUrl != "https://blab.lk/events/") {
                        setState(() {
                          selectedNav = "Events";
                          globalUrl = "https://blab.lk/events/";
                          webViewController?.loadUrl(
                              urlRequest: URLRequest(
                                  url: Uri.parse("https://blab.lk/events/")));
                        });
                      }
                      Navigator.of(context).pop();
                    }
                    break;

                  case "groups":
                    {
                      if (globalUrl != "https://blab.lk/groups/") {
                        setState(() {
                          selectedNav = "Groups";
                          globalUrl = "https://blab.lk/groups/";
                          webViewController?.loadUrl(
                              urlRequest: URLRequest(
                                  url: Uri.parse("https://blab.lk/groups/")));
                        });
                        Navigator.of(context).pop();
                      }
                    }
                    break;

                  default:
                    {
                      Navigator.of(context).pop();
                    }
                    break;
                }
              },
              highlightColor: Color(0x55a0a3a3),
              splashColor: Color(0x55a0a3a3),
              child: Container(
                decoration:
                    BoxDecoration(borderRadius: borderRadius, color: color),
                padding: EdgeInsets.all(12.0),
                child: AnimationLimiter(
                  child: AnimationConfiguration.synchronized(
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: clickRoute == "Dismiss"
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            icon,
                            color: Color(0xFF1FAFAD),
                            size: 30,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            tileText,
                            style: TextStyle(fontSize: 20),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }

  Widget dissmissMenuTile(
      EdgeInsets tilePadding,
      String tileText,
      String clickRoute,
      BuildContext context,
      BorderRadius borderRadius,
      Color color) {
    return Padding(
      padding: tilePadding,
      child: AnimationLimiter(
          child: AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 500),
        child: SlideAnimation(
          child: Material(
            color: color,
            borderRadius: borderRadius,
            child: InkWell(
              onTap: () async {
                Navigator.of(context).pop();
              },
              highlightColor: Color(0x55a0a3a3),
              splashColor: Color(0x55a0a3a3),
              child: Container(
                decoration:
                    BoxDecoration(borderRadius: borderRadius, color: color),
                padding: EdgeInsets.all(12.0),
                child: AnimationLimiter(
                  child: AnimationConfiguration.synchronized(
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tileText,
                            style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFF1FAFAD),
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}
