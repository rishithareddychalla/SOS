import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart'; // Import for contactsProvider

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  Future<void> _pickContact(BuildContext context, WidgetRef ref) async {
    // Check and request contact permission
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
        await openAppSettings(); // Open settings if denied
        return;
      }
    }

    try {
      final contacts = await FlutterContacts.getContacts();
      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts found on your device.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Contact'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Contact?>(
                  future: FlutterContacts.getContact(contacts[index].id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        debugPrint('Error fetching contact: ${snapshot.error}');
                        return const ListTile(
                          title: Text('Error loading contact'),
                        );
                      }
                      final contact = snapshot.data;
                      if (contact != null && contact.phones.isNotEmpty) {
                        final phone = contact.phones.first.number;
                        return ListTile(
                          title: Text(contact.displayName),
                          subtitle: Text(phone),
                          onTap: () {
                            ref
                                .read(contactsProvider.notifier)
                                .addContact(contact.displayName, phone);
                            Navigator.pop(context); // Close the dialog
                          },
                        );
                      }
                    }
                    return const SizedBox.shrink(); // Show nothing during loading or for invalid contacts
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contacts. Error: $e')),
      ); // Removed const
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/"),
        ),
        title: const Text('Manage Emergency Contacts'),
        backgroundColor: const Color(0xFF8B1E9B),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(contacts[index]['name']!),
            subtitle: Text(contacts[index]['phone']!),
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
    );
  }
}
