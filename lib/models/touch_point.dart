import 'package:flutter/material.dart';

class TouchPoints {
  Paint paint;
  Offset points;
  bool isNewDrawing; // Add this flag to indicate a new drawing

  TouchPoints(
      {required this.points, required this.paint, this.isNewDrawing = false});

  Map<String, dynamic> toJson() {
    return {
      'point': {'dx': '${points.dx}', "dy": "${points.dy}"}
    };
  }
}
