
import 'package:go_router/go_router.dart';

import 'package:sos_app/main.dart';

import 'contacts_screen.dart';
import 'calling_screen.dart';
final GoRouter router = GoRouter(
  routes: [
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