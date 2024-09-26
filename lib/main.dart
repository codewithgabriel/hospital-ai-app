import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Translator App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: UrlInputScreen(),
    );
  }
}

class UrlInputScreen extends StatelessWidget {
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Backend URL'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Enter Backend URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isNotEmpty) {
                  // Navigate to TranslatorScreen with the entered URL
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TranslatorScreen(backendUrl: url),
                    ),
                  );
                }
              },
              child: Text('Continue to Translator'),
            ),
          ],
        ),
      ),
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  final String backendUrl;

  TranslatorScreen({required this.backendUrl});

  @override
  _TranslatorScreenState createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  String _selectedSourceLanguage = 'en'; // Example: Nupe as source
  String _selectedTargetLanguage = 'yo'; // Example: English as target
  String _inputText = '';
  String _translatedText = 'Translation will appear here';
  bool _isLoading = false; // Loading state flag
  final TextEditingController _controller = TextEditingController();

  // Function to send a POST request to the backend URL entered by the user
  Future<void> _translateText() async {
    if (_inputText.isEmpty) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    final url = Uri.parse('${widget.backendUrl}/translate');

    // Prepare JSON body
    Map<String, String> body = {
      'tgt_lang': _selectedTargetLanguage,
      'src_lang': _selectedSourceLanguage,
      'text': _inputText,
    };

    try {
      // Send POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // If server returns OK, decode the response and display translation
        final decodedResponse = jsonDecode(response.body);
        setState(() {
          _translatedText = decodedResponse['translated_text'] ?? 'No translation available';
        });
      } else {
        // Handle error response
        setState(() {
          print(response.body);
          _translatedText = 'Error: ${response.statusCode}';
        });
      }
    } catch (error) {
      // Handle network or server error
      setState(() {
        _translatedText = 'Failed to translate: $error';
      });
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Translator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Language selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLanguageDropdown(
                    'Source Language', _selectedSourceLanguage, (value) {
                  setState(() {
                    _selectedSourceLanguage = value!;
                  });
                }),
                Icon(Icons.swap_horiz, size: 30, color: Colors.blue),
                _buildLanguageDropdown(
                    'Target Language', _selectedTargetLanguage, (value) {
                  setState(() {
                    _selectedTargetLanguage = value!;
                  });
                })
              ],
            ),
            SizedBox(height: 30),

            // Display translated text or loading indicator
            Expanded(
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator() // Show loading icon
                    : Text(
                  _translatedText,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Text input area at the bottom
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (text) {
                      setState(() {
                        _inputText = text;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter text to translate...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _translateText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for building language dropdowns
  Widget _buildLanguageDropdown(
      String label, String selectedValue, Function(String?) onChanged) {
    List<String> languages = ['nu', 'en', 'yo']; // Example languages (Nupe, English, etc.)
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedValue,
          onChanged: onChanged,
          items: languages.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
