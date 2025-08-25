import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:phone_state/phone_state.dart';

import 'contacts_screen.dart';
import 'calling_screen.dart';

// --- State Management ---

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
  Future<void> _initialize() async => await _loadContacts();

  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('contacts');
      if (contactsJson != null) {
        final decoded = json.decode(contactsJson) as List;
        state = AsyncValue.data(
          decoded.map((item) => Map<String, String>.from(item)).toList(),
        );
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addContact(String name, String phone) async {
    final currentContacts = state.value ?? [];
    state = AsyncValue.data([
      ...currentContacts,
      {'name': name, 'phone': phone},
    ]);
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

// Provider to manage the sequential call queue
final sequentialCallProvider =
    StateNotifierProvider<SequentialCallNotifier, List<String>>((ref) {
      return SequentialCallNotifier();
    });

class SequentialCallNotifier extends StateNotifier<List<String>> {
  StreamSubscription<PhoneState>? _callStateSubscription;

  SequentialCallNotifier() : super([]);

  void startSOS(List<String> numbers) {
    if (numbers.isEmpty) return;
    state = List.from(numbers);
    _listenToCallStates();
    _callNextNumber();
  }
  void _callNextNumber() async {
    if (state.isEmpty) {
      stopSOS();
      return;
    }
    final numberToCall = state.first;
    debugPrint('Attempting to call number: $numberToCall');
    try {
      await FlutterPhoneDirectCaller.callNumber(numberToCall);
    } catch (e) {
      debugPrint('Error calling number $numberToCall: $e');
      _handleCallEnded();
    }
  }

  void _handleCallEnded() {
    debugPrint('Detected call ended.');
    if (state.isNotEmpty) {
      state = List.from(state)..removeAt(0);
    }

    if (state.isNotEmpty) {
      debugPrint('More numbers in queue. Calling next number in 2 seconds.');
      Future.delayed(const Duration(seconds: 2), _callNextNumber);
    } else {
      debugPrint('No more numbers in queue. Stopping SOS.');
      stopSOS();
    }
  }

  void _listenToCallStates() {
    _callStateSubscription?.cancel();
    _callStateSubscription = PhoneState.stream.listen((phoneState) {
      debugPrint('Received call state event: ${phoneState.status}');
      if (phoneState.status == PhoneStateStatus.CALL_ENDED) {
        _handleCallEnded();
      }
    });
  }

  void stopSOS() {
    debugPrint('Stopping SOS and cancelling call state listener.');
    _callStateSubscription?.cancel();
    state = [];
  }

  @override
  void dispose() {
    _callStateSubscription?.cancel();
    super.dispose();
  }
}

// --- UI and App Setup ---

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
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MainScreen({super.key});

  Future<bool> _requestPermissions(BuildContext context) async {
    final permissions = [
      Permission.sms,
      Permission.location,
      Permission.phone,
      Permission.contacts, // Correct permission for READ_PHONE_STATE
      Permission.notification,
    ];
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    bool allGranted = true;
    statuses.forEach((permission, status) {
      debugPrint(
        'Permission: ${permission.toString()}, Status: ${status.toString()}',
      );
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (!allGranted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All permissions are required. Please check app settings.',
          ),
        ),
      );
      await openAppSettings();
    }
    return allGranted;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('Location permissions are permanently denied.');
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _handleSOS(BuildContext context, WidgetRef ref) async {
    final contactList = ref.read(contactsProvider).value ?? [];
    if (contactList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency contacts added!')),
      );
      return;
    }

    final hasPermissions = await _requestPermissions(context);
    if (!hasPermissions) return;

    context.go('/calling');

    try {
      final position = await _determinePosition();
      final locationMessage =
          "Emergency! I need help. My current location is: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      final phoneNumbers = contactList.map((c) => c['phone']!).toList();

      final telephony = Telephony.instance;
      for (var number in phoneNumbers) {
        await telephony.sendSms(to: number, message: locationMessage);
      }

      ref.read(sequentialCallProvider.notifier).startSOS(phoneNumbers);
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
                      offset: const Offset(0, 0),
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
