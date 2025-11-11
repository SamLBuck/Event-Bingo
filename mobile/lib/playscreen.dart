import 'package:flutter/material.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  // These will be where the tiles fetched from backend will be;
  // placed in the order

  // 1  2  3  4  5
  // 6  7  8  9  10
  // 11 12 X  13 14
  // 15 16 17 18 19
  // 20 21 22 23 24

  List<String> tiles = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "16",
    "17",
    "18",
    "19",
    "20",
    "21",
    "22",
    "23",
    "24",
  ];

  //Since randomization occurs on the backend, need to check tile count.

  @override
  Widget build(BuildContext context) {
    if (tiles.length != 24) {
      return Scaffold(
        appBar: _appBar(),
        body: Center(child: Text('Something went wrong.')),
      );
    }
    return Scaffold(
      appBar: _appBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Board(tiles: tiles)],
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: Text(
        'Hope Bingo',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      ),
      centerTitle: true,
      backgroundColor: Colors.lightBlueAccent,
    );
  }
}

class Board extends StatelessWidget {
  final List<String> tiles;

  Board({super.key, required this.tiles});

  final Map<int, BingoTile> board = {};

  @override
  Widget build(BuildContext context) {
    List<Widget> newCol = [];
    List<Widget> newRow = [];
    BingoTile newTile;

    for (String tile in tiles) {
      //if row is full, push
      if (newRow.length == 5) {
        newCol.add(Row(children: newRow));
        newRow = [];
      }
      // inserts the "FREE" square before adding the next one
      if (newRow.length == 2 && newCol.length == 2) {
        newTile = BingoTile(label: "FREE", free: true, board: board);
        board[newRow.length + newCol.length * 10] = newTile;
        newRow.add(newTile);
      }
      // board keys:
      // 0-4, 10-14, ... 40-44
      newTile = BingoTile(label: tile, free: true, board: board);
      board[newRow.length + newCol.length * 10] = newTile;
      newRow.add(newTile);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: newCol,
    );
  }
}

class BingoTile extends StatefulWidget {
  final String label;
  final bool free;
  final Map<int, BingoTile> board;
  bool checked = false;

  BingoTile({
    super.key,
    required this.label,
    this.free = false,
    required this.board,
  });

  @override
  State<BingoTile> createState() => _BingoTileState();
}

class _BingoTileState extends State<BingoTile> {
  @override
  void initState() {
    super.initState();
    // free tiles are checked
    widget.checked = widget.free;
  }

  void onClick() {
    if (widget.free) return;
    setState(() {
      // clicking a tile checks it, clicking again unchecks (in case of mistake)
      widget.checked = !widget.checked;
      if (widget.checked) {
        if (checkBingo()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'BINGO!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  bool checkBingo() {
    // row
    for (int row = 0; row < 5; row++) {
      bool rowBingo = true;
      for (int col = 0; col < 5; col++) {
        var tile = widget.board[row * 10 + col];
        if (tile == null || !tile.checked) {
          rowBingo = false;
          break;
        }
      }
      if (rowBingo) return true;
    }

    // cols
    for (int col = 0; col < 5; col++) {
      bool colBingo = true;
      for (int row = 0; row < 5; row++) {
        var tile = widget.board[row * 10 + col];
        if (tile == null || !tile.checked) {
          colBingo = false;
          break;
        }
      }
      if (colBingo) return true;
    }

    // dia
    bool diag1Bingo = true;
    for (int i = 0; i < 5; i++) {
      var tile = widget.board[i * 10 + i];
      if (tile == null || !tile.checked) {
        diag1Bingo = false;
        break;
      }
    }
    if (diag1Bingo) return true;

    // dia 2
    bool diag2Bingo = true;
    for (int i = 0; i < 5; i++) {
      var tile = widget.board[i * 10 + (4 - i)];
      if (tile == null || !tile.checked) {
        diag2Bingo = false;
        break;
      }
    }
    if (diag2Bingo) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.checked ? Colors.green : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
