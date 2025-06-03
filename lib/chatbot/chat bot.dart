import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class Chatbot extends StatefulWidget {
  final String? initialQuery;

  const Chatbot({super.key, this.initialQuery});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final GenerativeModel _healthCheckModel;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _initializeModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _handleSubmitted(widget.initialQuery!);
      }
    });
  }

  void _initializeModel() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyCIim6KXFVA9X3neJopSkgh0QRmwt4NQ7k', // TODO: Securely store API key
    );

    _healthCheckModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyCIim6KXFVA9X3neJopSkgh0QRmwt4NQ7k',
    );

    _chat = _model.startChat();
  }

  Future<bool> _shouldRespond(String text) async {
    try {
      final prompt = """
      Analyze the following user input and determine if:
      1. It's a general greeting (like hello, hi, etc.) - respond with "greeting"
      2. It's related to health, medical, or wellness topics - respond with "health"
      3. Otherwise - respond with "other"

      Input: "$text"
      """;

      final response = await _healthCheckModel.generateContent([
        Content.text(prompt),
      ]);
      final responseText = response.text?.toLowerCase() ?? 'other';

      return responseText.contains('greeting') || responseText.contains('health');
    } catch (e) {
      print('Content check error: $e');
      return false;
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    try {
      final shouldRespond = await _shouldRespond(text);

      if (!shouldRespond) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text:
              "I specialize in health-related topics. Please ask me about health, medical, or wellness questions, or say hello!",
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        return;
      }

      final response = await _chat.sendMessage(Content.text(text));
      final responseText = response.text ?? 'No response from AI';

      setState(() {
        _messages.insert(0, ChatMessage(text: responseText, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.insert(0, ChatMessage(text: 'Error: $e', isUser: false));
        _isLoading = false;
      });

      print('Error details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Health Chatbot'),
        backgroundColor:Color(0xFF4BA1AE),
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4BA1AE),
              Color(0xFF73B5C1),
              Color(0xFF82BDC8),
              Color(0xFF92C6CF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) => _messages[index],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            const Divider(height: 1, color: Colors.white54),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildTextComposer(),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: const IconThemeData(color: Color(0xFF4BA1AE)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration(
                  hintText: 'Ask a health question or say hello...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 12.0,
                  ),
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isUser
              ? Container()
              : Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xB6286E7A),
              child: const Icon(Icons.medical_services, color: Colors.white),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'Health AI',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Color(0x5AFFFFFF)
                        : Color(0x90FFFFFF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          isUser
              ? Container(
            margin: const EdgeInsets.only(left: 16.0),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF4BA1AE),
              child: Icon(Icons.person, color: Colors.white),
            ),
          )
              : Container(),
        ],
      ),
    );
  }
}