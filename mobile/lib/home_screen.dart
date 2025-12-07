import 'dart:convert';
import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:flutter/material.dart';
import 'package:mobile/board-designer.dart';
import 'package:mobile/create_game_widget.dart';
import 'package:mobile/playscreen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _joinGameController = TextEditingController();
  bool _noPasswordChecked = false;
  bool _notFullChecked = false;

  Future<void> _joinGame({
    required String gameCode,
    required String playerName,
    String? password,
    Uint16? UUID,
  }) async {
    final url = Uri.parse('http://localhost:8080/api/games/$gameCode/join');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        if (password != null) 'password': password,
        if (playerName.isNotEmpty) 'playerName': playerName,
        if (UUID != null) 'playerUUID': UUID,
      }),
    );
    if (response.statusCode == 200) {
      debugPrint("Joined game successfully");
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

  Future<List<GameListEntry>> _getGamesList() async {
    final url = Uri.parse('http://localhost:8080/api/games');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      var gamesMap = responseBody["games"];

      if (_searchController.text.isNotEmpty) {
        // Thanks chatGPT for this filtering code.
        gamesMap =
            gamesMap.where((game) {
              String boardName =
                  game['gameBoard']['boardName'].toString().toLowerCase();
              String searchText = _searchController.text.toLowerCase();
              return boardName
                  .split(' ')
                  .any((word) => word.startsWith(searchText));
            }).toList();
      }

      debugPrint("from thing${_searchController.text}");

      if (_noPasswordChecked) {
        gamesMap = gamesMap.where((game) => game['isPublic'] == true).toList();
      }

      if (_notFullChecked) {
        gamesMap =
            gamesMap.where((game) {
              if (game['boardStates'] == null) {
                return true;
              }
              return (game['boardStates'] as Map).length < 10;
            }).toList();
      }

      return gamesMap
          .map<GameListEntry>(
            (game) => GameListEntry(
              title: game['gameBoard']['boardName'],
              author: game['hostPlayer'],
              hasPassword: !game['isPublic'],
              currentPlayers: game['boardStates'].length,
              maxPlayers: 10,
              gameKey: game['gameCode'],
            ),
          )
          .toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load games');
    }
  }

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
                    child: FutureBuilder(
                      future: _getGamesList(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No games found.'));
                        } else {
                          var games = snapshot.data!;
                          return ListView.builder(
                            itemCount: games.length,
                            itemBuilder: (context, index) {
                              return games[index];
                            },
                          );
                        }
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
                  _button('Create game', () {
                    debugPrint("Create game pressed");
                    showCreateGameDialog(context);
                  }),
                  _button('Join with game code', openDialog),
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
          content: Column(
            children: [
              TextFormField(
                controller: _joinGameController,
                decoration: InputDecoration(hintText: 'Enter a game code'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter a game code'
                            : null,
              ),
              TextFormField(
                decoration: InputDecoration(hintText: 'Enter your name'),
              ),
            ],
          ),
          actions: [
            // TODO(Kyle): Implement join game functionality
            TextButton(
              onPressed: () {
                _joinGame(_joinGameController.text);
                Navigator.of(context).pop();
              },
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
      onSubmitted: (String value) {
        setState(() {});
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
  final int currentPlayers;
  final int maxPlayers;
  final String gameKey;

  const GameListEntry({
    super.key,
    required this.title,
    required this.author,
    required this.hasPassword,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.gameKey,
  });

  @override
  State<GameListEntry> createState() => _GameListEntryState();
}

class _GameListEntryState extends State<GameListEntry> {
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
                Text('Host: ${widget.author}'),
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
                  Text('${widget.currentPlayers} / ${widget.maxPlayers}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
