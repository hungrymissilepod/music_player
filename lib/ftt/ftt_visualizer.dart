import 'package:flutter/material.dart';
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'dart:ffi' as ffi;

class BarsFftWidget extends StatelessWidget {
  const BarsFftWidget({
    required this.audioData,
    required this.minFreq,
    required this.maxFreq,
    required this.width,
    required this.height,
    super.key,
  });

  final ffi.Pointer<ffi.Float> audioData;
  final int minFreq;
  final int maxFreq;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (audioData.address == 0x0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColoredBox(
          color: Colors.black,
          child: RepaintBoundary(
            child: ClipRRect(
              child: CustomPaint(
                size: Size(width, height),
                painter: FftPainter(
                  audioData: audioData,
                  minFreq: minFreq,
                  maxFreq: maxFreq,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to draw the wave in a circle
///
class FftPainter extends CustomPainter {
  const FftPainter({
    required this.audioData,
    required this.minFreq,
    required this.maxFreq,
  });
  final ffi.Pointer<ffi.Float> audioData;
  final int minFreq;
  final int maxFreq;

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
    final barWidth = size.width / (maxFreq - minFreq);
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = barWidth * 0.8
      ..style = PaintingStyle.stroke;

    /// TODO: should only calculate this if we are actually playing music
    // double averageBass = _averageFrequency(bass[0], bass[1]);
    // double averageLogMid = _averageFrequency(lowMid[0], lowMid[1]);
    // double averageMid = _averageFrequency(mid[0], mid[1]);
    // double averageHighMid = _averageFrequency(highMid[0], highMid[1]);
    // double averageTreble = _averageFrequency(treble[0], treble[1]);

    // print('bass: $averageBass');
    // print('lowMid: $averageLogMid');
    // print('mid: $averageMid');
    // print('highMid: $averageHighMid');
    // print('treble: $averageTreble');

    for (var i = minFreq; i <= maxFreq; i++) {
      final barHeight = size.height * audioData[i];
      canvas.drawRect(
        Rect.fromLTWH(
          barWidth * (i - minFreq),
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
