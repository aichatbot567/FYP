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
  bool _isModelInitialized = false;
  GenerativeModel? _model;
  ChatSession? _chat;

  @override
  void initState() {
    super.initState();
    _initializeModel().then((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _handleSubmitted(widget.initialQuery!);
      }
    });
  }

  Future<void> _initializeModel() async {
    try {
      const apiKey = "AIzaSyCuUj8UFsH6GsWXxPcxzO4Koy8XUWjfjtA";
      if (apiKey.isEmpty) {
        throw Exception('Please set your Google AI API key');
      }

      _model = GenerativeModel(
        model: 'gemini-2.0-flash', // Free tier model
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 1000, // Reduced to stay within limits
          temperature: 0.7,
          topP: 0.9,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      // Test the API key with a simple request
      final testResponse = await _model!.generateContent([
        Content.text("Hello")
      ]);

      if (testResponse.text == null) {
        throw Exception('API key test failed - no response received');
      }

      _chat = _model?.startChat(
        history: [
          Content.text(
              "You are a helpful health assistant. Specialize in medical, wellness, and health-related topics. "
                  "Be concise but accurate. For non-health questions, politely redirect to health topics. "
                  "Always remind users to consult healthcare professionals for serious medical concerns."),
        ],
      );

      setState(() {
        _isModelInitialized = true;
      });
    } catch (e) {
      debugPrint('Model initialization error: $e');
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: "Failed to initialize AI service. Please check your API key and internet connection.",
            isUser: false,
          ),
        );
      });
    }
  }

  Future<bool> _isHealthRelated(String text) async {
    if (!_isModelInitialized || _model == null) return false;

    try {
      // Create a separate model instance for content checking to avoid interfering with chat
      final checkModel = GenerativeModel(
        model: 'gemini-1.5-flash', // Free tier model
        apiKey: "AIzaSyCzoGa35PSsLQp39BjNMUfQhnuM23Uwfm8", // Your existing API key
      );

      final prompt = """
      Analyze if this input is health-related (medical, wellness, fitness, nutrition, mental health) or a general greeting.
      Respond ONLY with "health", "greeting", or "other":
      
      "$text"
      """;

      final response = await checkModel.generateContent([Content.text(prompt)]);
      final responseText = response.text?.toLowerCase().trim() ?? 'other';

      return responseText.contains('health') || responseText.contains('greeting');
    } catch (e) {
      debugPrint('Content check error: $e');
      // If content check fails, allow the message through to avoid blocking legitimate health queries
      return true;
    }
  }

  void _handleSubmitted(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    if (!_isModelInitialized || _chat == null) {
      _showError("AI service is not ready. Please wait or restart the app.");
      return;
    }

    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: trimmedText, isUser: true));
      _isLoading = true;
    });

    try {
      final isRelevant = await _isHealthRelated(trimmedText);

      if (!isRelevant) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: "I specialize in health topics. Ask me about nutrition, "
                  "fitness, medical conditions, mental health, or general wellness advice!",
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        return;
      }

      final response = await _chat!.sendMessage(Content.text(trimmedText));
      final responseText = response.text ?? 'Sorry, I couldn\'t process that. Please try rephrasing your question.';

      setState(() {
        _messages.insert(0, ChatMessage(text: responseText, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in _handleSubmitted: $e');
      String errorMessage = "I'm having trouble processing your request. ";

      if (e.toString().contains('API_KEY')) {
        errorMessage += "Please check the API key configuration.";
      } else if (e.toString().contains('quota') || e.toString().contains('limit')) {
        errorMessage += "API quota exceeded. Please try again later.";
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage += "Please check your internet connection.";
      } else {
        errorMessage += "Please try again.";
      }

      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: errorMessage,
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: message,
          isUser: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Chatbot',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4BA1AE),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4BA1AE),
                    Color(0xFF73B5C1),
                    Color(0xFF92C6CF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _messages.isEmpty
                  ? _buildWelcomeMessage()
                  : ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _messages[index],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Color(0xFF4BA1AE),
              padding: const EdgeInsets.all(16.0),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF43D7E8),
                    strokeWidth: 2,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Thinking...",
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              "Welcome to Health Chatbot!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Ask me about nutrition, fitness, wellness, or any health-related questions.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color:Color(0xFF4BA1AE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: _isModelInitialized && !_isLoading,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isModelInitialized
                      ? 'Ask a health question...'
                      : 'Initializing AI...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Color(0xFF8ACCDA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: _isModelInitialized && !_isLoading
                  ? const Color(0xFF4BA1AE)
                  : Colors.grey[400],
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isModelInitialized && !_isLoading
                    ? () => _handleSubmitted(_textController.text)
                    : null,
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isUser ? const Color(0xFF4BA1AE) : const Color(0xFF286E7A),
                  child: Icon(
                    isUser ? Icons.person : Icons.medical_services,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.white.withOpacity(0.9) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                      topRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                      bottomLeft: const Radius.circular(18),
                      bottomRight: const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}