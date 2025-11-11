import 'package:flutter/material.dart';

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
    ),
    GameListEntry(
      title: 'Sample Board',
      author: 'Alice',
      hasPassword: false,
      maxPlayers: 10,
    ),
    GameListEntry(
      title: 'Fun Board',
      author: 'Bob',
      hasPassword: true,
      maxPlayers: 8,
    ),
    GameListEntry(
      title: 'Adventure Board',
      author: 'Eve',
      hasPassword: false,
      maxPlayers: 6,
    ),
    GameListEntry(
      title: 'Cusack Board',
      author: 'Joe',
      hasPassword: true,
      maxPlayers: 15,
    ),
    GameListEntry(
      title: 'Mcfall Board',
      author: 'Max',
      hasPassword: true,
      maxPlayers: 4,
    ),
    GameListEntry(
      title: 'Olegbemi Board',
      author: 'Steven',
      hasPassword: false,
      maxPlayers: 6,
    ),
    GameListEntry(
      title: 'Cusack Board again',
      author: 'Joe Again',
      hasPassword: true,
      maxPlayers: 15,
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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _button(
                  'Create board',
                  () => debugPrint("Create board pressed"),
                ),
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.1,
                  ),
                ),
                _button(
                  'Join with key',
                  () => debugPrint("Join with key pressed"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  const GameListEntry({
    super.key,
    required this.title,
    required this.author,
    required this.hasPassword,
    required this.maxPlayers,
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
          Column(
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
