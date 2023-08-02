import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sketch_scribble/models/my_custom_painter.dart';
import 'package:sketch_scribble/models/touch_point.dart';
import 'package:sketch_scribble/screens/final_leader_board.dart';
import 'package:sketch_scribble/screens/sidebar/player_scoreboard_drawer.dart';
import 'package:sketch_scribble/screens/waiting_lobby.dart';
import 'package:sketch_scribble/utils/format.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key, required this.data, required this.screenFrom});
  final Map<String, dynamic> data;
  final String screenFrom;

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  WebSocketChannel? _channel;
  Map<String, dynamic>? dataOfRoom;
  List<TouchPoints> points = [];
  Color selectedColor = Colors.black;
  double opacity = 1;
  double strokeWidth = 2;
  List<Widget> textBlankWidget = [];
  ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  TextEditingController controller = TextEditingController();
  int _start = 60;
  Timer? _timer;
  ConfettiController? _confettiController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map> scoreboard = [];
  bool isTextInputReadOnly = false;
  int maxPoints = 0;
  StrokeCap strokeType = StrokeCap.round;
  Timer? socketUpdateTimer;

  String winner = "";
  bool isShowFinalLeaderBoard = false;
  @override
  void dispose() {
    // TODO: implement dispose
    _channel?.sink.close();
    _timer?.cancel();
    _confettiController?.dispose();

    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
    connect();
  }

  void _celebrate() {
    _confettiController?.play();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      if (_start <= 0) {
        if (dataOfRoom?["turn"]?["nickname"] == widget.data["name"]) {
          _channel?.sink.add(json.encode({
            "type": "change-turn",
            "data": {
              "room_name": widget.data['room_name'],
            }
          }));
        }

        // setState(() {
        //   _start = 60;
        // });
        _timer?.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void renderTextBlank(String text) {
    textBlankWidget.clear();
    for (int i = 0; i < text.length; i++) {
      textBlankWidget.add(
        Text(
          "_",
          style: TextStyle(
            fontSize: 30,
          ),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  void connect() {
    final Uri uri = kIsWeb
        ? Uri.parse('ws://127.0.0.1:8000/ws/drawing/')
        : Uri.parse('ws://10.0.2.2:8000/ws/drawing/');
    _channel = WebSocketChannel.connect(uri
        // protocols: ["websocket"],
        );

    _channel?.stream.listen(
      (message) {
        // Handle incoming messages
        final decodedMessage = json.decode(message);
        final data = decodedMessage["data"] ?? {};
        switch (decodedMessage["type"]) {
          case "update-room":
            setState(() {
              renderTextBlank(decodedMessage["data"]['word']);
              dataOfRoom = decodedMessage["data"];
            });

            if (decodedMessage["data"]['isJoin'] != true) {
              //Start timer
              startTimer();
            }
            scoreboard.clear();
            print(data!['players']);
            for (int i = 0; i < data!['players'].length; i++) {
              setState(() {
                scoreboard.add({
                  "name": data['players'][i]['nickname'],
                  "score": data['players'][i]['points'].toString(),
                });
              });
            }
            break;

          case "points":
            if (data['details'] != null) {
              if (data["type"] != null && data["type"] == "start") {
                setState(() {
                  points.add(
                    TouchPoints(
                      points: Offset(data['details']['dx'].toDouble(),
                          data['details']['dy'].toDouble()),
                      paint: Paint()
                        ..strokeCap = strokeType
                        ..isAntiAlias = true
                        ..color = selectedColor.withOpacity(opacity)
                        ..strokeWidth = strokeWidth,
                      isNewDrawing: true,
                    ),
                  );
                });
              } else {
                setState(() {
                  points.add(
                    TouchPoints(
                      points: Offset(data['details']['dx'].toDouble(),
                          data['details']['dy'].toDouble()),
                      paint: Paint()
                        ..strokeCap = strokeType
                        ..isAntiAlias = true
                        ..color = selectedColor.withOpacity(opacity)
                        ..strokeWidth = strokeWidth,
                    ),
                  );
                });
              }
            }
            break;

          case "close-input":
            _channel?.sink.add(json.encode({
              "type": "update-score",
              "data": {
                "room_name": widget.data['room_name'],
              }
            }));
            setState(() {
              isTextInputReadOnly = true;
            });

            break;

          case "color-change":
            int value = int.parse(data['color'].toString(), radix: 15);
            Color otherColor = Color(value);
            //TODO:Fixe color
            setState(() {
              selectedColor = otherColor;
            });
            break;

          case 'stroke-width':
            setState(() {
              strokeWidth = data['stroke_width'].toDouble();
            });
            break;

          case 'clean-screen':
            setState(() {
              points.clear();
            });
            break;
          case 'message':
            setState(() {
              messages.add(data);
            });

            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 40,
              duration: Duration(milliseconds: 600),
              curve: Curves.ease,
            );

            break;

          case 'change-turn':
            print(data?["turn"]);
            final String oldWork = dataOfRoom!["word"];
            _celebrate();
            showDialog(
                context: context,
                builder: (context) {
                  Future.delayed(Duration(seconds: 3), () {
                    setState(() {
                      dataOfRoom = data;
                      renderTextBlank(data["word"]);
                      isTextInputReadOnly = false;
                      _start = 60;
                      points.clear();
                      _confettiController?.stop();
                    });
                    // WidgetsBinding.instance.addPostFrameCallback((_) {
                    //   Navigator.of(context).pop();
                    // });
                    Navigator.of(_scaffoldKey.currentContext!).pop();
                    _timer?.cancel();
                    startTimer();
                  });

                  return AlertDialog(
                    title: Center(
                      child: Text("Word was $oldWork"),
                    ),
                  );
                });
            break;

          case "update-score":
            scoreboard.clear();
            for (int i = 0; i < data!['players'].length; i++) {
              setState(() {
                scoreboard.add({
                  "name": data['players'][i]['nickname'],
                  "score": data['players'][i]['points'].toString(),
                });
              });
            }
            break;
          case "show-leaderboard":
            scoreboard.clear();
            for (int i = 0; i < data!['players'].length; i++) {
              setState(() {
                scoreboard.add({
                  "name": data['players'][i]['nickname'],
                  "score": data['players'][i]['points'].toString(),
                });
              });
              if (maxPoints < int.parse(scoreboard[i]['score'])) {
                winner = scoreboard[i]['name'];
                maxPoints = int.parse(scoreboard[i]['score']);
              }
            }
            setState(() {
              _timer!.cancel();
              isShowFinalLeaderBoard = true;
            });
            break;
        }
      },
      onError: (error) {
        // Handle WebSocket errors
        print('WebSocket error: $error');
      },
      onDone: () {
        // Handle WebSocket closing
        print('WebSocket connection closed');
      },
    );

    if (widget.screenFrom == 'createRoom') {
      _channel?.sink.add(json.encode({
        "type": "create-game",
        "data": widget.data,
      }));
    }

    if (widget.screenFrom == "joinRoom") {
      _channel?.sink.add(json.encode({
        "type": "join-game",
        "data": widget.data,
      }));
    }
  }

  void selectColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Choose color",
        ),
        content: SingleChildScrollView(
          child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                // setState(() {
                //   selectedColor = color;
                // });
                String colorString = color.toString();
                String valueString = colorString.split('(0x')[1].split(')')[0];
                Map<String, dynamic> map = {
                  "color": int.parse(valueString, radix: 16),
                  "room_name": widget.data['room_name']
                };
                _channel?.sink.add(json.encode({
                  "type": "color-change",
                  "data": map,
                }));
              }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      drawer: PlayerScore(scoreboard),
      backgroundColor: Colors.white,
      body: dataOfRoom != null
          ? dataOfRoom!["isJoin"] != true
              ? !isShowFinalLeaderBoard
                  ? Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: width,
                              height: height * 0.55,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  socketUpdateTimer?.cancel();
                                  // Start a new timer to send the data after a short delay
                                  socketUpdateTimer =
                                      Timer(Duration(milliseconds: 100), () {
                                    _channel?.sink.add(json.encode({
                                      'data': {
                                        'details': {
                                          'dx': details.localPosition.dx,
                                          'dy': details.localPosition.dy,
                                        },
                                        'room_name': widget.data['room_name'],
                                      },
                                      'type': 'paint'
                                    }));
                                  });
                                },
                                onPanStart: (details) {
                                  // socketUpdateTimer?.cancel();

                                  // // Start a new timer to send the data after a short delay
                                  // socketUpdateTimer =
                                  //     Timer(Duration(milliseconds: 10), () {
                                  _channel?.sink.add(json.encode({
                                    'data': {
                                      'details': {
                                        'dx': details.localPosition.dx,
                                        'dy': details.localPosition.dy,
                                      },
                                      "type": "start",
                                      'room_name': widget.data['room_name'],
                                    },
                                    'type': 'paint'
                                  }));
                                  // });
                                },
                                onPanEnd: (details) {
                                  _channel?.sink.add(json.encode({
                                    'data': {
                                      'details': null,
                                      'room_name': widget.data['room_name'],
                                    },
                                    'type': 'paint'
                                  }));
                                },
                                child: SizedBox.expand(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter:
                                            MyCustomPainter(pointsList: points),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: selectColor,
                                  icon: Icon(
                                    Icons.color_lens,
                                    color: selectedColor,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    min: 1.0,
                                    max: 10,
                                    label: "Stroke Width $strokeWidth",
                                    activeColor: selectedColor,
                                    value: strokeWidth,
                                    onChanged: (double value) {
                                      socketUpdateTimer?.cancel();
                                      // Start a new timer to send the data after a short delay
                                      socketUpdateTimer =
                                          Timer(Duration(milliseconds: 50), () {
                                        _channel?.sink.add(json.encode({
                                          "type": "stroke-width",
                                          "data": {
                                            "stroke_width": value,
                                            "room_name":
                                                widget.data['room_name']
                                          }
                                        }));
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _channel?.sink.add(json.encode({
                                        "type": "clean-screen",
                                        "data": {
                                          "room_name": widget.data['room_name']
                                        }
                                      }));
                                    });
                                  },
                                  icon: Icon(
                                    Icons.layers_clear,
                                    color: selectedColor,
                                  ),
                                ),
                              ],
                            ),
                            dataOfRoom?["turn"]?["nickname"] !=
                                    widget.data["name"]
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: textBlankWidget,
                                  )
                                : Center(
                                    child: Text(
                                      dataOfRoom!["word"],
                                      style: TextStyle(
                                        fontSize: 30,
                                      ),
                                    ),
                                  ),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  var msg = messages[index].values;
                                  return ListTile(
                                    title: Text(msg.elementAt(0),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    subtitle: Text(msg.elementAt(1),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        )),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        dataOfRoom?["turn"]["nickname"] != widget.data["name"]
                            ? Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: TextField(
                                    controller: controller,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.done,
                                    readOnly: isTextInputReadOnly,
                                    onSubmitted: (String value) {
                                      if (value.trim().isEmpty) return;
                                      Map<String, dynamic> data = {
                                        "name": widget.data['name'],
                                        "message": value.trim(),
                                        'word': dataOfRoom!['word'],
                                        'room_name': widget.data['room_name'],
                                        'totalTime': 60,
                                        'timeTaken': 60 - _start,
                                      };
                                      _channel?.sink.add(
                                        json.encode(
                                          {"type": "message", "data": data},
                                        ),
                                      );
                                      controller.clear();
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                      filled: true,
                                      fillColor: const Color(0xffF5F5FA),
                                      hintText: "Your guess",
                                      hintStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        SafeArea(
                          child: IconButton(
                            icon: Icon(Icons.menu, color: Colors.black),
                            onPressed: () =>
                                _scaffoldKey.currentState!.openDrawer(),
                          ),
                        ),
                        Center(
                          child: ConfettiWidget(
                            confettiController: _confettiController!,
                            blastDirectionality:
                                BlastDirectionality.explosive, // straight up
                            emissionFrequency: 0.05,
                            numberOfParticles: 20,
                            gravity: 0.5,
                            colors: const [
                              Colors.red,
                              Colors.green,
                              Colors.blue
                            ],
                            // other parameters to customize confetti appearance
                          ),
                        ),
                      ],
                    )
                  : FinalLeaderboard(scoreboard, winner)
              : WaitingLobbyScreen(
                  lobbyName: dataOfRoom!['name'],
                  noOfPlayers: dataOfRoom!['players'].length,
                  occupancy: dataOfRoom!['occupancy'],
                  players: dataOfRoom!['players'],
                )
          : Center(child: CircularProgressIndicator.adaptive()),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: () {},
          elevation: 10,
          backgroundColor: Colors.white,
          child: Text(
            "$_start",
            style: TextStyle(color: Colors.black, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
