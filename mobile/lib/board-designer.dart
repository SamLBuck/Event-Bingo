import 'package:flutter/material.dart';
import 'package:mobile/home_screen.dart';
import 'package:mobile/playscreen.dart';

import institute.hopesoftware.hope_bingo.model.Board;


// import institute.hopesoftware.hope_bingo.model.Board;

class BoardTilesPage extends StatefulWidget {
  BoardTilesPage({super.key, this.title = 'Board'});
  final tiles = List<String>.generate(
    5 * 5,
    (i) => '${i ~/ 5 + 1}${i % 5 + 1}',
  );
  final String title;

  @override
  State<BoardTilesPage> createState() => _BoardTilesPageState();
}

class _BoardTilesPageState extends State<BoardTilesPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final List<String> _tiles;
  late final int _size;

  @override
  void initState() {
    super.initState();
    _size = 5;
    _tiles = List<String>.from(widget.tiles);
    _nameCtrl = TextEditingController(text: widget.title);
    _descCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  int get _filledCount => _tiles.where((t) => t.trim().isNotEmpty).length;

  Future<void> _editTile(BuildContext context, int index) async {
    final controller = TextEditingController(text: _tiles[index]);
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Put an event'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 40,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
              decoration: const InputDecoration(
                hintText: 'Enter tile text',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => controller.text = '',
                child: const Text('Clear'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (result != null) {
      setState(() => _tiles[index] = result);
    }
  }

  void _onCreatePressed() {
    final boardName = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final tiles = _tiles.where((t) => t.trim().isNotEmpty).toSet();



    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          ),
        ),
      );
    
    // Navigator.of(context).pushNamed(
    //   '/board',
    //   arguments: {
    //     'id': 'demo_${DateTime.now().millisecondsSinceEpoch}',
    //     'name': boardName.isEmpty ? 'Untitled Board' : boardName,
    //     'filled': _filledCount,
    //     'size': _size,
    //   },
    // );

    // Board board = Board(tiles: [],);
  }

  @override
  Widget build(BuildContext context) {
    assert(_tiles.length == _size * _size);

    return Scaffold(
      appBar: AppBar(title: Text(_nameCtrl.text)),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final n = _size;
                  const spacing = 8.0;

                  final gridW = constraints.maxWidth;
                  final gridH = constraints.maxHeight;

                  final tileW = (gridW - spacing * (n - 1)) / n;
                  final tileH = (gridH - spacing * (n - 1)) / n;

                  final ratio = tileW / tileH; // width / height

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: n,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: ratio,
                    ),
                    itemCount: _tiles.length,
                    itemBuilder: (context, index) {
                      final text = _tiles[index];
                      return InkWell(
                        onTap: () => _editTile(context, index),
                        onLongPress: () => setState(() => _tiles[index] = ''),
                        borderRadius: BorderRadius.circular(8),
                        child: _Tile(text: text),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          SizedBox(
            width: 320,
            child: Material(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Board Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Board name'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Board Description',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Create'),
              onPressed: _onCreatePressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isEmpty = text.trim().isEmpty;
    return Material(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade400),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            isEmpty ? '—' : text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              color: isEmpty ? Colors.grey.shade500 : null,
            ),
          ),
        ),
      ),
    );
  }
}

class BoardDetailPage extends StatelessWidget {
  const BoardDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final id = args?['id'] ?? 'unknown';
    final name = args?['name'] ?? 'Untitled Board';
    final filled = args?['filled'];
    final size = args?['size'];

    return Scaffold(
      appBar: AppBar(title: const Text('Board')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('id: $id'),
            Text('name: $name'),
            Text('tiles filled: $filled / ${size is int ? size * size : '?'}'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Designer'),
            ),
          ],
        ),
      ),
    );
  }
}
