import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart'; // Import for contactsProvider

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _pickContact(BuildContext context, WidgetRef ref) async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Contact permission denied. Please enable it in settings.',
            ),
          ),
        );
        await openAppSettings();
        return;
      }
    }

    try {
      final allContacts = await FlutterContacts.getContacts(
        withProperties: true,
      ); // Fetch with basic properties
      if (allContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts found on your device.')),
        );
        return;
      }

      TextEditingController _dialogSearchController = TextEditingController();
      List<Contact> filteredContacts = allContacts;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final searchQuery = _dialogSearchController.text.toLowerCase();

            // Filter contacts based on search query
            filteredContacts = allContacts.where((contact) {
              return contact.displayName?.toLowerCase().contains(searchQuery) ??
                  false;
            }).toList();

            return AlertDialog(
              title: const Text('Select Contact'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _dialogSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search contacts...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setDialogState(
                            () {},
                          ); // Update filtered list on change
                        },
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<Contact>>(
                        future: Future.wait(
                          filteredContacts.map((contact) async {
                            final detailedContact =
                                await FlutterContacts.getContact(
                                  contact.id,
                                  withProperties: true,
                                );
                            return detailedContact ??
                                contact; // Fallback to basic contact if detailed fetch fails
                          }),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            debugPrint(
                              'Error fetching contact details: ${snapshot.error}',
                            );
                            return const ListTile(
                              title: Text('Error loading contacts'),
                            );
                          }
                          final contactsWithDetails =
                              snapshot.data
                                  ?.where((c) => c.phones.isNotEmpty)
                                  .toList() ??
                              [];
                          if (contactsWithDetails.isEmpty) {
                            return const ListTile(
                              title: Text(
                                'No matching contacts with phone numbers',
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: contactsWithDetails.length,
                            itemBuilder: (context, index) {
                              final contact = contactsWithDetails[index];
                              final phone = contact.phones.isNotEmpty
                                  ? contact.phones.first.number
                                  : 'No phone';
                              return ListTile(
                                title: Text(contact.displayName ?? 'Unknown'),
                                subtitle: Text(phone),
                                onTap: () {
                                  ref
                                      .read(contactsProvider.notifier)
                                      .addContact(
                                        contact.displayName ?? 'Unknown',
                                        phone,
                                      );
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contacts. Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    return contacts.when(
      data: (contactList) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go("/"),
          ),
          title: const Text('Manage Emergency Contacts'),
          backgroundColor: const Color(0xFF8B1E9B),
        ),
        body: ListView.builder(
          itemCount: contactList.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(contactList[index]['name']!),
              subtitle: Text(contactList[index]['phone']!),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    ref.read(contactsProvider.notifier).deleteContact(index),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _pickContact(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
