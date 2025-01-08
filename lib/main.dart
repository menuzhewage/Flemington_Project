import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/account_officer.dart';
import 'pages/md_officer.dart';
import 'pages/perchase_officer.dart';
import 'pages/site_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var userRole = "MD";
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: userRole == 'Site'
    ? SitePage()
    : userRole == 'PurchaseOfficer'
        ? PurchaseOfficerPage()
        : userRole == 'AccountsOfficer'
            ? AccountsOfficerPage()
            : userRole == 'MD'
                ? MDPage()
                : Placeholder(),

    );
  }
}
