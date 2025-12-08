import 'package:flutter/material.dart';

class BoardMenuItem {
  final String name;
  final String author;
  final int id;

  const BoardMenuItem({
    required this.name,
    required this.author,
    required this.id,
  });
}

List<BoardMenuItem> menuItems = [
  BoardMenuItem(name: "Board A", author: "Kyle", id: 101),
  BoardMenuItem(name: "Board B", author: "Bob", id: 102),
  BoardMenuItem(name: "Board C", author: "Charlie", id: 103),
];

class BoardDropdown extends StatelessWidget {
  final BoardMenuItem? value;
  final ValueChanged<BoardMenuItem?> onChanged;

  const BoardDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<BoardMenuItem>(
          width: constraints.maxWidth,
          initialSelection: value,
          onSelected: onChanged,
          dropdownMenuEntries:
              menuItems.map((menu) {
                return DropdownMenuEntry<BoardMenuItem>(
                  value: menu,
                  label: menu.name,
                );
              }).toList(),
        );
      },
    );
  }
}
