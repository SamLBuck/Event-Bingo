import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/board_dropdown_widget.dart';

// Thanks ChatGPT for helping me turn this into a popup dialog!

Future<void> showCreateGameDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const CreateGameDialog(),
  );
}

class CreateGameDialog extends StatefulWidget {
  const CreateGameDialog({super.key});

  @override
  State<CreateGameDialog> createState() => _CreateGameDialogState();
}

class _CreateGameDialogState extends State<CreateGameDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  BoardMenuItem? _selectedBoard;

  Future<void> _createGame() async {
    final url = Uri.parse('http://localhost:8080/api/games');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hostPlayerName': _nameController.text,
        'boardId': _selectedBoard!.id, // null should be checked on validator
        'isPublic': _passwordController.text.isEmpty,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create game: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Text(
                  'Host Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your name',
                  ),
                  validator: (value) {
                    return value == null || value.isEmpty
                        ? 'Please enter a name'
                        : null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Password (optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter Password (optional)',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Board',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                BoardDropdown(
                  value: _selectedBoard,
                  onChanged: (v) => setState(() => _selectedBoard = v),
                  validator: (value) {
                    if (value == null) return 'Please select a board';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _createGame();
                        Navigator.pop(context); // close popup
                      }
                    },
                    child: const Text('Create Game'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
