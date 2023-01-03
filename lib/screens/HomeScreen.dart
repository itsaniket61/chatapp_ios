import 'package:chatapp/screens/AddUser.dart';
import 'package:chatapp/screens/ChatScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat App"),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => AddUser()));
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.person_add),
            ),
          ),
          InkWell(
            onTap: () {
              FirebaseAuth.instance.signOut();
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('recentchats')
            .orderBy('time', descending: true)
            .snapshots(),
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
                                          uid: snapshot.data!.docs[index]
                                              ['uid'],
                                          fcmToken: snapshot.data!.docs[index]
                                              ['fcmToken'])));
                            },
                            child: Dismissible(
                              onDismissed: (d) async {
                                var chatroom = "";
                                if (FirebaseAuth.instance.currentUser!.uid
                                        .codeUnitAt(0) >
                                    snapshot.data!.docs[index]['uid']
                                        .codeUnitAt(0)) {
                                  chatroom =
                                      FirebaseAuth.instance.currentUser!.uid +
                                          snapshot.data!.docs[index]['uid'];
                                } else {
                                  chatroom = snapshot.data!.docs[index]['uid'] +
                                      FirebaseAuth.instance.currentUser!.uid;
                                }
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(snapshot.data!.docs[index]['uid'])
                                    .collection('recentchats')
                                    .doc(chatroom)
                                    .delete();

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('recentchats')
                                    .doc(chatroom)
                                    .delete();

                                var docs = await FirebaseFirestore.instance
                                    .collection('chatrooms')
                                    .doc(chatroom)
                                    .collection('chats')
                                    .get();
                                var batch =
                                    await FirebaseFirestore.instance.batch();
                                for (var doc in docs.docs) {
                                  batch.delete(doc.reference);
                                }
                                await batch.commit();
                              },
                              background: Container(
                                color: Colors.red,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 30,
                                      color: Colors.white,
                                    )
                                  ],
                                ),
                              ),
                              key: UniqueKey(),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      snapshot.data!.docs[index]['img']),
                                ),
                                title: Text(snapshot.data!.docs[index]['name']),
                                subtitle: Text(
                                  snapshot.data!.docs[index]['message'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
