import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class UploadImage {
  final storage = FirebaseStorage.instance;

  static Future<String?> uploadImage(imageName, Uint8List image) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child(imageName);
    try {
      var upload = await imageRef.putData(image);
      var link = await imageRef.getDownloadURL();
      print("Success");
      return link;
    } catch (e) {
      print("Failed");
      return null;
    }
  }
}
