import 'package:go_router/go_router.dart';

import 'package:sos_app/main.dart';
import 'package:sos_app/splash_screen.dart';

import 'contacts_screen.dart';
import 'calling_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/', builder: (context, state) => MainScreen()),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: '/calling',
      builder: (context, state) => const CallingScreen(),
    ),
  ],
);
