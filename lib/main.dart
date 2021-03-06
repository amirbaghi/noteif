import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:noteif/helper/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_analytics/observer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  // static FirebaseAnalyticsObserver observer =
  //     FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    if (!kReleaseMode) {
//      analytics.resetAnalyticsData();
      analytics.setAnalyticsCollectionEnabled(false);
    }
    analytics.logAppOpen();
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale("fa", "IR"),
      ],
      theme: ThemeData(
          fontFamily: 'IRANSansMobile', primaryColor: AppColors.bondiBlue),
      locale: Locale("fa", "IR"),
//      navigatorObservers: <NavigatorObserver>[observer],
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final noteTextBoxController = TextEditingController();
  bool showNotification = false;
  SharedPreferences prefs;

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    noteTextBoxController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) => setState(() {
          prefs = sp;
          String note = prefs.getString('note');
          showNotification = prefs.getBool('showNotification') != null
              ? prefs.getBool('showNotification')
              : true; // for handling if pref is null
          if (note != null) {
            noteTextBoxController.text = note;
            // if (showNotification) {
            //   sendNotification(note);
            // }
          }
        }));
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('@mipmap/notification_icon');
    var iOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(
      initSettings,
//        onSelectNotification: onSelectNotification
    );
  }

//  Future onSelectNotification(String payload) {
////    debugPrint("payload : $payload");
////    myController.text = payload;
////    showDialog(
////      context: context,
////      builder: (_) => new AlertDialog(
////        title: new Text('Notification'),
////        content: new Text('$payload'),
////      ),
////    );
//  }

  @override
  Widget build(BuildContext context) {
    final noteTextBox = Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.veryLightGray, AppColors.whiteSmoke],
      )),
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      child: Text(
        'Noteif',
        style: TextStyle(
          fontFamily: 'Chewy',
          color: Colors.black,
          fontSize: 30.0,
        ),
        textAlign: TextAlign.center,
      ),
    );

    final descriptionText = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(
        'ثبت یادداشت های مهم شما در نوتیفیکیشن :)',
        style: TextStyle(
          height: 1.7,
          fontSize: 14.0,
        ),
        textAlign: TextAlign.center,
      ),
    );

    final noteTextField = Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
      child: TextField(
        style: TextStyle(
          fontSize: 14.0,
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        minLines: 6,
        cursorColor: AppColors.bondiBlue,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        decoration: new InputDecoration(
          labelText: "متن یادداشت",
          border: new OutlineInputBorder(
            borderRadius: new BorderRadius.circular(7.0),
          ),
        ),
        controller: noteTextBoxController,
      ),
    );

    final showNotificationWidgets = Container(
      padding: const EdgeInsets.all(10.0),
      width: 300.0,
      child: MergeSemantics(
        child: ListTile(
          title: Text(
            'نمایش دادن نوتیفیکیشن',
            style: TextStyle(fontSize: 14.0),
          ),
          trailing: CupertinoSwitch(
            activeColor: AppColors.Viking,
            value: showNotification,
            onChanged: (val) => onSwitchChange(val),
          ),
          onTap: () => onSwitchChange(!showNotification),
        ),
      ),
    );
    final saveNoteButton = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Center(child: materialButton('ثبت یادداشت', setNote)),
    );

    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
//      appBar: emptyAppbar(),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                noteTextBox,
                descriptionText,
                noteTextField,
                saveNoteButton,
                showNotificationWidgets,
              ],
            ),
          ),
        ),
      ),
    );
  }

  setNote() {
    setState(() {
      showNotification = true;
    });
    prefs.setBool('showNotification', true);
    prefs.setString('note', noteTextBoxController.text.trim());
    sendNotification(noteTextBoxController.text.trim());
  }

  disableNote() {
    setState(() {
      showNotification = false;
    });
    prefs.setBool('show', false);
    flutterLocalNotificationsPlugin.cancelAll();
  }

  sendNotification(String notificationText) async {
    if (notificationText.isNotEmpty) {
      var android = AndroidNotificationDetails('note', 'note', 'Your note',
          playSound: false,
          enableVibration: false,
          styleInformation: BigTextStyleInformation(notificationText),
          autoCancel: false,
          priority: Priority.Max,
          importance: Importance.Max,
          ongoing: true);
      var iOS = IOSNotificationDetails(presentSound: false);
      var platform = NotificationDetails(android, iOS);
      await flutterLocalNotificationsPlugin
          .show(0, null, notificationText, platform, payload: notificationText);
    } else {
      // disableNote();
    }
  }

  materialButton(String buttonText, void Function() onTap) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 10.0),
      decoration: BoxDecoration(
        color: AppColors.Viking,
        borderRadius: BorderRadius.all(
          Radius.circular(50.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 1.5,
            spreadRadius: 0.1,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.all(
            Radius.circular(50.0),
          ),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
            child: Text(
              buttonText,
              style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  onSwitchChange(bool val) {
    if (val) {
      setNote();
    } else {
      disableNote();
    }
  }
}
