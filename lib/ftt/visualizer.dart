import 'dart:async';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:ffi' as ffi;
import 'package:flutter/scheduler.dart';
import 'package:flutter_app_template/ftt/bar_wave_visualizer.dart';
import 'package:flutter_app_template/ftt/ftt_controller.dart';
import 'package:flutter_app_template/ftt/ftt_visualizer.dart';
import 'package:flutter_app_template/ftt/texture_type.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Visualizer extends StatefulWidget {
  const Visualizer({
    required this.controller,
    this.textureType = TextureType.fft2D,
    super.key,
  });

  final FftController controller;
  final TextureType textureType;

  @override
  State<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer> with SingleTickerProviderStateMixin {
  late bool isPlayerInited;
  late bool isCaptureInited;
  late Ticker ticker;
  late Stopwatch sw;
  late Bmp32Header fftImageRow;
  late Bmp32Header fftImageMatrix;
  late int fftSize;
  late int halfFftSize;
  late int fftBitmapRange;
  ffi.Pointer<ffi.Pointer<ffi.Float>> playerData = ffi.nullptr;
  ffi.Pointer<ffi.Pointer<ffi.Float>> captureData = ffi.nullptr;
  late Future<ui.Image?> Function() buildImageCallback;
  late int Function(int row, int col) textureTypeCallback;
  int nFrames = 0;

  @override
  void initState() {
    super.initState();

    isPlayerInited = SoLoud().isPlayerInited;
    isCaptureInited = SoLoud().isCaptureInited;
    SoLoud().audioEvent.stream.listen(
      (event) {
        isPlayerInited = SoLoud().isPlayerInited;
        isCaptureInited = SoLoud().isCaptureInited;
      },
    );

    /// these constants must not be touched since SoLoud
    /// gives back a size of 256 values
    fftSize = 512;
    halfFftSize = fftSize >> 1;

    playerData = calloc();
    captureData = calloc();

    ticker = createTicker(_tick);
    sw = Stopwatch();
    sw.start();
    setupBitmapSize();
    ticker.start();

    widget.controller.addListener(() {
      ticker.stop();
      setupBitmapSize();
      ticker.start();
      sw.reset();
      nFrames = 0;
    });
  }

  @override
  void dispose() {
    ticker.stop();
    sw.stop();
    calloc.free(playerData);
    playerData = ffi.nullptr;
    calloc.free(captureData);
    captureData = ffi.nullptr;
    super.dispose();
  }

  void _tick(Duration elapsed) {
    nFrames++;
    if (mounted) {
      setState(() {});
    }
  }

  void setupBitmapSize() {
    fftBitmapRange = widget.controller.maxFreqRange - widget.controller.minFreqRange;
    fftImageRow = Bmp32Header.setHeader(fftBitmapRange, 2);
    fftImageMatrix = Bmp32Header.setHeader(fftBitmapRange, 256);

    switch (widget.textureType) {
      case TextureType.both1D:
        {
          buildImageCallback = buildImageFromLatestSamplesRow;
          break;
        }
      case TextureType.fft2D:
        {
          buildImageCallback = buildImageFromAllSamplesMatrix;
          textureTypeCallback = getFFTDataCallback;
          break;
        }
      case TextureType.wave2D:
        {
          buildImageCallback = buildImageFromAllSamplesMatrix;
          textureTypeCallback = getWaveDataCallback;
          break;
        }
      // TODO(me): implement this
      case TextureType.both2D:
        {
          buildImageCallback = buildImageFromAllSamplesMatrix;
          textureTypeCallback = getWaveDataCallback;
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image?>(
      future: buildImageCallback(),
      builder: (context, dataTexture) {
        final fps = nFrames.toDouble() / (sw.elapsedMilliseconds / 1000.0);
        if (!dataTexture.hasData || dataTexture.data == null) {
          return Placeholder(
            color: Colors.yellow,
            fallbackWidth: 100,
            fallbackHeight: 100,
            strokeWidth: 0.5,
            child: Text("can't get audio samples\n"
                'FPS: ${fps.toStringAsFixed(1)}'),
          );
        }

        final nFft = widget.controller.maxFreqRange - widget.controller.minFreqRange;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FPS: ${fps.toStringAsFixed(1)}     '
                  'the texture sent to the shader',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          '$nFft FFT data',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        /// FFT bars
                        BarsFftWidget(
                          audioData: playerData.value,
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
                          audioData: widget.controller.isVisualizerForPlayer ? playerData.value : captureData.value,
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

  /// build an image to be passed to the shader.
  /// The image is a matrix of 256x2 RGBA pixels representing:
  /// in the 1st row the frequencies data
  /// in the 2nd row the wave data
  Future<ui.Image?> buildImageFromLatestSamplesRow() async {
    if (!widget.controller.isVisualizerEnabled) {
      return null;
    }

    /// get audio data from player or capture device
    if (widget.controller.isVisualizerForPlayer && isPlayerInited) {
      final ret = SoLoud().getAudioTexture2D(playerData);
      if (ret != PlayerErrors.noError) return null;
    } else if (!widget.controller.isVisualizerForPlayer && isCaptureInited) {
      final ret = SoLoud().getCaptureAudioTexture2D(captureData);
      if (ret != CaptureErrors.captureNoError) {
        return null;
      }
    } else {
      return null;
    }

    if (!mounted) {
      return null;
    }

    final completer = Completer<ui.Image>();
    final bytes = Uint8List(fftBitmapRange * 2 * 4);
    // Fill the texture bitmap
    var col = 0;
    for (var i = widget.controller.minFreqRange; i < widget.controller.maxFreqRange; ++i, ++col) {
      // fill 1st bitmap row with magnitude
      bytes[col * 4 + 0] = getFFTDataCallback(0, i);
      bytes[col * 4 + 1] = 0;
      bytes[col * 4 + 2] = 0;
      bytes[col * 4 + 3] = 255;
      // fill 2nd bitmap row with amplitude
      bytes[(fftBitmapRange + col) * 4 + 0] = getWaveDataCallback(0, i);
      bytes[(fftBitmapRange + col) * 4 + 1] = 0;
      bytes[(fftBitmapRange + col) * 4 + 2] = 0;
      bytes[(fftBitmapRange + col) * 4 + 3] = 255;
    }

    final img = fftImageRow.storeBitmap(bytes);
    ui.decodeImageFromList(img, completer.complete);

    return completer.future;
  }

  /// build an image to be passed to the shader.
  /// The image is a matrix of 256x256 RGBA pixels representing
  /// rows of wave data or frequencies data.
  /// Passing [getWaveDataCallback] as parameter, it will return wave data
  /// Passing [getFFTDataCallback] as parameter, it will return FFT data
  Future<ui.Image?> buildImageFromAllSamplesMatrix() async {
    if (!widget.controller.isVisualizerEnabled) {
      return null;
    }

    /// get audio data from player or capture device
    if (widget.controller.isVisualizerForPlayer && isPlayerInited) {
      final ret = SoLoud().getAudioTexture2D(playerData);
      if (ret != PlayerErrors.noError) return null;
    } else if (!widget.controller.isVisualizerForPlayer && isCaptureInited) {
      final ret = SoLoud().getCaptureAudioTexture2D(captureData);
      if (ret != CaptureErrors.captureNoError) {
        return null;
      }
    } else {
      return null;
    }

    if (!mounted) {
      return null;
    }

    /// IMPORTANT: if [mounted] is not checked here, could happens that
    /// dispose() is called before this is called but it is called!
    /// Since in dispose the [audioData] is freed, there will be a crash!
    /// I do not understand why this happens because the FutureBuilder
    /// seems has not finished before dispose()!?
    /// My psychoanalyst told me to forget it and my mom to study more
    if (!mounted) {
      return null;
    }
    final completer = Completer<ui.Image>();
    final bytes = Uint8List(fftBitmapRange * 256 * 4);

    // Fill the texture bitmap with wave data
    for (var y = 0; y < 256; ++y) {
      var col = 0;
      for (var x = widget.controller.minFreqRange; x < widget.controller.maxFreqRange; ++x, ++col) {
        bytes[y * fftBitmapRange * 4 + col * 4 + 0] = textureTypeCallback(y, x);
        bytes[y * fftBitmapRange * 4 + col * 4 + 1] = 0;
        bytes[y * fftBitmapRange * 4 + col * 4 + 2] = 0;
        bytes[y * fftBitmapRange * 4 + col * 4 + 3] = 255;
      }
    }

    final img = fftImageMatrix.storeBitmap(bytes);
    ui.decodeImageFromList(img, completer.complete);

    return completer.future;
  }

  int getFFTDataCallback(int row, int col) {
    if (widget.controller.isVisualizerForPlayer) {
      return (playerData.value[row * fftSize + col] * 255.0).toInt();
    } else {
      return (captureData.value[row * fftSize + col] * 255.0).toInt();
    }
  }

  int getWaveDataCallback(int row, int col) {
    if (widget.controller.isVisualizerForPlayer) {
      return (((playerData.value[row * fftSize + halfFftSize + col] + 1.0) / 2.0) * 128).toInt();
    } else {
      return (((captureData.value[row * fftSize + halfFftSize + col] + 1.0) / 2.0) * 128).toInt();
    }
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
