import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/ftt/soloud_handler.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:num_remap/num_remap.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

Random random = Random();

List<StarParticle> backgroundParticles = [];
int maxBackgroundParticles = 100;
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

    // if (backgroundParticles.length < maxBackgroundParticles) {
    //   var p =
    //       StarParticle(size, baseAcceleration: backgroundParticlesBaseAcceleration, maxSize: backgroundMaxParticleSize, circleRadius: );
    //   backgroundParticles.add(p);
    // }

    // for (int i = 0; i < backgroundParticles.length; i++) {
    //   backgroundParticles[i].update(averageLowMid);

    //   var scale = .1 + map(backgroundParticles[i].position.z, 0, size.width, backgroundParticles[i].size, 0);
    //   var sx = map(backgroundParticles[i].position.x / backgroundParticles[i].position.z, 0, 1, 0, size.width);
    //   var sy = map(backgroundParticles[i].position.y / backgroundParticles[i].position.z, 0, 1, 0, size.height);

    //   var time = DateTime.now().millisecondsSinceEpoch / 1000;

    //   var glowSizeX = 1 * 8 + 2 * (sin(time * .5));
    //   var glowSizeY = 1 * 8 + 2 * (cos(time * .75));

    //   var pos = Offset(sx, sy);
    //   var rect = Rect.fromCenter(center: pos, width: glowSizeX, height: glowSizeY);
    //   canvas.drawRect(rect, whitePaint..color = backgroundParticles[i].color);

    // canvas.drawCircle(
    //   Offset(backgroundParticles[i].position.x, backgroundParticles[i].position.y),
    //   backgroundParticles[i].size,
    //   whitePaint..color = backgroundParticles[i].color,
    // );

    /// Reset any particles that go off screen
    // if (backgroundParticles[i].shouldCull()) {
    //   backgroundParticles[i].resetPosition(size, false);
    //   backgroundParticles[i].initRandomly(size);
    // } else {
    //   backgroundParticles[i].update(averageLowMid);

    //   canvas.drawCircle(
    //     Offset(backgroundParticles[i].position.x, backgroundParticles[i].position.y),
    //     backgroundParticles[i].size,
    //     whitePaint..color = backgroundParticles[i].color,
    //   );
    // }
    // }

    /// Draw particles around circle
    // if (particles.length < maxParticles) {
    //   var p = StarParticle(size, circleRadius: midCircleRadius, maxSize: maxParticleSize);
    //   particles.add(p);
    // }

    // for (int i = particles.length - 1; i >= 0; i--) {
    //   print('running');

    //   /// Reset any particles that go off screen
    //   if (particles[i].shouldCull()) {
    //     particles[i].resetPosition();
    //     particles[i].initAroundCircle(midCircleRadius);
    //   } else {
    //     particles[i].update(averageBass);

    //     canvas.drawCircle(
    //       Offset(particles[i].pos.x, particles[i].pos.y),
    //       particles[i].size,
    //       whitePaint..color = particles[i].color,
    //     );
    //   }
    // }

    // /// We draw the circle in two halves
    // /// The first time we draw the right side and the second time we draw the left side
    // for (int t = -1; t <= 1; t += 2) {
    //   List<Offset> points = [];

    //   for (double i = 0; i < 180; i += 0.5) {
    //     final index = i.remap(0, 180, 0, samples - 1).floor();

    //     /// Map the [audioData] to the size of the circle (one half of it)
    //     var r = audioData[index + 256].remap(
    //       -1,
    //       1,
    //       (minCircleRadius + (averageTreble * trebleMultiplier)),
    //       (maxCirlceRadius + (averageTreble * trebleMultiplier)),
    //     );

    //     /// Plot points around the circle radius
    //     /// [t] here is used to flip the x axis over when drawing the other half
    //     double x = r * sin(i * (pi / 180)) * t;
    //     double y = r * cos(i * (pi / 180));
    //     points.add(Offset(x, y));
    //   }
    //   circlePaint.strokeWidth = 2.5 + (averageTreble * 8);
    //   canvas.drawPoints(PointMode.polygon, points, circlePaint);
    // }
  }

  double map(double value, double from1, double to1, double from2, double to2) {
    return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class StarParticle {
  vector_math.Vector3 position = vector_math.Vector3(0, 0, 0);

  vector_math.Vector2 pos = vector_math.Vector2(0, 0);
  vector_math.Vector2 velocity = vector_math.Vector2(0, 0);
  vector_math.Vector2 acceleration = vector_math.Vector2(0, 0);

  double size = 4;
  Color color = Colors.white;

  Size _canvasSize = Size.zero;
  double _accelerationValue = 0.0;
  double _maxSize = 0.0;

  double maxZ = 500;
  double minZ = 1;

  StarParticle(
    Size canvasSize, {
    double? circleRadius,
    double baseAcceleration = 0.0005,
    double maxSize = 0.0,
    bool randomZ = true,
  }) {
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

    // position.x = (-1 + random.nextDouble() * 2) * canvasSize.width / 2;
    // position.y = (-1 + random.nextDouble() * 2) * canvasSize.height / 2;
    // position.z = randomZ ? random.nextDouble() * maxZ : maxZ;
    // print('z: ${position.z}');
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

    // position.z -= 0.0001;
    // print('update z: ${position.z}');
    // shouldCull();
  }

  /// If particle goes off screen
  bool shouldCull() {
    // if (position.z < minZ) {
    //   // print('cull');
    //   resetPosition();
    //   return true;
    // } else {
    //   position.z = minZ;
    // }

    if (pos.x < -_canvasSize.width / 2 ||
        pos.x > _canvasSize.width / 2 ||
        pos.y < -_canvasSize.height / 2 ||
        pos.y > _canvasSize.height / 2) {
      return true;
    }
    return false;
  }
}

////////////////////

class StarField extends StatefulWidget {
  const StarField({
    super.key,
    this.starSpeed = 3,
    this.starCount = 500,
    required this.audioData,
  });

  final double starSpeed;
  final int starCount;
  final ffi.Pointer<ffi.Float> audioData;

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField> {
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

class Star {
  double x;
  double y;
  double z;
  double size = 1;
  double rotation = 0;
  Color color = Colors.white;

  Star({this.x = 0, this.y = 0, this.z = 0});
}

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final ui.Image? glowImage;
  final ffi.Pointer<ffi.Float> audioData;

  StarFieldPainter(this.stars, this.glowImage, this.audioData, this.canvasSize) {
    maxCirlceRadius = canvasSize.width / 2.5;
    midCircleRadius = (minCircleRadius + maxCirlceRadius) / 2;
  }

  final Size canvasSize;

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
    if (particles.length < maxParticles) {
      var p = StarParticle(size, circleRadius: midCircleRadius, maxSize: maxParticleSize);
      particles.add(p);
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
      canvas.drawPoints(ui.PointMode.polygon, points, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  double map(double value, double from1, double to1, double from2, double to2) {
    return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
  }
}
