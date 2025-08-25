
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'contacts_screen.dart';
import 'calling_screen.dart'; // New screen for the call UI

// Riverpod provider for contacts with initialization
final contactsProvider = StateNotifierProvider<ContactsNotifier, AsyncValue<List<Map<String, String>>>>((ref) {
  final notifier = ContactsNotifier();
  notifier._initialize(); // Trigger initialization
  return notifier;
});

class ContactsNotifier extends StateNotifier<AsyncValue<List<Map<String, String>>>> {
  ContactsNotifier() : super(const AsyncValue.loading()) {
    // Initial state is loading
  }

  Future<void> _initialize() async {
    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('contacts');
      debugPrint('Loading contacts from SharedPreferences: $contactsJson'); // Detailed debug
      if (contactsJson != null) {
        final decoded = json.decode(contactsJson) as List;
        final contacts = decoded.map((item) => Map<String, String>.from(item)).toList();
        state = AsyncValue.data(contacts);
        debugPrint('Successfully loaded contacts: $contacts'); // Confirm loaded state
      } else {
        state = const AsyncValue.data([]); // Set empty list if no data
        debugPrint('No contacts found in SharedPreferences');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Error loading contacts: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> addContact(String name, String phone) async {
    try {
      final currentContacts = state.value ?? [];
      final newContacts = [...currentContacts, {'name': name, 'phone': phone}];
      state = AsyncValue.data(newContacts.cast<Map<String, String>>());
      await _saveContacts();
      debugPrint('Contact added, new state: $newContacts'); // Confirm state update
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Error adding contact: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> deleteContact(int index) async {
    try {
      final currentContacts = state.value ?? [];
      if (index >= 0 && index < currentContacts.length) {
        final newContacts = List.from(currentContacts)..removeAt(index);
        state = AsyncValue.data(newContacts.cast<Map<String, String>>());
        await _saveContacts();
        debugPrint('Contact deleted, new state: $newContacts'); // Confirm state update
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      debugPrint('Error deleting contact: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsToSave = state.value ?? [];
      await prefs.setString('contacts', json.encode(contactsToSave));
      final savedJson = prefs.getString('contacts');
      debugPrint('Contacts saved to SharedPreferences: $savedJson'); // Confirm save
      if (savedJson != json.encode(contactsToSave)) {
        debugPrint('Warning: Saved data does not match current state');
      }
    } catch (e) {
      debugPrint('Error saving contacts: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
}

// GoRouter setup
final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
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
  const MainScreen({super.key});

  Future<void> _handleSOS(
    BuildContext context,
    AsyncValue<List<Map<String, String>>> contacts,
  ) async {
    final contactList = contacts.value ?? [];
    if (contactList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency contacts added!')),
      );
      return;
    }

    // Use the first contact only
    final contact = contactList.first;

    // Initiate call with brief redirection
    bool? res = await FlutterPhoneDirectCaller.callNumber(contact['phone']!);
    if (res != true) {
      debugPrint('Failed to call ${contact['phone']}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to initiate call.')));
      return;
    }

    // Wait briefly to allow call to start, then navigate to calling screen
    await Future.delayed(const Duration(seconds: 3)); // Adjust based on device response time
    context.go('/calling', extra: contact); // Pass contact data to the calling screen
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return contacts.when(
      data: (contactList) => Scaffold(
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
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _handleSOS(context, contacts),
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
                        'Tapping SOS calls your emergency contact (manual merging required)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'assets/images/logo_pink.png', // Replace with your hospital logo
                height: 50,
                width: 50,
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}