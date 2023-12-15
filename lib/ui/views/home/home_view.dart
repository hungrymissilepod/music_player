import 'dart:async';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:ffi' as ffi;
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_app_template/ui/common/app_colors.dart';
import 'package:flutter_app_template/ui/common/ui_helpers.dart';

import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  final int startingIndex;
  HomeView({Key? key, required this.startingIndex}) : super(key: key);

  final ValueNotifier<RangeValues> fftImageRange = ValueNotifier(const RangeValues(0, 255));
  final ValueNotifier<TextureType> textureType = ValueNotifier(TextureType.fft2D);
  FftController visualizerController = FftController()..changeIsVisualizerForPlayer(true);

  String shader = 'assets/shaders/test9.frag';

  /// load asynchronously the fragment shader
  Future<ui.FragmentShader?> loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(shader);
      return program.fragmentShader();
    } catch (e) {
      debugPrint('error compiling the shader: $e');
    }
    return null;
  }

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                verticalSpaceLarge,
                Column(
                  children: [
                    const Text(
                      'Hello, STACKED!',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    verticalSpaceMedium,
                    MaterialButton(
                      color: Colors.black,
                      onPressed: viewModel.incrementCounter,
                      child: Text(
                        viewModel.counterLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      child: Text('Play: Tropical Beeper'),
                      onPressed: () {
                        viewModel.playAsset('assets/audio/baddadan.mp3');
                        viewModel.notifyListeners();
                      },
                    ),

                    /// fft range slider values to put into the texture
                    ValueListenableBuilder<RangeValues>(
                      valueListenable: fftImageRange,
                      builder: (_, fftRange, __) {
                        return Row(
                          children: [
                            Text('FFT range ${fftRange.start.toInt()}'),
                            Expanded(
                              child: RangeSlider(
                                max: 255,
                                divisions: 256,
                                values: fftRange,
                                onChanged: (values) {
                                  fftImageRange.value = values;
                                  visualizerController
                                    ..changeMinFreq(values.start.toInt())
                                    ..changeMaxFreq(values.end.toInt());
                                },
                              ),
                            ),
                            Text('${fftRange.end.toInt()}'),
                          ],
                        );
                      },
                    ),
                    ValueListenableBuilder<TextureType>(
                      valueListenable: textureType,
                      builder: (_, type, __) {
                        // return SizedBox.shrink();
                        return Visualizer(
                          key: UniqueKey(),
                          controller: visualizerController,
                          // shader: snapshot.data!,
                          textureType: type,
                        );
                      },
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MaterialButton(
                      color: kcDarkGreyColor,
                      onPressed: viewModel.showDialog,
                      child: const Text(
                        'Show Dialog',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    MaterialButton(
                      color: kcDarkGreyColor,
                      onPressed: viewModel.showBottomSheet,
                      child: const Text(
                        'Show Bottom Sheet',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      HomeViewModel(startingIndex);
}

/// enum to tell [Visualizer] to build a texture as:
/// [both1D] frequencies data on the 1st 256px row, wave on the 2nd 256px
/// [fft2D] frequencies data 256x256 px
/// [wave2D] wave data 256x256px
/// [both2D] both frequencies & wave data interleaved 256x512px
enum TextureType {
  both1D,
  fft2D,
  wave2D,
  both2D, // no implemented yet
}

class FftController extends ChangeNotifier {
  FftController({
    this.minFreqRange = 0,
    this.maxFreqRange = 255,
    this.isVisualizerEnabled = true,
    this.isVisualizerForPlayer = false,
  });

  int minFreqRange;
  int maxFreqRange;
  bool isVisualizerEnabled;
  bool isVisualizerForPlayer;

  void changeMinFreq(int minFreq) {
    if (minFreq < 0) return;
    if (minFreq >= maxFreqRange) return;
    minFreqRange = minFreq;
    notifyListeners();
  }

  void changeMaxFreq(int maxFreq) {
    if (maxFreq > 255) return;
    if (maxFreq <= minFreqRange) return;
    maxFreqRange = maxFreq;
    notifyListeners();
  }

  void changeIsVisualizerForPlayer(bool isForPlayer) {
    isVisualizerForPlayer = isForPlayer;
    notifyListeners();
  }

  void changeIsVisualizerEnabled(bool enable) {
    isVisualizerEnabled = enable;
    notifyListeners();
    SoLoud().setVisualizationEnabled(enable);
  }
}

class Visualizer extends StatefulWidget {
  const Visualizer({
    required this.controller,
    // required this.shader,
    this.textureType = TextureType.fft2D,
    super.key,
  });

  final FftController controller;
  // final ui.FragmentShader shader;
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

                /// paint texture passed to the shader
                // DisableButton(
                //   width: constraints.maxWidth,
                //   height: constraints.maxWidth / 6,
                //   onPressed: () {
                //     sw.reset();
                //     nFrames = 0;
                //   },
                //   child: PaintTexture(
                //     width: constraints.maxWidth,
                //     height: constraints.maxWidth / 6,
                //     image: dataTexture.data!,
                //   ),
                // ),

                // const Text(
                //   'SHADER',
                //   style: TextStyle(fontWeight: FontWeight.bold),
                // ),
                // DisableButton(
                //   width: constraints.maxWidth,
                //   height: constraints.maxWidth / 2.4,
                //   onPressed: () {
                //     sw.reset();
                //     nFrames = 0;
                //   },
                //   child: AudioShader(
                //     width: constraints.maxWidth,
                //     height: constraints.maxWidth / 2.4,
                //     image: dataTexture.data!,
                //     shader: widget.shader,
                //     iTime: sw.elapsedMilliseconds / 1000.0,
                //   ),
                // ),

                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          '$nFft FFT data',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        /// FFT bars
                        DisableButton(
                          width: constraints.maxWidth / 2 - 3,
                          height: constraints.maxWidth / 6,
                          onPressed: () {
                            sw.reset();
                            nFrames = 0;
                          },
                          child: BarsFftWidget(
                            audioData: playerData.value,
                            minFreq: widget.controller.minFreqRange,
                            maxFreq: widget.controller.maxFreqRange,
                            width: constraints.maxWidth / 2 - 3,
                            height: constraints.maxWidth / 6,
                          ),
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
                        DisableButton(
                          width: constraints.maxWidth / 2 - 3,
                          height: constraints.maxWidth / 6,
                          onPressed: () {
                            sw.reset();
                            nFrames = 0;
                          },
                          child: BarsWaveWidget(
                            audioData: widget.controller.isVisualizerForPlayer ? playerData.value : captureData.value,
                            width: constraints.maxWidth / 2 - 3,
                            height: constraints.maxWidth / 6,
                          ),
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

class DisableButton extends StatefulWidget {
  const DisableButton({
    required this.width,
    required this.height,
    required this.child,
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;
  final double width;
  final double height;
  final Widget child;

  @override
  State<DisableButton> createState() => _DisableButtonState();
}

class _DisableButtonState extends State<DisableButton> {
  late bool isChildVisible;

  @override
  void initState() {
    super.initState();
    isChildVisible = true;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          if (isChildVisible) widget.child else const Placeholder(),
          Align(
            alignment: Alignment.topRight,
            child: FloatingActionButton.small(
              onPressed: () {
                isChildVisible = !isChildVisible;
                setState(() {});
                widget.onPressed();
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

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

    var nyquist = 44100 / 2;
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

/// Draw the audio wave data
///
class BarsWaveWidget extends StatelessWidget {
  const BarsWaveWidget({
    required this.audioData,
    required this.width,
    required this.height,
    super.key,
  });

  final ffi.Pointer<ffi.Float> audioData;
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
                painter: WavePainter(audioData: audioData),
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
class WavePainter extends CustomPainter {
  const WavePainter({
    required this.audioData,
  });
  final ffi.Pointer<ffi.Float> audioData;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 256;
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = barWidth * 0.8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 256; i++) {
      final barHeight = size.height * audioData[i + 256];
      canvas.drawRect(
        Rect.fromLTWH(
          barWidth * i,
          (size.height - barHeight) / 2,
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
