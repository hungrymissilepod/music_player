import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:ffi' as ffi;
import 'package:flutter/scheduler.dart';
import 'package:flutter_app_template/ftt/bar_wave_visualizer.dart';
import 'package:flutter_app_template/ftt/ftt_controller.dart';
import 'package:flutter_app_template/ftt/ftt_visualizer.dart';
import 'package:flutter_app_template/ftt/texture_type.dart';
import 'package:flutter_app_template/ui/views/home/home_viewmodel.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:num_remap/num_remap.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

List<int> bass = <int>[0, 2];
List<int> lowMid = <int>[2, 5];
List<int> mid = <int>[5, 30];
List<int> highMid = <int>[30, 60];
List<int> treble = <int>[60, 164];

class AverageFrequencies {
  double bass = -1;
  double lowMid = -1;
  double mid = -1;
  double highMid = -1;
  double treble = -1;

  printData() {
    print('bass: $bass - lowMid: $lowMid - mid: $mid - highMid: $highMid - treble: $treble');
  }
}

class Visualizer extends StatefulWidget {
  const Visualizer({
    required this.controller,
    required this.setupBitmapSize,
    required this.viewModel,
    this.textureType = TextureType.fft2D,
    super.key,
  });

  final FftController controller;
  final TextureType textureType;
  final Function() setupBitmapSize;
  final HomeViewModel viewModel;

  @override
  State<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer> with SingleTickerProviderStateMixin {
  /// TODO: do we need this?
  late bool isPlayerInited;
  late Ticker ticker;
  @override
  void initState() {
    super.initState();

    isPlayerInited = SoLoud().isPlayerInited;
    SoLoud().audioEvent.stream.listen(
      (event) {
        isPlayerInited = SoLoud().isPlayerInited;
      },
    );

    ticker = createTicker(_tick);
    ticker.start();

    widget.controller.addListener(() {
      ticker.stop();
      widget.setupBitmapSize();
      ticker.start();
    });
  }

  @override
  void dispose() {
    ticker.stop();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image?>(
      future: widget.viewModel.soLoudHandler.buildImageCallback(),
      builder: (context, dataTexture) {
        if (!dataTexture.hasData || dataTexture.data == null) {
          return Placeholder(
            color: Colors.yellow,
            fallbackWidth: 100,
            fallbackHeight: 100,
            strokeWidth: 0.5,
            child: Text("can't get audio samples"),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        /// FFT bars
                        BarsFftWidget(
                          audioData: widget.viewModel.soLoudHandler.playerData.value,
                          minFreq: widget.controller.minFreqRange,
                          maxFreq: widget.controller.maxFreqRange,
                          width: constraints.maxWidth / 2 - 3,
                          height: constraints.maxWidth / 6,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Column(
                      children: [
                        const Text(
                          '256 wave data',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        /// wave data bars
                        BarsWaveWidget(
                          audioData: widget.controller.isVisualizerForPlayer
                              ? widget.viewModel.soLoudHandler.playerData.value
                              : widget.viewModel.soLoudHandler.captureData.value,
                          width: constraints.maxWidth / 2 - 3,
                          height: constraints.maxWidth / 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class Bmp32Header {
  late int width;
  late int height;
  late Uint8List bmp;
  late int contentSize;
  int rgba32HeaderSize = 122;
  int bytesPerPixel = 4;

  /// set a BMP from bytes
  Bmp32Header.setBmp(Uint8List imgBytes) {
    final bd = imgBytes.buffer.asByteData();
    width = bd.getInt32(0x12, Endian.little);
    height = -bd.getInt32(0x16, Endian.little);
    contentSize = bd.getInt32(0x02, Endian.little) - rgba32HeaderSize;
    bmp = imgBytes;
  }

  /// set BMP header and memory to use
  Bmp32Header.setHeader(this.width, this.height) {
    contentSize = width * height;
    bmp = Uint8List(rgba32HeaderSize + contentSize * bytesPerPixel);

    bmp.buffer.asByteData()
      ..setUint8(0x00, 0x42) // 'B'
      ..setUint8(0x01, 0x4d) // 'M'

      ..setInt32(0x02, rgba32HeaderSize + contentSize, Endian.little)
      ..setInt32(0x0A, rgba32HeaderSize, Endian.little)
      ..setUint32(0x0E, 108, Endian.little)
      ..setUint32(0x12, width, Endian.little)
      ..setUint32(0x16, -height, Endian.little)
      ..setUint16(0x1A, 1, Endian.little)
      ..setUint8(0x1C, 32)
      ..setUint32(0x1E, 3, Endian.little)
      ..setUint32(0x22, contentSize, Endian.little)
      ..setUint32(0x36, 0x000000ff, Endian.little)
      ..setUint32(0x3A, 0x0000ff00, Endian.little)
      ..setUint32(0x3E, 0x00ff0000, Endian.little)
      ..setUint32(0x42, 0xff000000, Endian.little);
  }

  /// Insert the [bitmap] after the header and return the BMP
  Uint8List storeBitmap(Uint8List bitmap) {
    bmp.setRange(rgba32HeaderSize, bmp.length, bitmap);
    return bmp;
  }

  /// clear BMP pixels leaving the header untouched
  Uint8List clearBitmap() {
    bmp.fillRange(rgba32HeaderSize, bmp.length, 0);
    return bmp;
  }

  /// set BMP pixels color
  Uint8List setBitmapBackgroundColor(int r, int g, int b, int a) {
    final value = (((r & 0xff) << 0) | ((g & 0xff) << 8) | ((b & 0xff) << 16) | ((a & 0xff) << 24)) & 0xFFFFFFFF;
    final tmp = bmp.sublist(rgba32HeaderSize).buffer.asUint32List();
    tmp.fillRange(0, tmp.length, value);

    final bytes = BytesBuilder()
      ..add(bmp.sublist(0, rgba32HeaderSize))
      ..add(tmp.buffer.asUint8List());
    // ignore: join_return_with_assignment
    bmp = bytes.toBytes();

    return bmp;
  }
}

List<Particle> particles = [];
Random random = Random();

class StarsPainter extends CustomPainter {
  StarsPainter({
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
