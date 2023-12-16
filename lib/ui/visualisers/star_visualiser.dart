import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app_template/ftt/soloud_handler.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:num_remap/num_remap.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

List<Particle> particles = [];
Random random = Random();

class StarsVisualiser extends CustomPainter {
  StarsVisualiser({
    required this.audioData,
  });

  final ffi.Pointer<ffi.Float> audioData;

  double _averageFrequency(int low, int high) {
    double total = 0.0;
    int numFrequencies = 0;
    for (int i = low; i <= high; i++) {
      total += audioData[i];
      numFrequencies++;
    }
    return total / numFrequencies;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // print('isPlaying: ${SoLoudHandler().isPlaying()}');
    // print(audioData[0]);
    Paint paint = Paint()..color = Colors.black;

    /// background
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          size.width / 2,
          size.height / 2,
        ),
        width: size.width,
        height: size.height,
      ),
      paint,
    );

    canvas.translate(size.width / 2, size.height / 2);

    Paint strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;

    final int widthInt = size.width.toInt();
    final int samples = 256;
    final double minCircleRadius = 150;
    final double maxCirlceRadius = size.width / 2;
    final double midCircleRadius = (minCircleRadius + maxCirlceRadius) / 2;

    /// We draw the circle in two halves
    /// The first time we draw the right side and the second time we draw the left side
    for (int t = -1; t <= 1; t += 2) {
      List<Offset> points = [];

      for (double i = 0; i < 180; i += 0.5) {
        final index = i.remap(0, 180, 0, samples - 1).floor();

        /// Map the [audioData] to the size of the circle (one half of it)
        var r = audioData[index + 256].remap(-1, 1, minCircleRadius, maxCirlceRadius);

        /// Plot points around the circle radius
        /// [t] here is used to flip the x axis over when drawing the other half
        double x = r * sin(i * (pi / 180)) * t;
        double y = r * cos(i * (pi / 180));
        points.add(Offset(x, y));
      }

      canvas.drawPoints(PointMode.polygon, points, strokePaint);
    }

    double averageBass = _averageFrequency(bass[0], bass[1]);

    /// Draw particles
    // TODO: improve performance by pooling particles
    var p = Particle(size, midCircleRadius);
    particles.add(p);

    for (int i = particles.length - 1; i >= 0; i--) {
      if (!particles[i].edges()) {
        particles[i].update(averageBass);
        canvas.drawCircle(
            Offset(particles[i].pos.x, particles[i].pos.y), particles[i].size, strokePaint..color = particles[i].color);
      } else {
        particles.removeAt(i);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Particle {
  vector_math.Vector2 pos = vector_math.Vector2(0, 0);
  vector_math.Vector2 velocity = vector_math.Vector2(0, 0);
  vector_math.Vector2 acceleration = vector_math.Vector2(0, 0);
  double size = 4;
  Color color = Colors.white;

  Size _canvasSize = Size.zero;

  Particle(Size canvasSize, double circleRadius) {
    _canvasSize = canvasSize;

    /// Pick random angle around the circle
    var angle = random.nextDouble() * pi * 2;

    /// Plot this particle around edge of the circle
    pos = vector_math.Vector2(
      cos(angle) * circleRadius,
      sin(angle) * circleRadius,
    );

    acceleration = pos.clone()..multiply(vector_math.Vector2(random.nextDouble() * 0.001, random.nextDouble() * 0.001));

    size = random.nextInt(3) + 0.5;

    // int c = random.nextInt(3);
    // switch (c) {
    //   case 0:
    //     color = Colors.red;
    //   case 1:
    //     color = Colors.green;
    //   case 2:
    //     color = Colors.blue;
    //   default:
    //     color = Colors.white;
    // }
  }

  update(double boost) {
    velocity.add(acceleration);
    pos.add(velocity);

    var r = boost % 0.2;
    for (int i = 0; i < r; i++) {
      pos.add(velocity);
    }
  }

  /// If particle goes off screen
  bool edges() {
    if (pos.x < -_canvasSize.width / 2 ||
        pos.x > _canvasSize.width / 2 ||
        pos.y < -_canvasSize.height / 2 ||
        pos.y > _canvasSize.height / 2) {
      return true;
    }
    return false;
  }
}
