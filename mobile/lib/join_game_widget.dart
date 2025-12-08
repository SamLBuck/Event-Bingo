import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/playscreen.dart';

Future<void> showJoinGameDialog(BuildContext context, [String? clickedGame]) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => JoinGameDialog(clickedGame),
  );
}

class JoinGameDialog extends StatefulWidget {
  final String? clickedGame;

  const JoinGameDialog(this.clickedGame, {super.key});

  @override
  State<JoinGameDialog> createState() => _JoinGameDialogState();
}

class _JoinGameDialogState extends State<JoinGameDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accessKeyController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _accessKeyController = TextEditingController(text: widget.clickedGame);
  }

  @override
  void dispose() {
    super.dispose();
    _accessKeyController.dispose();
  }

  Future<void> _joinGame() async {
    final url = Uri.parse(
      'http://localhost:8080/api/games/${_accessKeyController.text}/join',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playerName': _nameController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlayScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join game: ${response.statusCode}')),
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
                  'Access Key',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _accessKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter access key',
                  ),
                  validator: (value) {
                    return value == null || value.isEmpty
                        ? 'Please enter an access key'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Name',
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
                        ? 'Please enter your name'
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
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _joinGame();
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Join Game'),
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
