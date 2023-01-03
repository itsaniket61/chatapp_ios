import 'package:chatapp/screens/ChatScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddUser extends StatelessWidget {
  const AddUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add User")),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .get(),
        builder: (context, snapshot) {
          return !snapshot.hasData
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : snapshot.data!.docs.length > 0
                  ? ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: ((context, index) => InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                            name: snapshot.data!.docs[index]
                                                ['name'],
                                            img: snapshot.data!.docs[index]
                                                ['img'],
                                            uid: snapshot.data!.docs[index].id,
                                            fcmToken: snapshot.data!.docs[index]
                                                ['fcmToken'],
                                          )));
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    snapshot.data!.docs[index]['img']),
                              ),
                              title: Text(snapshot.data!.docs[index]['name']),
                              subtitle: Text("Tap to chat"),
                            ),
                          )))
                  : Center(
                      child: Text("No data found"),
                    );
        },
      ),
    );
  }
}
