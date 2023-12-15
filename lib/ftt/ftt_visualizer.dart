import 'package:flutter/material.dart';
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

  double calculateAverageFreq(int lowFreq, int highFreq) {
    var nyquist = 44100 / 2;

    var a = (lowFreq / nyquist * 256).round();
    var b = (highFreq / nyquist * 256).round();
    var total = 0.0;
    var numFreq = 0;

    // print('from: $a to $b');
    for (int i = a; i <= b; i++) {
      total += audioData[i];
      numFreq++;
    }

    var average = total / numFreq;
    return average;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (maxFreq - minFreq);
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = barWidth * 0.8
      ..style = PaintingStyle.stroke;

    // var nyquist = 44100 / 2;
    // var freq1 = audioData[20];

    // var b = (freq1 / nyquist * 256);
    // print(b);

    // print(audioData[20]);
    // print(audioData[140]);

    // print(audioData[0]);

    // var a = (20 / nyquist * 256).round();
    // var b = (140 / nyquist * 256).round();
    // var total = 0.0;
    // var numFreq = 0;

    // // print('from: $a to $b');
    // for (int i = a; i <= b; i++) {
    //   total += audioData[i];
    //   numFreq++;
    // }

    /// TODO: pick up from here and work out what the bass, low end, mid, high, etc ranges are if we
    /// only have 256 samples. Hardcode these values somewhere so that we don't needlessly calculate them each frame.
    /// Then when we pass in the fft data we can get the averages of these values and use them in our visualisation

    // var average = total / numFreq;

    // var bass = calculateAverageFreq(20, 140);
    // print('bass average: $bass');

    // var lowMid = calculateAverageFreq(140, 400);
    // print('lowMid average: ${lowMid}');

    // this.bass = [20, 140];
    // this.lowMid = [140, 400];
    // this.mid = [400, 2600];
    // this.highMid = [2600, 5200];
    // this.treble = [5200, 14000];

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
