import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'splash_screen/splash_screen.dart';
import 'firebase_options.dart'; 
import 'Services/theme_manager.dart';
import 'Services/notification_service.dart';
import 'advertisement/advertise.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("Starting App Initialization...");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // ✅ Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // ✅ Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint("Firebase Initialized");
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  // ✅ Initialize FCM Background Handler
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("FCM Background Handler Error: $e");
  }

  // ✅ Initialize Background Services correctly
  await _initServices();

  // ✅ Enable Edge-to-Edge Display for Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

Future<void> _initServices() async {
  try {
    await NotificationService().init();
    debugPrint("Notification Service Initialized");
  } catch (e) {
    debugPrint("Notification Service Init Error: $e");
  }

  try {
    await ThemeManager.instance.init();
    debugPrint("Theme Manager Initialized");
  } catch (e) {
    debugPrint("Theme Manager Init Error: $e");
  }

  try {
    MobileAds.instance.initialize();
    AdvertiseManager().preloadInterstitial(); // ✅ Preload on startup
    debugPrint("Mobile Ads Initialized");
  } catch (e) {
    debugPrint("Mobile Ads Init Error: $e");
  }

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode ? AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode ? AppleDebugProvider() : const AppleDeviceCheckProvider(),
    );
    debugPrint("App Check Activated");
  } catch (e) {
    debugPrint("Firebase App Check Activation Error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeModeNotifier,
      builder: (context, mode, child) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            // Determine platform for App style
            final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
            
            if (isIOS) {
              return CupertinoApp(
                debugShowCheckedModeBanner: false,
                theme: CupertinoThemeData(
                  brightness: mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
                  primaryColor: CupertinoColors.activeBlue,
                ),
                home: child,
              );
            } else {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                  brightness: Brightness.light,
                  fontFamily: 'Poppins',
                  snackBarTheme: const SnackBarThemeData(
                    behavior: SnackBarBehavior.floating,
                  ),
                  appBarTheme: AppBarTheme(
                    titleTextStyle: TextStyle(
                      fontSize: 22.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                    brightness: Brightness.dark,
                  ),
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  fontFamily: 'Poppins',
                  snackBarTheme: const SnackBarThemeData(
                    behavior: SnackBarBehavior.floating,
                  ),
                  appBarTheme: AppBarTheme(
                    titleTextStyle: TextStyle(
                      fontSize: 22.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                home: child,
              );
            }
          },
          child: const SplashScreen(),
        );
      },
    );
  }
}
