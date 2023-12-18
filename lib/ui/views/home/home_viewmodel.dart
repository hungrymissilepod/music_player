import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/ftt/soloud_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:stacked/stacked.dart';
import 'dart:async';

enum HomeViewSection { player }

class HomeViewModel extends BaseViewModel {
  SoLoudHandler soLoudHandler = SoLoudHandler();

  bool fpsMonitorEnabled = false;

  void toggleFpsMonitor() {
    fpsMonitorEnabled = !fpsMonitorEnabled;
    notifyListeners();
  }

  bool showPlayerControls = true;

  void togglePlayerControls() {
    showPlayerControls = !showPlayerControls;
    notifyListeners();
  }

  List<String> exampleSongs = [
    'baddadan.mp3',
    'gods_country.mp3',
    'highest_in_the_room.mp3',
    'massive&crew.mp3',
    'leavemealone.mp3',
    'Tropical Beeper.mp3',
    'X trackTure.mp3',
    '8_bit_mentality.mp3',
    'range_test.mp3',
    'sample.mp3',
    'sample2.mp3',
  ];

  int currentSong = 0;
  Timer? timer;

  void updateCurrentSongPositon() {
    var pos = soLoudHandler.currentSongPositon.value;
    var length = soLoudHandler.soundLength.value;
    if (length != 0) {
      currentSongPositon.value = pos / length;
    } else {
      currentSongPositon.value = 0.0;
    }
    currentSongPositonFormatted.value = formattedCurrentPosition();
  }

  final ValueNotifier<double> currentSongPositon = ValueNotifier(0.0);
  final ValueNotifier<String> currentSongPositonFormatted = ValueNotifier('');

  HomeViewModel() {
    runBusyFuture(initSoLoud(), busyObject: HomeViewSection.player);
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      soLoudHandler.updateIsPlaying();
      updateCurrentSongPositon();
    });
  }

  String formattedTime({required int timeInSecond}) {
    int sec = timeInSecond % 60;
    int min = (timeInSecond / 60).floor();
    String minute = min.toString().length <= 1 ? "0$min" : "$min";
    String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
    return "$minute : $second";
  }

  String formattedCurrentPosition() {
    return formattedTime(timeInSecond: soLoudHandler.currentSongPositon.value.round());
  }

  bool isPlaying() => soLoudHandler.isPlaying.value;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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

  Future<void> playPause() async {
    if (soLoudHandler.currentSound == null) {
      playCurrentExampleSong();
      return;
    }
    togglePause();
  }

  Future<void> playCurrentExampleSong() async {
    await stop();
    final String path = 'assets/audio/${exampleSongs[currentSong]}';
    playAsset(path);
    notifyListeners();
  }

  Future<void> stop() async {
    if (soLoudHandler.currentSound != null) {
      if (soLoudHandler.currentSound!.handle.isNotEmpty) {
        SoLoud().stop(soLoudHandler.currentSound!.handle.first);
      }
    }
  }

  Future<void> togglePause() async {
    if (soLoudHandler.currentSound != null) {
      if (soLoudHandler.currentSound!.handle.isNotEmpty) {
        SoLoud().pauseSwitch(soLoudHandler.currentSound!.handle.first);
      }
    }
  }

  Future<void> nextSong() async {
    currentSong++;
    if (currentSong > exampleSongs.length - 1) {
      currentSong = 0;
    }
    notifyListeners();
    if (isPlaying()) {
      await playCurrentExampleSong();
    }
  }

  Future<void> prevSong() async {
    currentSong--;
    if (currentSong < 0) {
      currentSong = exampleSongs.length - 1;
    }
    notifyListeners();
    if (isPlaying()) {
      await playCurrentExampleSong();
    }
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
    if (soLoudHandler.currentSound != null) {
      if (await SoLoud().disposeSound(soLoudHandler.currentSound!) != PlayerErrors.noError) {
        return;
      }
    }

    /// load the file
    final loadRet = await SoLoud().loadFile(file);
    if (loadRet.error != PlayerErrors.noError) return;
    soLoudHandler.currentSound = loadRet.sound;

    /// play it
    final playRet = await SoLoud().play(soLoudHandler.currentSound!);
    if (loadRet.error != PlayerErrors.noError) return;
    soLoudHandler.currentSound = playRet.sound;

    /// get its length and notify it
    soLoudHandler.soundLength.value = SoLoud().getLength(soLoudHandler.currentSound!).length;

    /// Stop the timer and dispose the sound when the sound ends
    soLoudHandler.currentSound!.soundEvents.stream.listen(
      (event) {
        // TODO(me): put this elsewhere?
        event.sound.soundEvents.close();

        /// It's needed to call dispose when it end else it will
        /// not be cleared
        SoLoud().disposeSound(soLoudHandler.currentSound!);
        soLoudHandler.currentSound = null;
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
