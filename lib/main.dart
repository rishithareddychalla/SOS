// import 'dart:async';
// import 'dart:convert';
// import 'dart:io' show Platform;

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:telephony/telephony.dart';

// import 'contacts_screen.dart';
// import 'calling_screen.dart';

// // Riverpod provider for contacts - NO CHANGES HERE
// final contactsProvider =
//     StateNotifierProvider<
//       ContactsNotifier,
//       AsyncValue<List<Map<String, String>>>
//     >((ref) {
//       final notifier = ContactsNotifier();
//       notifier._initialize();
//       return notifier;
//     });

// class ContactsNotifier
//     extends StateNotifier<AsyncValue<List<Map<String, String>>>> {
//   ContactsNotifier() : super(const AsyncValue.loading());

//   Future<void> _initialize() async {
//     await _loadContacts();
//   }

//   Future<void> _loadContacts() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final contactsJson = prefs.getString('contacts');
//       if (contactsJson != null) {
//         final decoded = json.decode(contactsJson) as List;
//         final contacts = decoded
//             .map((item) => Map<String, String>.from(item))
//             .toList();
//         state = AsyncValue.data(contacts);
//       } else {
//         state = const AsyncValue.data([]);
//       }
//     } catch (e, stack) {
//       state = AsyncValue.error(e, stack);
//     }
//   }

//   Future<void> addContact(String name, String phone) async {
//     final currentContacts = state.value ?? [];
//     final newContacts = [
//       ...currentContacts,
//       {'name': name, 'phone': phone},
//     ];
//     state = AsyncValue.data(newContacts.cast<Map<String, String>>());
//     await _saveContacts();
//   }

//   Future<void> deleteContact(int index) async {
//     final currentContacts = state.value ?? [];
//     if (index >= 0 && index < currentContacts.length) {
//       final newContacts = List.from(currentContacts)..removeAt(index);
//       state = AsyncValue.data(newContacts.cast<Map<String, String>>());
//       await _saveContacts();
//     }
//   }

//   Future<void> _saveContacts() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('contacts', json.encode(state.value ?? []));
//   }
// }

// // GoRouter setup - NO CHANGES HERE
// final GoRouter router = GoRouter(
//   routes: [
//     GoRoute(path: '/', builder: (context, state) => MainScreen()),
//     GoRoute(
//       path: '/contacts',
//       builder: (context, state) => const ContactsScreen(),
//     ),
//     GoRoute(
//       path: '/calling',
//       builder: (context, state) => const CallingScreen(),
//     ),
//   ],
// );

// void main() {
//   runApp(ProviderScope(child: MyApp()));
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       title: 'SOS',
//       theme: ThemeData(
//         scaffoldBackgroundColor: Colors.white,
//         textTheme: const TextTheme(
//           headlineMedium: TextStyle(
//             fontSize: 48,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//           bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
//         ),
//       ),
//       routerConfig: router,
//     );
//   }
// }

// class MainScreen extends ConsumerWidget {
//   MainScreen({super.key});

//   static const platform = MethodChannel('com.example.sos_app/conference_call');
//   final Telephony telephony = Telephony.instance;

//   Future<bool> _requestPermissions(BuildContext context) async {
//     final permissions = [Permission.sms, Permission.location, Permission.phone];

//     Map<Permission, PermissionStatus> statuses = await permissions.request();

//     bool allGranted = true;
//     statuses.forEach((permission, status) {
//       if (!status.isGranted) {
//         allGranted = false;
//       }
//     });

//     if (!allGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'All permissions (SMS, Location, Phone) are required to use the SOS feature.',
//           ),
//         ),
//       );
//     }

//     return allGranted;
//   }

//   Future<Position> _determinePosition() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       return Future.error(
//         'Location permissions are permanently denied, we cannot request permissions.',
//       );
//     }

//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//   }

//   Future<void> _handleSOS(BuildContext context, WidgetRef ref) async {
//     final contactList = ref.read(contactsProvider).value ?? [];
//     if (contactList.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No emergency contacts have been added!')),
//       );
//       return;
//     }

//     final hasPermissions = await _requestPermissions(context);
//     if (!hasPermissions) {
//       return;
//     }

//     // Navigate to the calling screen immediately for better user feedback
//     context.go('/calling');

//     try {
//       // 1. Get Geolocation
//       final position = await _determinePosition();
//       final locationMessage =
//           "Emergency! I need help. My current location is: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

//       // 2. Send SMS to all contacts
//       final phoneNumbers = contactList.map((c) => c['phone']!).toList();
//       for (var number in phoneNumbers) {
//         await telephony.sendSms(to: number, message: locationMessage);
//       }

//       // 3. Initiate Conference Call via native code
//       await platform.invokeMethod('startConferenceCall', {
//         'numbers': phoneNumbers,
//       });

//       // On iOS, users must manually merge calls. This provides a hint.
//       if (Platform.isIOS) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             duration: Duration(seconds: 10),
//             content: Text(
//               'Calls have been initiated. Please merge the calls manually to create a conference.',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint('An error occurred during SOS: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
//       // If something fails, navigate back from the calling screen
//       if (context.mounted) context.go('/');
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // ... The rest of the build method is unchanged from the original file
//     final contacts = ref.watch(contactsProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('SOS', style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFF8B1E9B),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.contacts, color: Colors.white),
//             onPressed: () => context.go('/contacts'),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     GestureDetector(
//                       onTap: () => _handleSOS(context, ref),
//                       child: Container(
//                         width: 200,
//                         height: 200,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFFD81B60), Color(0xFF8B1E9B)],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFFD81B60).withOpacity(0.3),
//                               spreadRadius: 10,
//                               blurRadius: 20,
//                               offset: Offset(0, 0),
//                             ),
//                           ],
//                         ),
//                         child: const Center(
//                           child: Text(
//                             'SOS',
//                             style: TextStyle(
//                               fontSize: 48,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     const Text(
//                       'Tapping SOS will call all emergency contacts and send them your location.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 16, color: Colors.black54),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Image.asset(
//               'assets/images/logo_pink.png',
//               height: 50,
//               width: 50,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';

import 'contacts_screen.dart';
import 'calling_screen.dart';

// Riverpod provider for contacts
final contactsProvider =
    StateNotifierProvider<
      ContactsNotifier,
      AsyncValue<List<Map<String, String>>>
    >((ref) {
      final notifier = ContactsNotifier();
      notifier._initialize();
      return notifier;
    });

class ContactsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, String>>>> {
  ContactsNotifier() : super(const AsyncValue.loading());

  Future<void> _initialize() async {
    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('contacts');
      if (contactsJson != null) {
        final decoded = json.decode(contactsJson) as List;
        final contacts = decoded
            .map((item) => Map<String, String>.from(item))
            .toList();
        state = AsyncValue.data(contacts);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addContact(String name, String phone) async {
    final currentContacts = state.value ?? [];
    final newContacts = [
      ...currentContacts,
      {'name': name, 'phone': phone},
    ];
    state = AsyncValue.data(newContacts.cast<Map<String, String>>());
    await _saveContacts();
  }

  Future<void> deleteContact(int index) async {
    final currentContacts = state.value ?? [];
    if (index >= 0 && index < currentContacts.length) {
      final newContacts = List.from(currentContacts)..removeAt(index);
      state = AsyncValue.data(newContacts.cast<Map<String, String>>());
      await _saveContacts();
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contacts', json.encode(state.value ?? []));
  }
}

// GoRouter setup
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

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SOS',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
      routerConfig: router,
    );
  }
}

class MainScreen extends ConsumerWidget {
  MainScreen({super.key});

  static const platform = MethodChannel('com.example.sos_app/conference_call');
  final Telephony telephony = Telephony.instance;

  Future<bool> _requestPermissions(BuildContext context) async {
    final permissions = [Permission.sms, Permission.location, Permission.phone];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (!allGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'All permissions (SMS, Location, Phone) are required.',
            ),
          ),
        );
      }
    }

    return allGranted;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _handleSOS(BuildContext context, WidgetRef ref) async {
    final contactList = ref.read(contactsProvider).value ?? [];
    if (contactList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency contacts have been added!')),
      );
      return;
    }

    final hasPermissions = await _requestPermissions(context);
    if (!hasPermissions) {
      return;
    }

    context.go('/calling');

    try {
      final position = await _determinePosition();
      final locationMessage =
          "Emergency! I need help. My current location is: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      final phoneNumbers = contactList.map((c) => c['phone']!).toList();
      for (var number in phoneNumbers) {
        await telephony.sendSms(to: number, message: locationMessage);
      }

      await platform.invokeMethod('startConferenceCall', {
        'numbers': phoneNumbers,
      });

      if (Platform.isIOS && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 10),
            content: Text('Calls initiated. Please merge them manually.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('An error occurred during SOS: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8B1E9B),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts, color: Colors.white),
            onPressed: () => context.go('/contacts'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _handleSOS(context, ref),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD81B60), Color(0xFF8B1E9B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD81B60).withOpacity(0.3),
                      spreadRadius: 10,
                      blurRadius: 20,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tapping SOS will call all emergency contacts and send them your location.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
