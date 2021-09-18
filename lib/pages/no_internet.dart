import 'package:flutter/material.dart';

class NoInternet extends StatelessWidget {
  const NoInternet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Image.asset('assets/images/connection_down.gif',
                fit: BoxFit.fill, height: 130, width: 150),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              'You are offline',
              style:
              TextStyle(color: Color(0xFF545454), fontSize: 18.0),
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(
                  bottom: 15.0, left: 50, right: 50),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text:
                  'Please enable your network connection for giving you to a ',
                  style: TextStyle(
                      color: Colors.black54, fontSize: 14.0),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'better experience',
                        style: TextStyle(
                            color: Color(0xff1a3e57),
                            fontSize: 14.0)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
