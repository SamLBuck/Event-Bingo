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
