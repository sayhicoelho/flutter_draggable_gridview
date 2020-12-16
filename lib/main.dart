import 'package:flutter/material.dart';
import 'package:flutter_draggable_gridview/widgets/draggable_gridview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridView Drag N\' Drop',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<DraggableGridViewItem<Network>> _items = [
    DraggableGridViewItem(Network('Facebook'), 1),
    DraggableGridViewItem(Network('YouTube'), 2),
    DraggableGridViewItem(Network('LinkedIn'), 3),
    DraggableGridViewItem(Network('Instagram'), 4),
    DraggableGridViewItem(Network('Twitter'), 5),
    DraggableGridViewItem(Network('WhatsApp'), 6),
    DraggableGridViewItem(Network('CashApp'), 7),
    DraggableGridViewItem(Network('Venmo'), 8),
    DraggableGridViewItem(Network('OnlyFans'), 9),
    DraggableGridViewItem(Network('Snapchat'), 10),
    DraggableGridViewItem(Network('SMS'), 11),
    DraggableGridViewItem(Network('Telegram'), 12),
    DraggableGridViewItem(Network('Apple Music'), 13),
    DraggableGridViewItem(Network('Email'), 14),
    DraggableGridViewItem(Network('SoundCloud'), 15),
    DraggableGridViewItem(Network('Spotify'), 16),
    DraggableGridViewItem(Network('TikTok'), 17),
    DraggableGridViewItem(Network('Twitch'), 18),
    DraggableGridViewItem(Network('Venmo'), 19),
    DraggableGridViewItem(Network('Add Link'), 20, draggable: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(36.0),
              child: Container(
                color: Colors.red,
                child: DraggableGridView<Network>(
                  crossAxisCount: 3,
                  items: _items,
                  builder: (context, index, item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('${item.data.name}', textAlign: TextAlign.center,)
                      ),
                    ),
                  ),
                  onDragStop: () {
                    print(_items);
                  },
                  onSort: () {
                    print('ON SORT!');
                  }
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Network {
  final String name;

  Network(this.name);

  @override
  String toString() => 'Network(name: $name)';
}
