import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  ChatBubble(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2,
      constraints: BoxConstraints(
        maxWidth: 50,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
        ),
        child: Text(message),
      ),
    );
  }
}
