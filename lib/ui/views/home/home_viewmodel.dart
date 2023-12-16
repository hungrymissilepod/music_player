import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/ftt/ftt_controller.dart';
import 'package:flutter_app_template/ftt/texture_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:stacked/stacked.dart';

enum HomeViewSection { player }

class HomeViewModel extends BaseViewModel {
  SoundProps? currentSound;

  final ValueNotifier<double> soundLength = ValueNotifier(0);

  final ValueNotifier<double> fftSmoothing = ValueNotifier(0.8);
  final ValueNotifier<RangeValues> fftImageRange = ValueNotifier(const RangeValues(0, 255));
  final ValueNotifier<TextureType> textureType = ValueNotifier(TextureType.fft2D);
  FftController visualizerController = FftController()..changeIsVisualizerForPlayer(true);

  List<String> exampleSongs = [
    'baddadan.mp3',
    'sample.mp3',
    'sample2.mp3',
    'massive&crew.mp3',
    'leavemealone.mp3',
    'Tropical Beeper.mp3',
    'X trackTure.mp3',
    '8_bit_mentality.mp3',
    'range_test.mp3',
  ];

  int currentSong = 0;

  HomeViewModel() {
    runBusyFuture(initSoLoud(), busyObject: HomeViewSection.player);
  }

  Future<void> initSoLoud() async {
    final b = await SoLoud().startIsolate();
    if (b == PlayerErrors.noError) {
      debugPrint('isolate started');
      SoLoud().setVisualizationEnabled(true);
    }
  }

  Future<void> stopSoLoud() async {
    SoLoud().stopIsolate();
  }

  Future<void> playCurrentExampleSong() async {
    await stop();
    final String path = 'assets/audio/${exampleSongs[currentSong]}';
    playAsset(path);
    notifyListeners();
  }

  Future<void> stop() async {
    if (currentSound != null) {
      if (currentSound!.handle.isNotEmpty) {
        SoLoud().stop(currentSound!.handle.first);
      }
    }
  }

  Future<void> pause() async {
    if (currentSound != null) {
      if (currentSound!.handle.isNotEmpty) {
        SoLoud().pauseSwitch(currentSound!.handle.first);
      }
    }
  }

  Future<void> nextSong() async {
    currentSong++;
    if (currentSong > exampleSongs.length - 1) {
      currentSong = 0;
    }
    notifyListeners();
    await playCurrentExampleSong();
  }

  Future<void> prevSong() async {
    currentSong--;
    if (currentSong < 0) {
      currentSong = exampleSongs.length - 1;
    }
    notifyListeners();
    await playCurrentExampleSong();
  }

  Future<void> playFromUrl() async {
    final String url =
        'https://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Kangaroo_MusiQue_-_The_Neverwritten_Role_Playing_Game.mp3';
    SoundProps? soundProps = await SoloudTools.loadFromUrl(url);
    if (soundProps != null) {
      await SoLoud().play(soundProps);
    }
  }

  /// plays an assets file
  Future<void> playAsset(String assetsFile) async {
    final audioFile = await _getAssetFile(assetsFile);
    return _play(audioFile.path);
  }

  /// play file
  Future<void> _play(String file) async {
    if (currentSound != null) {
      if (await SoLoud().disposeSound(currentSound!) != PlayerErrors.noError) {
        return;
      }
    }

    /// load the file
    final loadRet = await SoLoud().loadFile(file);
    if (loadRet.error != PlayerErrors.noError) return;
    currentSound = loadRet.sound;

    /// play it
    final playRet = await SoLoud().play(currentSound!);
    if (loadRet.error != PlayerErrors.noError) return;
    currentSound = playRet.sound;

    /// get its length and notify it
    soundLength.value = SoLoud().getLength(currentSound!).length;

    /// Stop the timer and dispose the sound when the sound ends
    currentSound!.soundEvents.stream.listen(
      (event) {
        // TODO(me): put this elsewhere?
        event.sound.soundEvents.close();

        /// It's needed to call dispose when it end else it will
        /// not be cleared
        SoLoud().disposeSound(currentSound!);
        currentSound = null;
      },
    );
  }

  /// get the assets file and copy it to the temp dir
  Future<File> _getAssetFile(String assetsFile) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    final filePath = '$tempPath/$assetsFile';
    final file = File(filePath);
    if (file.existsSync()) {
      return file;
    } else {
      final byteData = await rootBundle.load(assetsFile);
      final buffer = byteData.buffer;
      await file.create(recursive: true);
      return file.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
    }
  }
}
