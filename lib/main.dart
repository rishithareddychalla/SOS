import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'contacts_screen.dart';

// Riverpod provider for contacts
final contactsProvider = StateNotifierProvider<ContactsNotifier, List<Map<String, String>>>((ref) {
  return ContactsNotifier();
});

class ContactsNotifier extends StateNotifier<List<Map<String, String>>> {
  ContactsNotifier() : super([]) {
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      state = List<Map<String, String>>.from(json.decode(contactsJson));
    }
  }

  Future<void> addContact(String name, String phone) async {
    state = [...state, {'name': name, 'phone': phone}];
    _saveContacts();
  }

  Future<void> deleteContact(int index) async {
    state = List.from(state)..removeAt(index);
    _saveContacts();
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('contacts', json.encode(state));
  }
}

// GoRouter setup
final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/contacts', builder: (context, state) => const ContactsScreen()),
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
          headlineMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
      routerConfig: router,
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  Future<void> _handleSOS(BuildContext context, List<Map<String, String>> contacts) async {
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No emergency contacts added!')));
      return;
    }

    // Initiate calls to all contacts sequentially using flutter_phone_direct_caller
    for (var contact in contacts) {
      bool? res = await FlutterPhoneDirectCaller.callNumber(contact['phone']!);
      if (res != true) {
        debugPrint('Failed to call ${contact['phone']}');
      }
      await Future.delayed(const Duration(seconds: 1)); // Delay between calls
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS'),
        backgroundColor: const Color(0xFF8B1E9B),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
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
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tapping SOS calls your emergency contacts (manual merging required)',
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
    );
  }
}