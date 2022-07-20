import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
import 'package:uni_web/helpers/Constant.dart';
import 'package:uni_web/screens/web_url_screen.dart';
import 'package:provider/src/provider.dart';

import '../helpers/Strings.dart';
import '../helpers/Icons.dart';
import '../main.dart';
import '../provider/navigationBarProvider.dart';
import '../widgets/GlassBoxCurve.dart';
import '../screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  MainScreen();
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 1;
  var _previousIndex;
  late TabController _tabController;
  late AnimationController idleAnimation;
  late AnimationController onSelectedAnimation;
  late AnimationController onChangedAnimation;
  Duration animationDuration = const Duration(milliseconds: 700);

  late AnimationController navigationContainerAnimationController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>()
  ];

  @override
  void dispose() {
    super.dispose();
    // dispose controller
    _tabController.dispose();
    idleAnimation.dispose();
    onSelectedAnimation.dispose();
    onChangedAnimation.dispose();
    navigationContainerAnimationController.dispose();
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    idleAnimation = AnimationController(vsync: this);
    onSelectedAnimation =
        AnimationController(vsync: this, duration: animationDuration);
    onChangedAnimation =
        AnimationController(vsync: this, duration: animationDuration);

    Future.delayed(Duration.zero, () {
      context
          .read<NavigationBarProvider>()
          .setAnimationController(navigationContainerAnimationController);
    });

    initFirebaseState();
  }

  void initFirebaseState() async {
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {}
    });
    _firebaseMessaging.getToken().then((value) {});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // var data = message.notification!;
      // var title = data.title.toString();
      // var body = data.body.toString();
      // var image = message.data['image'] ?? '';
      // print(image);
      // print(data);
      RemoteNotification notification = message.notification!;
      AndroidNotification android = message.notification!.android!;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  color: Colors.blue,
                  playSound: true,
                  icon: notificationIcon,
                ),
                iOS: const IOSNotificationDetails()));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Theme.of(context).cardColor,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ));
    return WillPopScope(
      onWillPop: () => _navigateBack(context),
      child: SafeArea(
        child: Scaffold(
          extendBody: true,
          bottomNavigationBar: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(
                    parent: navigationContainerAnimationController,
                    curve: Curves.easeInOut)),
            child: SlideTransition(
                position: Tween<Offset>(
                        begin: Offset.zero, end: const Offset(0.0, 1.0))
                    .animate(CurvedAnimation(
                        parent: navigationContainerAnimationController,
                        curve: Curves.easeInOut)),
                child: _bottomNavigationBar),
          ),
          body: Stack(children: [
            IndexedStack(
              index: _selectedIndex,
              children: _tabs,
            ),
          ]),
        ),
      ),
    );
  }

  Future<bool> _navigateBack(BuildContext context) async {
    if (Platform.isIOS && Navigator.of(context).userGestureInProgress) {
      return Future.value(true);
    }
    final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
    if (!context
        .read<NavigationBarProvider>()
        .animationController
        .isAnimating) {
      context.read<NavigationBarProvider>().animationController.reverse();
    }
    if (!isFirstRouteInCurrentTab) {
      return Future.value(false);
    } else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Do you want to exit app?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ));

      return Future.value(true);
    }
  }

  Widget get _bottomNavigationBar {
    return Container(
      height: 75,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 3,
            spreadRadius: 1,
          )
        ],
      ),
      child: GlassBoxCurve(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width / 10,
        child: Padding(
          padding: const EdgeInsets.only(left: 2, right: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavItem(0, CustomStrings.demo,
                  Theme.of(context).colorScheme.demoIcon),
              _buildNavItem(1, CustomStrings.home,
                  Theme.of(context).colorScheme.homeIcon),
              _buildNavItem(2, CustomStrings.settings,
                  Theme.of(context).colorScheme.settingsIcon),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, String icon) {
    return InkWell(
      onTap: () {
        onButtonPressed(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10.0),
          Lottie.asset(icon,
              height: 30,
              repeat: true,
              // reverse: true,
              // animate: true,
              controller: _selectedIndex == index
                  ? onSelectedAnimation
                  : _previousIndex == index
                      ? onChangedAnimation
                      : idleAnimation),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Text(title,
                textAlign: TextAlign.center,
                style: _selectedIndex == index
                    ? TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      )
                    : const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      )),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                width: 35,
                height: 3,
                decoration: BoxDecoration(
                  color: _selectedIndex == index
                      ? Theme.of(context).indicatorColor
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                      topRight: Radius.circular(4.0)),
                  boxShadow: _selectedIndex == index
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .indicatorColor
                                .withOpacity(0.5),
                            blurRadius: 50.0, // soften the shadow
                            spreadRadius: 20.0,
                            //extend the shadow
                          )
                        ]
                      : [],
                )),
          ),
        ],
      ),
    );
  }

  void onButtonPressed(int index) {
    if (_navigatorKeys[_selectedIndex].currentState!.canPop()) {
      //
      _navigatorKeys[_selectedIndex]
          .currentState!
          .popUntil((route) => route.isFirst);
    }
    onSelectedAnimation.reset();
    onSelectedAnimation.forward();

    onChangedAnimation.value = 1;
    onChangedAnimation.reverse();

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
      if (!context
          .read<NavigationBarProvider>()
          .animationController
          .isAnimating) {
        context.read<NavigationBarProvider>().animationController.reverse();
      }
    });
  }

  late final List<Widget> _tabs = [
    //demo tab
    Navigator(
      key: _navigatorKeys[0],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (_) => WebUrlScreen(firstTabUrl));
      },
    ),

    //home tab
    Navigator(
      key: _navigatorKeys[1],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (_) => WebUrlScreen(webInitialUrl));
      },
    ),

    //settings tab
    Navigator(
      key: _navigatorKeys[2],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      },
    ),
  ];
}
