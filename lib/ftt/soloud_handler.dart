import 'package:flutter/services.dart';
import 'package:flutter_app_template/ftt/ftt_controller.dart';
import 'package:flutter_app_template/ftt/texture_type.dart';
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'dart:ui' as ui;
import 'dart:ffi' as ffi;
import 'package:flutter/scheduler.dart';

class SoLoudHandler {
  static final SoLoudHandler _singleton = SoLoudHandler._instance();

  factory SoLoudHandler() {
    return _singleton;
  }

  SoLoudHandler._instance();

  AverageFrequencies averageFrequencies = AverageFrequencies();
  bool isPlayerInited = false;
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
  Uint8List? bitMapImage;

  final ValueNotifier<double> soundLength = ValueNotifier(0);

  final ValueNotifier<double> fftSmoothing = ValueNotifier(0.8);
  final ValueNotifier<RangeValues> fftImageRange = ValueNotifier(const RangeValues(0, 255));
  final ValueNotifier<TextureType> textureType = ValueNotifier(TextureType.fft2D);
  FftController visualizerController = FftController()..changeIsVisualizerForPlayer(true);

  Future<void> init() async {
    /// these constants must not be touched since SoLoud
    /// gives back a size of 256 values
    fftSize = 512;
    halfFftSize = fftSize >> 1;

    await initSoLoud();

    if (isPlayerInited) {
      setupBitmapSize();

      playerData = calloc();
    }
  }

  Future<void> initSoLoud() async {
    if (isPlayerInited) return;

    final b = await SoLoud().startIsolate();
    if (b == PlayerErrors.noError) {
      debugPrint('isolate started');
      SoLoud().setVisualizationEnabled(true);
    }
    isPlayerInited = SoLoud().isPlayerInited;
  }

  /// TODO: need to dispose when app is closed!!!
  void dispose() {
    calloc.free(playerData);
    playerData = ffi.nullptr;
  }

  // bool isPlaying() {
  //   // return true;
  //   if (playerData[0].value.round() == 0) {
  //     return bitMapImage == null;
  //   }
  //   return true;

  //   var f = playerData[0];

  //   int? i = f.value.round();

  //   print(i);
  //   return true;

  //   // if (playerData[0] == ffi.nullptr) {
  //   //   if (playerData[256] == ffi.nullptr) {
  //   //     return false;
  //   //   }
  //   // }
  //   // return true;
  //   // return playerData == ffi.nullptr;
  // }

  void setupBitmapSize() {
    fftBitmapRange = visualizerController.maxFreqRange - visualizerController.minFreqRange;
    fftImageRow = Bmp32Header.setHeader(fftBitmapRange, 2);
    fftImageMatrix = Bmp32Header.setHeader(fftBitmapRange, 256);

    switch (textureType.value) {
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

  /// build an image to be passed to the shader.
  /// The image is a matrix of 256x2 RGBA pixels representing:
  /// in the 1st row the frequencies data
  /// in the 2nd row the wave data
  Future<ui.Image?> buildImageFromLatestSamplesRow() async {
    if (!visualizerController.isVisualizerEnabled) {
      return null;
    }

    /// get audio data from player or capture device
    if (visualizerController.isVisualizerForPlayer && isPlayerInited) {
      final ret = SoLoud().getAudioTexture2D(playerData);
      if (ret != PlayerErrors.noError) return null;
    } else if (!visualizerController.isVisualizerForPlayer && isCaptureInited) {
      final ret = SoLoud().getCaptureAudioTexture2D(captureData);
      if (ret != CaptureErrors.captureNoError) {
        return null;
      }
    } else {
      return null;
    }

    // if (!mounted) {
    //   return null;
    // }

    final completer = Completer<ui.Image>();
    final bytes = Uint8List(fftBitmapRange * 2 * 4);
    // Fill the texture bitmap
    var col = 0;
    for (var i = visualizerController.minFreqRange; i < visualizerController.maxFreqRange; ++i, ++col) {
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
    if (!visualizerController.isVisualizerEnabled) {
      return null;
    }

    /// get audio data from player or capture device
    if (visualizerController.isVisualizerForPlayer && isPlayerInited) {
      final ret = SoLoud().getAudioTexture2D(playerData);
      if (ret != PlayerErrors.noError) return null;
    } else if (!visualizerController.isVisualizerForPlayer && isCaptureInited) {
      final ret = SoLoud().getCaptureAudioTexture2D(captureData);
      if (ret != CaptureErrors.captureNoError) {
        return null;
      }
    } else {
      return null;
    }

    // if (!mounted) {
    //   return null;
    // }

    /// IMPORTANT: if [mounted] is not checked here, could happens that
    /// dispose() is called before this is called but it is called!
    /// Since in dispose the [audioData] is freed, there will be a crash!
    /// I do not understand why this happens because the FutureBuilder
    /// seems has not finished before dispose()!?
    /// My psychoanalyst told me to forget it and my mom to study more
    // if (!mounted) {
    //   return null;
    // }
    final completer = Completer<ui.Image>();
    final bytes = Uint8List(fftBitmapRange * 256 * 4);

    // Fill the texture bitmap with wave data
    for (var y = 0; y < 256; ++y) {
      var col = 0;
      for (var x = visualizerController.minFreqRange; x < visualizerController.maxFreqRange; ++x, ++col) {
        bytes[y * fftBitmapRange * 4 + col * 4 + 0] = textureTypeCallback(y, x);
        bytes[y * fftBitmapRange * 4 + col * 4 + 1] = 0;
        bytes[y * fftBitmapRange * 4 + col * 4 + 2] = 0;
        bytes[y * fftBitmapRange * 4 + col * 4 + 3] = 255;
      }
    }

    final bitMapImage = fftImageMatrix.storeBitmap(bytes);
    ui.decodeImageFromList(bitMapImage, completer.complete);

    return completer.future;
  }

  int getFFTDataCallback(int row, int col) {
    if (visualizerController.isVisualizerForPlayer) {
      return (playerData.value[row * fftSize + col] * 255.0).toInt();
    } else {
      return (captureData.value[row * fftSize + col] * 255.0).toInt();
    }
  }

  int getWaveDataCallback(int row, int col) {
    if (visualizerController.isVisualizerForPlayer) {
      return (((playerData.value[row * fftSize + halfFftSize + col] + 1.0) / 2.0) * 128).toInt();
    } else {
      return (((captureData.value[row * fftSize + halfFftSize + col] + 1.0) / 2.0) * 128).toInt();
    }
  }
}
