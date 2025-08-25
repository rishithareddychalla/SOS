// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // class CallingScreen extends StatelessWidget {
// //   const CallingScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     // Retrieve contact data passed via GoRouter
// //     final contact =
// //         GoRouterState.of(context).extra as Map<String, String>? ??
// //         {'name': 'Unknown'};

// //     return WillPopScope(
// //       onWillPop: () async => false, // Prevent back button during call
// //       child: Scaffold(
// //         body: SafeArea(
// //           child: Container(
// //             decoration: const BoxDecoration(
// //               gradient: LinearGradient(
// //                 colors: [Color(0xFFD81B60), Color(0xFF8B1E9B)],
// //                 begin: Alignment.topCenter,
// //                 end: Alignment.bottomCenter,
// //               ),
// //             ),
// //             child: Center(
// //               child: SizedBox(
// //                 width: double.infinity, // Ensure full width
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Container(
// //                       width: 200,
// //                       height: 200,
// //                       decoration: BoxDecoration(
// //                         shape: BoxShape.circle,
// //                         gradient: const LinearGradient(
// //                           colors: [Color(0xFFD81B60), Color(0xFF8B1E9B)],
// //                           begin: Alignment.topCenter,
// //                           end: Alignment.bottomCenter,
// //                         ),
// //                         boxShadow: [
// //                           BoxShadow(
// //                             color: const Color(0xFFD81B60).withOpacity(0.5),
// //                             spreadRadius: 15,
// //                             blurRadius: 25,
// //                             offset: const Offset(0, 10),
// //                           ),
// //                         ],
// //                       ),
// //                       child: const Center(
// //                         child: Text(
// //                           'SOS',
// //                           style: TextStyle(
// //                             fontSize: 48,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.white,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 30),
// //                     Text(
// //                       'Calling ${contact['name']}...',
// //                       textAlign: TextAlign.center,
// //                       style: const TextStyle(
// //                         fontSize: 20,
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 10),
// //                     const Text(
// //                       'Call in progress',
// //                       textAlign: TextAlign.center,
// //                       style: TextStyle(fontSize: 16, color: Colors.white70),
// //                     ),
// //                     const SizedBox(height: 40),
// //                     Padding(
// //                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
// //                       child: ElevatedButton(
// //                         onPressed: () {
// //                           // Simulate ending the call by navigating back to main screen
// //                           // Note: Actual call termination is not supported by flutter_phone_direct_caller
// //                           context.go('/');
// //                         },
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: Colors.white,
// //                           foregroundColor: const Color(0xFFD81B60),
// //                           padding: const EdgeInsets.symmetric(
// //                             vertical: 12,
// //                             horizontal: 24,
// //                           ),
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(8.0),
// //                           ),
// //                         ),
// //                         child: const Text(
// //                           'Stop SOS',
// //                           style: TextStyle(
// //                             fontSize: 18,
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 40),
// //                     Padding(
// //                       padding: const EdgeInsets.all(16.0),
// //                       child: Image.asset(
// //                         'assets/images/logo_pink.png', // Replace with your hospital logo
// //                         height: 50,
// //                         width: 50,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CallingScreen extends StatelessWidget {
  const CallingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent user from swiping back
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD81B60), Color(0xFF8B1E9B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD81B60).withOpacity(0.5),
                            spreadRadius: 15,
                            blurRadius: 25,
                            offset: const Offset(0, 10),
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
                    const SizedBox(height: 30),
                    const Text(
                      'Contacting all emergency contacts...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sending location via SMS and initiating calls.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // This button returns to the home screen.
                          // It does not end the actual phone calls, as that must be done
                          // by the user in their native phone app.
                          context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD81B60),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Return to App',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.asset(
                        'assets/images/logo_pink.png',
                        height: 50,
                        width: 50,
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