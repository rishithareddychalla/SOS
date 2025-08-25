import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'main.dart'; // To access the providers

class CallingScreen extends ConsumerWidget {
  const CallingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingNumbers = ref.watch(sequentialCallProvider);
    final allContacts = ref.watch(contactsProvider).value ?? [];
    
    String statusText;
    if (remainingNumbers.isNotEmpty) {
      final currentNumber = remainingNumbers.first;
      final contactName = allContacts.firstWhere(
        (c) => c['phone'] == currentNumber,
        orElse: () => {'name': 'Unknown'},
      )['name'];
      statusText = 'Calling $contactName...\\n($currentNumber)';
    } else {
      statusText = 'Finished calling all emergency contacts.';
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD81B60), Color(0xFF8B1E9B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      // ... (rest of UI is the same)
                    ),
                    const SizedBox(height: 30),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (remainingNumbers.isNotEmpty)
                      const Text(
                        'Waiting for call to end before trying next number...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(sequentialCallProvider.notifier).stopSOS();
                          context.go('/');
                        },
                        // ... (rest of button is the same)
                        child: Text(
                          remainingNumbers.isNotEmpty ? 'Stop SOS' : 'Return to Home',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
