import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// CHATGPT helped with adding the validator

class BoardMenuItem {
  final String name;
  final int id;

  const BoardMenuItem({required this.name, required this.id});
}

class BoardDropdown extends StatefulWidget {
  final BoardMenuItem? value;
  final ValueChanged<BoardMenuItem?> onChanged;
  final String? Function(BoardMenuItem?)? validator;

  const BoardDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  State<BoardDropdown> createState() => _BoardDropdownState();
}

class _BoardDropdownState extends State<BoardDropdown> {
  late Future<List<BoardMenuItem>> _boardsFuture;

  @override
  void initState() {
    super.initState();
    _boardsFuture = _getBoardMenuItems();
  }

  Future<List<BoardMenuItem>> _getBoardMenuItems() async {
    final url = Uri.parse('http://localhost:8080/api/boards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      var boardList = responseBody['boards'] as List<dynamic>;

      return boardList
          .map(
            (board) => BoardMenuItem(name: board['boardName'], id: board['id']),
          )
          .toList();
    } else {
      throw Exception('Failed to load boards');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<List<BoardMenuItem>>(
          future: _boardsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final items = snapshot.data ?? [];

            return FormField<BoardMenuItem>(
              validator: widget.validator,
              initialValue: widget.value,
              builder: (formFieldState) {
                final hasError = formFieldState.hasError;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              hasError
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: DropdownMenu<BoardMenuItem>(
                        width: constraints.maxWidth,
                        initialSelection: formFieldState.value ?? widget.value,
                        onSelected: (val) {
                          formFieldState.didChange(val);
                          widget.onChanged(val);
                        },
                        dropdownMenuEntries:
                            items
                                .map(
                                  (menu) => DropdownMenuEntry<BoardMenuItem>(
                                    value: menu,
                                    label: menu.name,
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          formFieldState.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
