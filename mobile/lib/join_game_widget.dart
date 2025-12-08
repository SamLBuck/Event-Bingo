import 'package:flutter/material.dart';
import 'board_dropdown_widget.dart';

Future<void> showJoinGameDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const JoinGameDialog(),
  );
}

// class MenuItem {
//   final String name;
//   final String author;
//   final int id;

//   const MenuItem({required this.name, required this.author, required this.id});
// }

// List<MenuItem> menuItems = [
//   MenuItem(name: "Board A", author: "Kyle", id: 101),
//   MenuItem(name: "Board B", author: "Bob", id: 102),
//   MenuItem(name: "Board C", author: "Charlie", id: 103),
// ];

class JoinGameDialog extends StatefulWidget {
  const JoinGameDialog({super.key});

  @override
  State<JoinGameDialog> createState() => _JoinGameDialogState();
}

class _JoinGameDialogState extends State<JoinGameDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController accessKeyController = TextEditingController();
  BoardMenuItem? selectedBoard;

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
                  controller: accessKeyController,
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter Password (optional)',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'UUID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter UUID',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a positive integer';
                    } else {
                      var parsedValue = int.tryParse(value);
                      if (parsedValue == null || parsedValue < 0) {
                        return 'Please enter a positive integer';
                      } else {
                        return null;
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Board',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                BoardDropdown(
                  value: selectedBoard,
                  onChanged: (menu) {
                    setState(() {
                      selectedBoard = menu;
                    });
                  },
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Process the join game action here
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
