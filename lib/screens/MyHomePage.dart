import 'dart:convert';

import 'package:chatapp/screens/AuthScreen.dart';
import 'package:chatapp/screens/HomeScreen.dart';
import 'package:chatapp/services/PushNotificationService.dart';
import 'package:chatapp/services/UploadImage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? imgLink;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return snapshot.hasData ? HomeScreen() : AuthScreen();
      },
    );
  }
}
