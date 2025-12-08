import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final TextEditingController _accessKeyController = TextEditingController();
  final TextEditingController _maxPlayersController = TextEditingController();

  Future<void> _createGame() async {
    final url = Uri.parse('http://localhost:8080/api/games');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hostPlayerName': _nameController.text,
        'accessKey': _accessKeyController.text,
        'maxPlayers': int.parse(_maxPlayersController.text),
      }),
    );
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
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter game name',
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
                  controller: _accessKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter Password (optional)',
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Max Players',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _maxPlayersController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter maximum number of players',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a number';
                    }
                    final n = int.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // DropdownMenu<BoardListEntry>(
                //   initialSelection: ,
                // )
                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: handle create-game logic using:
                        // nameController.text
                        // accessKeyController.text
                        // maxPlayersController.text

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
