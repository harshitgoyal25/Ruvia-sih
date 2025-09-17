import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruvia ChatBot',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruvia Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => showChatBotPanel(context),
          child: const Text('Open Chat with Coach AI'),
        ),
      ),
    );
  }
}

void showChatBotPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ChatBotDraggablePanel(),
  );
}

class ChatBotDraggablePanel extends StatefulWidget {
  const ChatBotDraggablePanel({super.key});

  @override
  State<ChatBotDraggablePanel> createState() => _ChatBotDraggablePanelState();
}

class _ChatBotDraggablePanelState extends State<ChatBotDraggablePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      // If at min scroll extent and user is dragging downward
      if (_scrollController.position.pixels <=
              _scrollController.position.minScrollExtent &&
          _scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.99,
      expand: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF232323),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ChatBotPanel(scrollController: _scrollController),
        );
      },
    );
  }
}

class ChatBotPanel extends StatefulWidget {
  final ScrollController scrollController;
  const ChatBotPanel({super.key, required this.scrollController});

  @override
  State<ChatBotPanel> createState() => _ChatBotPanelState();
}

class _ChatBotPanelState extends State<ChatBotPanel> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  List<Map<String, dynamic>>? _runData;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserRuns();
  }

  Future<void> _fetchUserRuns() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      _userId = user.uid;

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('runs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      _runData = query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _runData = [];
      _userId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading runs: $e')));
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<String> getBotReply(String userMsg) async {
    setState(() => _loading = true);

    String history = (_runData != null && _runData!.isNotEmpty)
        ? "Here are my last runs:\n" +
              _runData!
                  .map((run) {
                    var area = run['areaCaptured']?.toString() ?? 'unknown';
                    var distance = run['distance']?.toString() ?? 'unknown';
                    var pace = run['pace']?.toString() ?? 'unknown';
                    var time = run['timeTaken']?.toString() ?? 'unknown';
                    var ts = run['timestamp'];
                    String dateStr = ts?.toString() ?? "unknown";
                    return "Distance: $distance meters, Pace: $pace m/min, Time: $time min, Date: $dateStr, Area: $area";
                  })
                  .join("\n") +
              "\n"
        : "I have no recent run data.\n";

    String prompt =
        "You are a certified fitness coach. Here is my running data:\n$history\nUser question: $userMsg";

    try {
      const String groqApiKey =
          "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";
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are Ruvia Coach AI, a professional running and fitness coach. Provide concise, motivational advice referencing user run history.",
            },
            {"role": "user", "content": prompt},
          ],
          "max_tokens": 450,
          "temperature": 0.7,
          "top_p": 1,
        }),
      );
      setState(() => _loading = false);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final aiReply = decoded["choices"][0]["message"]["content"];
        return aiReply.trim();
      } else {
        print("Groq API error: ${response.statusCode} ${response.body}");
        return "Sorry, couldn't connect to Coach AI (code ${response.statusCode}).";
      }
    } catch (e) {
      setState(() => _loading = false);
      print("Groq error: $e");
      return "Error connecting to Coach AI: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            "Chat with Coach AI",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: _loading && _runData == null
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF79c339)),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[_messages.length - 1 - i];
                      return Align(
                        alignment: msg["from"] == "user"
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 6,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: msg["from"] == "user"
                                ? const Color(0xFF79c339)
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg["text"] ?? "",
                            style: TextStyle(
                              color: msg["from"] == "user"
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ask a running/fitness question...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.white12,
                    filled: true,
                  ),
                  onSubmitted: _loading
                      ? null
                      : (msg) async {
                          if (msg.trim().isEmpty) return;
                          setState(() {
                            _messages.add({"from": "user", "text": msg.trim()});
                          });
                          _controller.clear();
                          String aiAnswer = await getBotReply(msg.trim());
                          setState(() {
                            _messages.add({"from": "bot", "text": aiAnswer});
                          });
                        },
                ),
              ),
              const SizedBox(width: 8),
              _loading
                  ? const CircularProgressIndicator(
                      color: Color(0xFF79c339),
                      strokeWidth: 2,
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF79c339)),
                      onPressed: () async {
                        String msg = _controller.text.trim();
                        if (msg.isEmpty) return;
                        setState(() {
                          _messages.add({"from": "user", "text": msg});
                        });
                        _controller.clear();
                        String aiAnswer = await getBotReply(msg);
                        setState(() {
                          _messages.add({"from": "bot", "text": aiAnswer});
                        });
                      },
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
