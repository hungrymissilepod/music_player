import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app_template/ftt/soloud_handler.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:num_remap/num_remap.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

Random random = Random();

List<StarParticle> backgroundParticles = [];
int maxBackgroundParticles = 150;
double backgroundParticlesBaseAcceleration = 0.0002;
double backgroundMaxParticleSize = 1.2;

List<StarParticle> particles = [];
int maxParticles = 50;
double baseAcceleration = 0.0005;
double maxParticleSize = 2.5;

class StarsVisualiser extends CustomPainter {
  StarsVisualiser({
    required this.audioData,
    required this.canvasSize,
  }) {
    maxCirlceRadius = canvasSize.width / 2.5;
    midCircleRadius = (minCircleRadius + maxCirlceRadius) / 2;
  }

  final Size canvasSize;

  final ffi.Pointer<ffi.Float> audioData;

  /// Amount the circle should increase in size by by multipling treble data
  final int trebleMultiplier = 50;

  /// Number of FFT samples
  final int samples = 256;

  /// Size of circle
  final double minCircleRadius = 150;
  double maxCirlceRadius = 0.0;
  double midCircleRadius = 0.0;

  double _averageFrequency(int low, int high) {
    double total = 0.0;
    int numFrequencies = 0;
    for (int i = low; i <= high; i++) {
      total += audioData[i];
      numFrequencies++;
    }
    return total / numFrequencies;
  }

  Paint backgroundPaint = Paint()..color = Colors.black;

  Paint whitePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.miter;

  Paint circlePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.miter;

  @override
  void paint(Canvas canvas, Size size) {
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
      backgroundPaint,
    );

    canvas.translate(size.width / 2, size.height / 2);

    double averageBass = _averageFrequency(bass[0], bass[1]);
    double averageLowMid = _averageFrequency(lowMid[0], lowMid[1]);
    double averageTreble = _averageFrequency(treble[0], treble[1]);

    if (backgroundParticles.length < maxBackgroundParticles) {
      var p =
          StarParticle(size, baseAcceleration: backgroundParticlesBaseAcceleration, maxSize: backgroundMaxParticleSize);
      backgroundParticles.add(p);
    }

    for (int i = 0; i < backgroundParticles.length; i++) {
      /// Reset any particles that go off screen
      if (backgroundParticles[i].shouldCull()) {
        backgroundParticles[i].resetPosition();
        backgroundParticles[i].initRandomly(size);
      } else {
        backgroundParticles[i].update(averageLowMid);

        canvas.drawCircle(
          Offset(backgroundParticles[i].pos.x, backgroundParticles[i].pos.y),
          backgroundParticles[i].size,
          whitePaint..color = backgroundParticles[i].color,
        );
      }
    }

    /// Draw particles
    if (particles.length < maxParticles) {
      var p = StarParticle(size, circleRadius: midCircleRadius, maxSize: maxParticleSize);
      particles.add(p);
    }

    for (int i = particles.length - 1; i >= 0; i--) {
      /// Reset any particles that go off screen
      if (particles[i].shouldCull()) {
        particles[i].resetPosition();
        particles[i].initAroundCircle(midCircleRadius);
      } else {
        particles[i].update(averageBass);

        canvas.drawCircle(
          Offset(particles[i].pos.x, particles[i].pos.y),
          particles[i].size,
          whitePaint..color = particles[i].color,
        );
      }
    }

    /// We draw the circle in two halves
    /// The first time we draw the right side and the second time we draw the left side
    for (int t = -1; t <= 1; t += 2) {
      List<Offset> points = [];

      for (double i = 0; i < 180; i += 0.5) {
        final index = i.remap(0, 180, 0, samples - 1).floor();

        /// Map the [audioData] to the size of the circle (one half of it)
        var r = audioData[index + 256].remap(
          -1,
          1,
          (minCircleRadius + (averageTreble * trebleMultiplier)),
          (maxCirlceRadius + (averageTreble * trebleMultiplier)),
        );

        /// Plot points around the circle radius
        /// [t] here is used to flip the x axis over when drawing the other half
        double x = r * sin(i * (pi / 180)) * t;
        double y = r * cos(i * (pi / 180));
        points.add(Offset(x, y));
      }
      circlePaint.strokeWidth = 2.5 + (averageTreble * 8);
      canvas.drawPoints(PointMode.polygon, points, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class StarParticle {
  vector_math.Vector2 pos = vector_math.Vector2(0, 0);
  vector_math.Vector2 velocity = vector_math.Vector2(0, 0);
  vector_math.Vector2 acceleration = vector_math.Vector2(0, 0);

  double size = 4;
  Color color = Colors.white;

  Size _canvasSize = Size.zero;
  double _accelerationValue = 0.0;
  double _maxSize = 0.0;

  StarParticle(Size canvasSize, {double? circleRadius, double baseAcceleration = 0.0005, double maxSize = 0.0}) {
    _canvasSize = canvasSize;
    _accelerationValue = baseAcceleration;
    _maxSize = maxSize;

    resetPosition();

    if (circleRadius != null) {
      initAroundCircle(circleRadius);
    } else {
      initRandomly(canvasSize);
    }

    setSize();
  }

  void resetPosition() {
    pos = vector_math.Vector2(0, 0);
    velocity = vector_math.Vector2(0, 0);
    acceleration = vector_math.Vector2(0, 0);
  }

  void setSize() {
    size = random.nextDouble() * _maxSize;
  }

  void initRandomly(Size canvasSize) {
    pos = vector_math.Vector2(
      (-1 + random.nextDouble() * 2) * canvasSize.width / 2,
      (-1 + random.nextDouble() * 2) * canvasSize.height / 2,
    );
    acceleration = pos.clone()
      ..multiply(
        vector_math.Vector2(
          random.nextDouble() * _accelerationValue,
          random.nextDouble() * _accelerationValue,
        ),
      );
  }

  void initAroundCircle(double circleRadius) {
    /// Pick random angle around the circle
    var angle = random.nextDouble() * pi * 2;

    /// Plot this particle around edge of the circle
    pos = vector_math.Vector2(
      cos(angle) * circleRadius,
      sin(angle) * circleRadius,
    );

    acceleration = pos.clone()
      ..multiply(
        vector_math.Vector2(
          random.nextDouble() * _accelerationValue,
          random.nextDouble() * _accelerationValue,
        ),
      );
  }

  update(double bass) {
    if (bass.round() == 0) {
      vector_math.Vector2 add = acceleration;
      velocity.add(add);
    } else {
      double value = 0.1 + _accelerationValue + bass;
      vector_math.Vector2 add = acceleration..multiply(vector_math.Vector2(value, value));
      velocity.add(add);
    }

    pos.add(velocity);
  }

  /// If particle goes off screen
  bool shouldCull() {
    if (pos.x < -_canvasSize.width / 2 ||
        pos.x > _canvasSize.width / 2 ||
        pos.y < -_canvasSize.height / 2 ||
        pos.y > _canvasSize.height / 2) {
      return true;
    }
    return false;
  }
}
