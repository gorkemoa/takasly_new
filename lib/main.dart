import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'views/home/home_view.dart'; // Import HomeView

import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart'; // Import HomeViewModel
import 'viewmodels/notification_viewmodel.dart'; // Import NotificationViewModel
import 'viewmodels/event_viewmodel.dart'; // Import EventViewModel
import 'viewmodels/auth_viewmodel.dart'; // Import AuthViewModel

import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ],
      child: MaterialApp(
        title: 'Takasly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeView(),
      ),
    );
  }
}
