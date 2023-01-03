import 'package:chatapp/services/UploadImage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  Map<String, dynamic> data = {};
  bool isSignUp = true;
  bool loading = false;
  var pickedImg;

  signin(email, password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential != null) {
        var fcmToken = await FirebaseMessaging.instance.getToken();
        FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'fcmToken': fcmToken});
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        loading = false;
      });
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Theme.of(context).errorColor,
            content: Text('No user found for that email.')));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Theme.of(context).errorColor,
            content: Text('Wrong password provided for that user.')));
      }
    }
  }

  signup(name, email, password, picked) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      var img = await UploadImage.uploadImage(
          'profile_images/${userCredential.user!.uid}.jpg',
          picked!.files[0].bytes!);
      var fcmToken = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        "name": name,
        "email": email,
        "password": password,
        "fcmToken": fcmToken,
        "img": img
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        loading = false;
      });
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Theme.of(context).errorColor,
            content: Text('The password provided is too weak.')));
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Theme.of(context).errorColor,
            content: Text('The account already exists for that email.')));
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).errorColor,
          content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const Text(
              "Authentication",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.all(10),
                  children: [
                    isSignUp
                        ? InkWell(
                            onTap: () async {
                              pickedImg = await FilePicker.platform.pickFiles(
                                  withData: true, allowCompression: true);
                              setState(() {});
                            },
                            child: pickedImg == null
                                ? Icon(Icons.add_a_photo)
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    height: 100,
                                    child: Image.memory(
                                      pickedImg!.files[0].bytes ?? "",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                          )
                        : SizedBox(),
                    isSignUp
                        ? TextField(
                            onChanged: (txt) => data['name'] = txt,
                            decoration: const InputDecoration(
                              label: Text("Name"),
                            ),
                          )
                        : const SizedBox(),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (txt) => data['email'] = txt,
                      decoration: const InputDecoration(
                        label: Text("Email"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      onChanged: (txt) => data['password'] = txt,
                      decoration: const InputDecoration(
                        label: Text("Password"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    loading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                loading = true;
                              });
                              if (isSignUp) {
                                if (pickedImg != null) {
                                  signup(data['name'], data['email'],
                                      data['password'], pickedImg);
                                } else {
                                  setState(() {
                                    loading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          backgroundColor:
                                              Theme.of(context).errorColor,
                                          content: Text(
                                              'Please Upload profile image.')));
                                }
                              } else {
                                signin(data['email'], data['password']);
                              }
                            },
                            child: Text(isSignUp ? "Sign Up" : "Login")),
                    const SizedBox(height: 10),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            isSignUp = !isSignUp;
                          });
                        },
                        child: Text(isSignUp
                            ? "Already have account"
                            : "Create Account"))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
