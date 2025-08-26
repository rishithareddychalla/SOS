import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart'; // Import for contactsProvider

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return contacts.when(
      data: (contactList) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go("/"),
          ),
          title: const Text(
            'Manage Emergency Contacts',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFB51963),
        ),
        body: ListView.builder(
          itemCount: contactList.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                contactList[index]['name']!,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                contactList[index]['phone']!,
                style: TextStyle(color: Colors.grey[900]),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.grey[800]),
                onPressed: () =>
                    ref.read(contactsProvider.notifier).deleteContact(index),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xFFFB51963),
          onPressed: () => _pickContact(context, ref),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _pickContact(BuildContext context, WidgetRef ref) async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Contact permission is required to select contacts.',
              ),
            ),
          );
          await openAppSettings();
        }
        return;
      }
    }

    try {
      final allContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (allContacts.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contacts found on your device.')),
          );
        }
        return;
      }

      final validContacts = allContacts
          .where((c) => c.phones.isNotEmpty)
          .toList();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              _ContactSelectionDialog(contacts: validContacts),
        );
      }
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts. Error: $e')),
        );
      }
    }
  }
}

class _ContactSelectionDialog extends ConsumerStatefulWidget {
  final List<Contact> contacts;

  const _ContactSelectionDialog({required this.contacts});

  @override
  _ContactSelectionDialogState createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState
    extends ConsumerState<_ContactSelectionDialog> {
  late List<Contact> _filteredContacts;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        return contact.displayName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // soft rounded corners
      ),
      backgroundColor: Colors.grey[50], // subtle background
      title: const Text(
        'Select a Contact',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // cleaner look
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredContacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching contacts found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final phone = contact.phones.first.number;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              contact.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              phone,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              ref
                                  .read(contactsProvider.notifier)
                                  .addContact(contact.displayName, phone);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Color(0xFFFB51963)),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
