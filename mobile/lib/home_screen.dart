import 'package:flutter/material.dart';
import 'package:mobile/board-designer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _noPasswordChecked = false;
  bool _notFullChecked = false;

  // TODO: Query fromm server
  List<GameListEntry> gamesList = [
    GameListEntry(
      title: 'Test Board',
      author: 'Kyle',
      hasPassword: true,
      maxPlayers: 5,
      gameKey: 'ABCD1234',
    ),
    GameListEntry(
      title: 'Sample Board',
      author: 'Alice',
      hasPassword: false,
      maxPlayers: 10,
      gameKey: 'EFGH5678',
    ),
    GameListEntry(
      title: 'Fun Board',
      author: 'Bob',
      hasPassword: true,
      maxPlayers: 8,
      gameKey: 'IJKL9012',
    ),
    GameListEntry(
      title: 'Adventure Board',
      author: 'Eve',
      hasPassword: false,
      maxPlayers: 6,
      gameKey: 'MNOP3456',
    ),
    GameListEntry(
      title: 'Cusack Board',
      author: 'Joe',
      hasPassword: true,
      maxPlayers: 15,
      gameKey: 'QRST7890',
    ),
    GameListEntry(
      title: 'Mcfall Board',
      author: 'Max',
      hasPassword: true,
      maxPlayers: 4,
      gameKey: 'UVWX1122',
    ),
    GameListEntry(
      title: 'Olegbemi Board',
      author: 'Steven',
      hasPassword: false,
      maxPlayers: 6,
      gameKey: 'YZAB3344',
    ),
    GameListEntry(
      title: 'Cusack Board again',
      author: 'Joe Again',
      hasPassword: true,
      maxPlayers: 15,
      gameKey: 'CDEF5566',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 4),
              ),
              margin: const EdgeInsets.all(16.0),
              width: 1000,
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _searchBar(),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _noPasswordChecked,
                          activeColor: Colors.lightBlueAccent,
                          onChanged: (bool? value) {
                            setState(() {
                              _noPasswordChecked = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          'No password',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 20),
                        Checkbox(
                          value: _notFullChecked,
                          activeColor: Colors.lightBlueAccent,
                          onChanged: (bool? value) {
                            setState(() {
                              _notFullChecked = value ?? false;
                            });
                          },
                        ),
                        const Text('Not full', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: gamesList.length,
                      itemBuilder: (context, index) {
                        return gamesList[index];
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 1000,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _button('Create board', () {
                    debugPrint("Create board pressed");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BoardTilesPage()),
                    );
                  }),
                  _button(
                    'Create game',
                    () => debugPrint("Create game pressed"),
                  ),
                  _button('Join with key', openDialog),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future openDialog() => showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Join game with key'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Enter a game code'),
          ),
          actions: [
            // TODO(Kyle): Implement join game functionality
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Join'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
  );

  SearchBar _searchBar() {
    return SearchBar(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
      shadowColor: WidgetStateProperty.all<Color>(Colors.transparent),
      overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
      surfaceTintColor: WidgetStateProperty.all<Color>(Colors.transparent),
      controller: _searchController,
      leading: const Icon(Icons.search),
      trailing: <Widget>[
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
          },
        ),
      ],
      hintText: 'Search for board',
      onChanged: (String value) {
        debugPrint('The text has changed to: $value');
      },
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

  Container _button(String text, void Function() onPressed) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        child: Text(text),
      ),
    );
  }
}

class GameListEntry extends StatefulWidget {
  final String title;
  final String author;
  final bool hasPassword;
  final int maxPlayers;
  final String gameKey;

  const GameListEntry({
    super.key,
    required this.title,
    required this.author,
    required this.hasPassword,
    required this.maxPlayers,
    required this.gameKey,
  });

  @override
  State<GameListEntry> createState() => _GameListEntryState();
}

class _GameListEntryState extends State<GameListEntry> {
  int currentPlayers = 0;

  // Thanks Copilot for helping with this method.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Author: ${widget.author}'),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                widget.gameKey,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    widget.hasPassword ? Icons.lock : Icons.lock_open,
                    color: widget.hasPassword ? Colors.red : Colors.green,
                  ),
                  Text(widget.hasPassword ? 'Private' : 'Public'),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.person),
                  Text('$currentPlayers / ${widget.maxPlayers}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
