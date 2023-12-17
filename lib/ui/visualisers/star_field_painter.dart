import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_app_template/ftt/soloud_handler.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:flutter_app_template/main.dart';
import 'package:flutter_app_template/ui/visualisers/star.dart';
import 'package:flutter_app_template/ui/visualisers/star_field_visualiser.dart';
import 'package:flutter_app_template/ui/visualisers/star_particle.dart';
import 'package:num_remap/num_remap.dart';

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final ui.Image? glowImage;
  final ffi.Pointer<ffi.Float> audioData;

  StarFieldPainter(this.stars, this.glowImage, this.audioData, this.canvasSize) {
    minCircleRadius = canvasSize.width / 3.3;
    maxCirlceRadius = canvasSize.width / 2.1;
    midCircleRadius = (minCircleRadius + maxCirlceRadius) / 2;
  }

  final Size canvasSize;

  /// Amount the circle should increase in size by by multipling treble data
  final int trebleMultiplier = 50;

  /// Number of FFT samples
  final int samples = 256;

  /// Size of circle
  double minCircleRadius = 0.0;
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

  Paint circlePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.miter;

  Paint whitePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.miter;

  @override
  void paint(Canvas canvas, Size size) {
    if (stars.isEmpty) return;
    canvas.translate(size.width / 2, size.height / 2);

    var paint = Paint()..color = Colors.white;

    /// background stars
    for (int i = 0; i < stars.length; i++) {
      var scale = .1 + map(stars[i].z, 0, size.width, stars[i].size, 0);
      var sx = map(stars[i].x / stars[i].z, 0, 1, 0, size.width);
      var sy = map(stars[i].y / stars[i].z, 0, 1, 0, size.height);
      var time = DateTime.now().millisecondsSinceEpoch / 200;
      paint.color = stars[i].color;
      var pos = Offset(sx, sy);
      canvas.drawCircle(pos, scale, paint);
      if (glowImage != null && stars[i].color != Colors.white) {
        if (stars[i].color == Colors.red) {
          var glowSizeX = scale * 6 + 2 * (sin(time * .25));
          var glowSizeY = scale * 6 + 2 * (cos(time * .150));
          var src = Rect.fromPoints(Offset.zero, Offset(glowImage!.width.toDouble(), glowImage!.height.toDouble()));
          var rect = Rect.fromCenter(center: pos, width: glowSizeX, height: glowSizeY);
          canvas.drawImageRect(glowImage!, src, rect, paint);
        } else {
          var glowSizeX = scale * 8 + 2 * (sin(time * .5));
          var glowSizeY = scale * 8 + 2 * (cos(time * .75));
          var src = Rect.fromPoints(Offset.zero, Offset(glowImage!.width.toDouble(), glowImage!.height.toDouble()));
          var rect = Rect.fromCenter(center: pos, width: glowSizeX, height: glowSizeY);
          canvas.drawImageRect(glowImage!, src, rect, paint);
        }
      }
    }

    double averageBass = _averageFrequency(bass[0], bass[1]);
    double averageLowMid = _averageFrequency(lowMid[0], lowMid[1]);
    double averageTreble = _averageFrequency(treble[0], treble[1]);

    /// Draw particles around circle
    if (true) {
      if (particles.length < maxParticles) {
        var p = StarParticle(size, circleRadius: midCircleRadius, maxSize: maxParticleSize);
        particles.add(p);
      }
    }

    for (int i = particles.length - 1; i >= 0; i--) {
      /// Reset any particles that go off screen
      /// TODO: make sure we only reset these particle positions if we are playing because they should only be displayed when playing
      if (particles[i].shouldCull() && SoLoudHandler().isPlaying.value) {
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

      for (double i = 0; i < 181; i += 1) {
        final index = i.remap(0, 180, 0, samples - 1).floor();

        /// Map the [audioData] to the size of the circle (one half of it)
        var r = audioData[index + 256].remap(
          -1,
          1,
          minCircleRadius,
          maxCirlceRadius + (averageTreble * trebleMultiplier),
        );

        /// Plot points around the circle radius
        /// [t] here is used to flip the x axis over when drawing the other half
        double x = r * sin(i * (pi / 180)) * t;
        double y = r * cos(i * (pi / 180));
        points.add(Offset(x, y));
      }
      circlePaint.strokeWidth = 2.5 + (averageTreble * 15);

      double a = getRad();
      double h = (_hue * 0.5 + random.nextDouble() * 40.0 + a / pi * 30) % 360;

      int color = HSLColor.fromAHSL(1.0, h, 1.0, getBool(0.1) ? 1.0 : 0.4).toColor().value;

      canvas.drawPoints(ui.PointMode.polygon, points, circlePaint);
    }
  }

  double _hue = 0.0;
  double getRad() {
    return getDouble(0, pi * 2);
  }

  double getDouble(double min, double max) {
    return min + random.nextDouble() * (max - min);
  }

  bool getBool([double chance = 0.5]) {
    return random.nextDouble() < chance;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  double map(double value, double from1, double to1, double from2, double to2) {
    return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
  }
}
