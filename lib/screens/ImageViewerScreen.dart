import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final img;
  const ImageViewerScreen(this.img);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InteractiveViewer(child: Image.network(img)),
    );
  }
}
