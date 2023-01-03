import 'package:chat_bubbles/bubbles/bubble_special_one.dart';
import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:chatapp/screens/ImageViewerScreen.dart';
import 'package:chatapp/services/PushNotificationService.dart';
import 'package:chatapp/services/UploadImage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final name, img, uid, fcmToken;
  ChatScreen(
      {required this.name,
      required this.img,
      required this.uid,
      required this.fcmToken});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  var _message = "";
  String chatroom = "";
  String reply = "";
  TextEditingController _msgC = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser!.uid.codeUnitAt(0) >
        widget.uid.codeUnitAt(0)) {
      chatroom = FirebaseAuth.instance.currentUser!.uid + widget.uid;
    } else {
      chatroom = widget.uid + FirebaseAuth.instance.currentUser!.uid;
    }
  }

  sendMessage(msg, type, r) async {
    setState(() {
      _msgC.clear();
      _message = "";
    });
    var data = {
      "message": msg,
      "type": type,
      "from": FirebaseAuth.instance.currentUser!.uid,
      "seen": false,
      "reply": r,
      "time": FieldValue.serverTimestamp()
    };
    setState(() {
      reply = "";
    });
    await FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatroom)
        .collection('chats')
        .add(data);
    var mydata = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    await FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatroom)
        .set({FirebaseAuth.instance.currentUser!.uid: ""});
    data['name'] = mydata.data()!['name'];
    data['img'] = mydata.data()!['img'];
    data['uid'] = mydata.id;
    data['fcmToken'] = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('recentchats')
        .doc(chatroom)
        .set(data);
    data['name'] = widget.name;
    data['img'] = widget.img;
    data['uid'] = widget.uid;
    data['fcmToken'] = widget.fcmToken;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('recentchats')
        .doc(chatroom)
        .set(data);
    PushNotificationService.pushNotification(
        mydata.data()!['name'] + " sent a message",
        _message == "" ? "Image" : _message,
        widget.fcmToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(4.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage(widget.img),
          ),
        ),
        title: Text(widget.name),
      ),
      body: Column(
        children: [
          Flexible(
              child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('chatrooms')
                .doc(chatroom)
                .collection('chats')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              return !(snapshot.hasData)
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container(
                      child: AnimatedList(
                          physics: BouncingScrollPhysics(),
                          reverse: true,
                          padding: EdgeInsets.all(10),
                          initialItemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, i, animation) {
                            if (snapshot.data!.docs[i]['from'] !=
                                FirebaseAuth.instance.currentUser!.uid) {
                              snapshot.data!.docs[i].reference
                                  .update({'seen': true});
                            }
                            return snapshot.data!.docs[i]['type'] == 'text'
                                ? InkWell(
                                    onDoubleTap: () {
                                      setState(() {
                                        reply =
                                            snapshot.data!.docs[i]['message'];
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: snapshot.data!.docs[i]
                                                      ['reply'] ==
                                                  ""
                                              ? Colors.transparent
                                              : Theme.of(context).focusColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Text(
                                                snapshot.data!.docs[i]['reply'],
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            BubbleSpecialOne(
                                              sent: snapshot.data!.docs[i]
                                                      ['from'] ==
                                                  FirebaseAuth.instance
                                                      .currentUser!.uid,
                                              tail: i + 1 ==
                                                  snapshot.data!.docs.length,
                                              seen: snapshot.data!.docs[i]
                                                          ['from'] ==
                                                      FirebaseAuth.instance
                                                          .currentUser!.uid
                                                  ? snapshot.data!.docs[i]
                                                      ['seen']
                                                  : false,
                                              textStyle: TextStyle(
                                                color: snapshot.data!.docs[i]
                                                            ['from'] ==
                                                        FirebaseAuth.instance
                                                            .currentUser!.uid
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              text: snapshot.data!.docs[i]
                                                  ['message'],
                                              isSender: snapshot.data!.docs[i]
                                                      ['from'] ==
                                                  FirebaseAuth.instance
                                                      .currentUser!.uid,
                                              color: snapshot.data!.docs[i]
                                                          ['from'] ==
                                                      FirebaseAuth.instance
                                                          .currentUser!.uid
                                                  ? Theme.of(context)
                                                      .primaryColorDark
                                                  : Colors.white70,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      alignment: snapshot.data!.docs[i]
                                                  ['from'] ==
                                              FirebaseAuth
                                                  .instance.currentUser!.uid
                                          ? Alignment.bottomRight
                                          : Alignment.bottomLeft,
                                      height:
                                          MediaQuery.of(context).size.height /
                                              3,
                                      width: MediaQuery.of(context).size.width /
                                          1.5,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ImageViewerScreen(
                                                          snapshot.data!.docs[i]
                                                              ['message'])));
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                          ),
                                          padding: EdgeInsets.all(8),
                                          child: Image.network(
                                            snapshot.data!.docs[i]['message'],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                          }),
                    );
            },
          )),
          Container(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chatrooms')
                  .doc(chatroom)
                  .snapshots(),
              builder: (context, snap) => snap.hasData && snap.data!.exists
                  ? snap.data!.data()![widget.uid] != null
                      ? BubbleSpecialThree(
                          textStyle: TextStyle(fontStyle: FontStyle.italic),
                          text: "${snap.data!.data()![widget.uid]}...",
                          isSender: false)
                      : SizedBox()
                  : SizedBox(),
            ),
          ),
          Container(
              color: Theme.of(context).primaryColorDark,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    reply == ""
                        ? SizedBox()
                        : Row(
                            children: [
                              Flexible(
                                child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).hintColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.all(4),
                                    width: double.infinity,
                                    child: Text(
                                      reply,
                                      style: TextStyle(color: Colors.white),
                                    )),
                              ),
                              SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    reply = "";
                                  });
                                },
                                child: Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                ),
                              )
                            ],
                          ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).backgroundColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _msgC,
                                onSubmitted: (s) =>
                                    sendMessage(_message, 'text', reply),
                                onChanged: (txt) async {
                                  await FirebaseFirestore.instance
                                      .collection('chatrooms')
                                      .doc(chatroom)
                                      .set({
                                    FirebaseAuth.instance.currentUser!.uid: txt
                                  });
                                  setState(() {
                                    _message = txt;
                                  });
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Enter message here",
                                ),
                              )),
                        ),
                        const SizedBox(width: 5),
                        _message.isNotEmpty
                            ? AnimatedContainer(
                                duration: Duration(seconds: 1),
                                child: InkWell(
                                    onTap: () =>
                                        sendMessage(_message, 'text', reply),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                    )),
                              )
                            : AnimatedContainer(
                                duration: Duration(seconds: 1),
                                child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextButton(
                                                    onPressed: () async {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  CircularProgressIndicator(),
                                                                  Text(
                                                                      "Sendiing....")
                                                                ],
                                                              ),
                                                            );
                                                          });
                                                      var picked = await ImagePicker
                                                          .platform
                                                          .getImage(
                                                              source:
                                                                  ImageSource
                                                                      .camera);
                                                      var file = await picked!
                                                          .readAsBytes();
                                                      var link = await UploadImage
                                                          .uploadImage(
                                                              'images/' +
                                                                  DateTime.now()
                                                                      .toString() +
                                                                  '.jpg',
                                                              file);
                                                      await sendMessage(
                                                          link, 'image', reply);
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text("Camera")),
                                                TextButton(
                                                    onPressed: () async {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  CircularProgressIndicator(),
                                                                  Text(
                                                                      "Sendiing....")
                                                                ],
                                                              ),
                                                            );
                                                          });
                                                      var picked = await ImagePicker
                                                          .platform
                                                          .getImage(
                                                              source:
                                                                  ImageSource
                                                                      .gallery);
                                                      var file = await picked!
                                                          .readAsBytes();
                                                      var link = await UploadImage
                                                          .uploadImage(
                                                              'images/' +
                                                                  DateTime.now()
                                                                      .toString() +
                                                                  '.jpg',
                                                              file);
                                                      await sendMessage(
                                                          link, 'image', reply);
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text("Gallary")),
                                              ],
                                            );
                                          });
                                    },
                                    child: const Icon(Icons.camera,
                                        color: Colors.white)),
                              )
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
