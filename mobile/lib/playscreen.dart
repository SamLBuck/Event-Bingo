import 'package:flutter/material.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

void main() {
  runApp(MaterialApp(home: const PlayScreen()));
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

  // how many of each player(s) are 0 away, 1 away, 2 away ... 5 away
  List<int> player_tiles_left = [0, 3, 1, 5, 1, 4];

  String board_name = "Name";

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
          children: [
            Text(
              board_name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Board(tiles: tiles)],
            ),
            Divider(),
            ListView.builder(
              itemCount: 5,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: EdgeInsets.all(4.0),
                  child:
                      index == 0
                          ? player_tiles_left[index] == 0
                              ? Text(
                                "No One has reached Bingo yet, be the first one!",
                              )
                              : Text("${2} Player(s) have reached Bingo!")
                          : player_tiles_left[index] == 0
                          ? null
                          : Text(
                            "${player_tiles_left[index]} Player(s) are $index away!",
                          ),
                );
              },
            ),
          ],
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

  final List<List<BingoTile?>> board = List.generate(
    5,
    (_) => List.filled(5, null),
  );

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
        board[newCol.length][newRow.length] = newTile;
        newRow.add(newTile);
      }
      // board keys:
      // 0-4, 10-14, ... 40-44
      newTile = BingoTile(label: tile, free: false, board: board);
      board[newCol.length][newRow.length] = newTile;
      newRow.add(newTile);
    }
    newCol.add(Row(children: newRow));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: newCol,
    );
  }
}

class BingoTile extends StatefulWidget {
  final String label;
  final bool free;
  final List<List<BingoTile?>> board;
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
        if (checkBingo() == 5) {
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

  int checkBingo() {
    int maxCount = 0;

    // row
    for (int row = 0; row < 5; row++) {
      int count = 0;
      for (int col = 0; col < 5; col++) {
        var tile = widget.board[row][col];
        if (tile != null && tile.checked) {
          count++;
        }
      }
      if (count > maxCount) maxCount = count;
    }

    // cols
    for (int col = 0; col < 5; col++) {
      int count = 0;
      for (int row = 0; row < 5; row++) {
        var tile = widget.board[row][col];
        if (tile != null && tile.checked) {
          count++;
        }
      }
      if (count > maxCount) maxCount = count;
    }

    // dia
    int diag1Count = 0;
    for (int i = 0; i < 5; i++) {
      var tile = widget.board[i][i];
      if (tile != null && tile.checked) {
        diag1Count++;
      }
    }
    if (diag1Count > maxCount) maxCount = diag1Count;

    // dia 2
    int diag2Count = 0;
    for (int i = 0; i < 5; i++) {
      var tile = widget.board[i][4 - i];
      if (tile != null && tile.checked) {
        diag2Count++;
      }
    }
    if (diag2Count > maxCount) maxCount = diag2Count;

    return maxCount;
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
          color: widget.checked ? Colors.orange : Colors.lightBlueAccent,
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
