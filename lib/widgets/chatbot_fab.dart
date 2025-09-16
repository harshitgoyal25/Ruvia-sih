import 'package:flutter/material.dart';

class ChatBotFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const ChatBotFAB({super.key, required this.onPressed});

  // Widget build(BuildContext context) {
  //   return FloatingActionButton(
  //     heroTag: "chatbot_fab",
  //     onPressed: onPressed,
  //     backgroundColor: const Color(0xFF79c339),
  //     child: const Icon(Icons.support_agent, color: Colors.black),
  //     tooltip: "Chat with Coach AI",
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
        shape: BoxShape.circle,
      ),
      child: FloatingActionButton(
        heroTag: "chatbot_fab",
        onPressed: onPressed,
        backgroundColor: const Color(0xFF79c339),
        child: const Icon(Icons.support_agent, color: Colors.black),
        tooltip: "Chat with Coach AI",
      ),
    );
  }
}
// To add a drop shadow, wrap the FloatingActionButton in a Container with BoxShadow.