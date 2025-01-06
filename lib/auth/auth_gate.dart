
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flemington_project/pages/homepage.dart';
import 'package:flutter/material.dart';

import 'login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Homepage();
          } else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
