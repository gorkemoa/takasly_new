import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:takasly/viewmodels/product_detail_viewmodel.dart';
import 'firebase_options.dart';

import 'views/root_view.dart';

import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart'; // Import HomeViewModel
import 'viewmodels/notification_viewmodel.dart'; // Import NotificationViewModel
import 'viewmodels/event_viewmodel.dart'; // Import EventViewModel
import 'viewmodels/auth_viewmodel.dart'; // Import AuthViewModel
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/ticket_viewmodel.dart';
import 'viewmodels/trade_viewmodel.dart';
import 'viewmodels/blocked_users_viewmodel.dart';

import 'theme/app_theme.dart';

import 'services/firebase_messaging_service.dart';
import 'services/navigation_service.dart';

import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/in_app_review_service.dart';
import 'widgets/global_interaction_observer.dart'; // Import GlobalInteractionObserver

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set Navigation Key
  NavigationService.navigatorKey = navigatorKey;

  // Initialize Firebase Messaging Service
  await FirebaseMessagingService.initialize();

  // Initialize AdService
  await AdService().init();

  // Initialize InAppReview Service
  await InAppReviewService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // DeepLinkService().init(); // Temporarily disabled for development flow
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(
          create: (_) => EventViewModel(),
        ), // Register EventViewModel
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ProductDetailViewModel()),
        ChangeNotifierProvider(create: (_) => TicketViewModel()),
        ChangeNotifierProvider(create: (_) => TradeViewModel()),
        ChangeNotifierProvider(create: (_) => BlockedUsersViewModel()),
      ],
      child: MaterialApp(
        title: 'Takasly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        navigatorObservers: [AnalyticsService().getAnalyticsObserver()],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
        home: const RootView(),
        builder: (context, child) {
          return GlobalInteractionObserver(
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: child,
            ),
          );
        },
      ),
    );
  }
}
