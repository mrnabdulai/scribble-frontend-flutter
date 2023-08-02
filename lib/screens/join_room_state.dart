import 'package:flutter/material.dart';
import 'package:sketch_scribble/screens/paint_screen.dart';
import '../widgets/custom_text_field.dart';
// import './paint_screen.dart';

class JoinRoomState extends StatefulWidget {
  const JoinRoomState({Key? key}) : super(key: key);

  @override
  _JoinRoomStateState createState() => _JoinRoomStateState();
}

class _JoinRoomStateState extends State<JoinRoomState> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  late String? _maxRoundsValue;
  late String? _roomSizeValue;

  void joinRoom() {
    if (_nameController.text.isEmpty || _roomNameController.text.isEmpty) {
      return;
    }
    Map<String, dynamic> data = {
      "name": _nameController.text.trim(),
      "room_name": _roomNameController.text.trim(),
    };
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PaintScreen(
                  data: data,
                  screenFrom: 'joinRoom',
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Join Room",
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextField(
              controller: _nameController,
              hintText: "Enter your name",
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextField(
              controller: _roomNameController,
              hintText: "Enter Room Name",
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            // onPressed: () {},
            onPressed: joinRoom,
            child: const Text(
              "Join",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ButtonStyle(
                elevation: MaterialStatePropertyAll(0),
                backgroundColor: MaterialStateProperty.all(Colors.redAccent),
                textStyle:
                    MaterialStateProperty.all(TextStyle(color: Colors.white)),
                minimumSize: MaterialStateProperty.all(
                    Size(MediaQuery.of(context).size.width / 2.5, 50))),
          ),
        ],
      ),
    );
  }
}
