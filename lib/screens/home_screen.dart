import 'package:flutter/material.dart';
import 'package:sketch_scribble/screens/create_room_screen.dart';
import 'package:sketch_scribble/screens/join_room_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Create/Join a room to play, ",
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateRoomScreen()));
                },
                child: Text(
                  "Create",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                style: ButtonStyle(
                  elevation: MaterialStatePropertyAll(0),
                  minimumSize: MaterialStateProperty.all(
                    Size(
                      MediaQuery.of(context).size.width / 2.5,
                      50,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => JoinRoomState()));
                },
                child: Text(
                  "Join",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                style: ButtonStyle(
                  elevation: MaterialStatePropertyAll(0),
                  minimumSize: MaterialStateProperty.all(
                    Size(
                      MediaQuery.of(context).size.width / 2.5,
                      50,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
