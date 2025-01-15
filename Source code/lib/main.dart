import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:manga_made_v2/firebase_options.dart';
import 'package:manga_made_v2/screens/adminScreen.dart';
import 'package:manga_made_v2/screens/navigationScreen.dart';

import 'package:manga_made_v2/screens/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MangaMadeAppp());
}

class MangaMadeAppp extends StatefulWidget {
  const MangaMadeAppp({super.key});

  @override
  State<MangaMadeAppp> createState() => _MangaMadeApppState();
}

class _MangaMadeApppState extends State<MangaMadeAppp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData) {
            var userId = snapshot.data!.uid;

            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                var data = snapshot.data!.data()!;
                if (data['type'] == 'admin') {
                  return const AdminScreen();
                } else if (data['type'] == 'user') {
                  return const NavigationScreen();
                }
                return const SplashScreenView();
              },
            );
          }

          return const SplashScreenView();
        },
      ),
      builder: EasyLoading.init(),
    );
  }
}
