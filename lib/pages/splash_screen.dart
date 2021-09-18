import 'package:blab/pages/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import 'package:page_transition/page_transition.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  int _timeUp = 0;
  late AnimationController rippleController;
  late AnimationController scaleController;

  late Animation<double> rippleAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    rippleController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    scaleController =
    AnimationController( vsync:  this, duration: Duration(milliseconds: 300))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Navigator.pushReplacement(
              context,
              PageTransition(
                  type: PageTransitionType.fade, child: HomePage()));
        }
      });

    rippleAnimation =
    Tween<double>(begin: 50.0, end: 60.0).animate(rippleController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          rippleController .reverse();
        } else if (status == AnimationStatus.dismissed) {
          rippleController .forward();
        }
      });

    scaleAnimation =
        Tween<double>(begin: 1.0, end: 50.0).animate(scaleController );

    rippleController .forward();

    Timer(Duration(seconds: 2), () {
      setState(() {
        _timeUp =1;
      });
      scaleController .forward();
    });

  }

  @override
  void dispose() {
    rippleController .dispose();
    scaleController .dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFFffffff), // for light theme
      statusBarIconBrightness: Brightness.dark,
      //    statusBarColor :Color(0xFF1a1b1c)//for dark theme
    ));
    return Scaffold(
      body:Container(
        color: Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                  Container(
                    width: 108,
                    height:108,
                    decoration: BoxDecoration(
                      // boxShadow: [
                      //   new BoxShadow(color: Color(0xFF545454), blurRadius: 2)
                      // ],
                      borderRadius: BorderRadius.circular(200),
                      color: Colors.white,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(200),
                          color: Colors.white,
                          image: DecorationImage(
                              image: AssetImage('assets/images/logo_original.png')
                          )
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(
                    'Please Wait...',
                    style: TextStyle(color: Color(0xFF1d465c)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(
                    'Loading services',
                    style: TextStyle(color: Colors.black54, fontSize: 15.0),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.loose,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: rippleAnimation,
                        builder: (context, child) => Container(
                          width: rippleAnimation.value,
                          height: rippleAnimation.value,
                          child: AnimatedBuilder(
                            animation: scaleAnimation,
                            builder: (context, child) => Transform.scale(
                              scale: scaleAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _timeUp == 0
                                        ? Colors.white
                                        : Color(0xFF393d3a)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: _timeUp == 0 ? true : false,
                        child: SpinKitWave(
                          color: Color(0xFF393d3a),
                          size: 20.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      ),
                    ],
                  ),
                ),


                // Padding(
                //   padding: const EdgeInsets.only(bottom: 10.0),
                //   child: Container(
                //     height: 40,
                //     child: Visibility(
                //       visible: _timeUp == 0 ? true : false,
                //       child: Row(
                //         crossAxisAlignment: CrossAxisAlignment.center,
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: <Widget>[
                //           Text('Powerd by :  ', style: TextStyle(
                //             fontSize: 10.0,
                //             color: Color(0xFF1d465c),
                //             fontFamily: "Georgia",
                //           )),
                //           Shimmer.fromColors(
                //               child: Text(
                //                 "Blab.lk™ ",
                //                 style: TextStyle(
                //                   fontSize: 16.0,
                //                   fontWeight: FontWeight.bold,
                //                   fontFamily: "Georgia",
                //                 ),
                //               ),
                //               baseColor: Color(0xff21678a),
                //               highlightColor: Colors.white),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
