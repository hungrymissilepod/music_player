import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:flutter_app_template/ui/visualisers/star.dart';
import 'package:flutter_app_template/ui/visualisers/star_field_painter.dart';
import 'package:flutter_app_template/ui/visualisers/star_particle.dart';

List<StarParticle> backgroundParticles = [];
int maxBackgroundParticles = 100;
double backgroundParticlesBaseAcceleration = 0.0002;
double backgroundMaxParticleSize = 1.2;

List<StarParticle> particles = [];
int maxParticles = 50;
double baseAcceleration = 0.0005;
double maxParticleSize = 4;

class StarFieldVisualiser extends StatefulWidget {
  const StarFieldVisualiser({
    super.key,
    this.starSpeed = 3,
    this.starCount = 500,
    required this.audioData,
  });

  final double starSpeed;
  final int starCount;
  final ffi.Pointer<ffi.Float> audioData;

  @override
  State<StarFieldVisualiser> createState() => _StarFieldVisualiserState();
}

class _StarFieldVisualiserState extends State<StarFieldVisualiser> {
  List<Star> stars = [];
  ui.Image? glowImage;
  double maxZ = 500;
  double minZ = 1;

  Ticker? ticker;

  double _averageFrequency(int low, int high) {
    double total = 0.0;
    int numFrequencies = 0;
    for (int i = low; i <= high; i++) {
      total += widget.audioData[i];
      numFrequencies++;
    }
    return total / numFrequencies;
  }

  @override
  void initState() {
    super.initState();
    _loadGlowImage();

    for (int i = 0; i < widget.starCount; i++) {
      var s = _randomiseStar(true);
      stars.add(s);
    }
    ticker = Ticker(_handleStarTick)..start();
  }

  Future<void> _loadGlowImage() async {
    final ByteData data = await rootBundle.load('assets/glow.png');
    ui.decodeImageFromList(Uint8List.view(data.buffer), (img) => glowImage = img);
  }

  void _handleStarTick(Duration duration) {
    double averageBass = _averageFrequency(bass[0], bass[1]);

    setState(() {
      if (averageBass.round() == 0) {
        advanceStars(widget.starSpeed);
      } else {
        advanceStars(widget.starSpeed + (averageBass));
      }
    });
  }

  @override
  void dispose() {
    ticker?.dispose();
    super.dispose();
  }

  void advanceStars(double distance) {
    for (int i = 0; i < stars.length; i++) {
      stars[i].z -= distance;
      if (stars[i].z < minZ) {
        stars[i] = _randomiseStar(false);
      } else if (stars[i].z > maxZ) {
        stars[i].z = minZ;
      }
    }
  }

  Star _randomiseStar(bool randomZ) {
    Star star = Star();
    Random rand = Random();

    /// randomly distribute stars on screen
    star.x = (-1 + rand.nextDouble() * 2) * 75;
    star.y = (-1 + rand.nextDouble() * 2) * 75;
    star.z = randomZ ? rand.nextDouble() * maxZ : maxZ;
    star.rotation = rand.nextDouble() * pi * 2;

    final double colorRand = rand.nextDouble();
    if (colorRand < 0.05) {
      star.color = Colors.red;
      star.size = 3 + rand.nextDouble() * 2;
    } else if (colorRand < 0.1) {
      star.color = const Color(0xffD4A1FF);
      star.size = 2 + rand.nextDouble() * 2;
    } else {
      star.color = Colors.white;
      star.size = .5 + rand.nextDouble() * 2;
    }
    return star;
  }

  @override
  Widget build(BuildContext context) {
    final ui.Size size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: CustomPaint(
        painter: StarFieldPainter(
          stars,
          glowImage,
          widget.audioData,
          size,
        ),
      ),
    );
  }
}
