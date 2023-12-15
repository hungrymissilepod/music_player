import 'dart:ffi';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/app/app.bottomsheets.dart';
import 'package:flutter_app_template/app/app.dialogs.dart';
import 'package:flutter_app_template/app/app.locator.dart';
import 'package:flutter_app_template/ui/common/app_strings.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
// import 'package:fftea/fftea.dart';
// import 'package:wav/wav.dart';

class HomeViewModel extends BaseViewModel {
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();

  late Dio dio;

  HomeViewModel(int startingIndex) {
    dio = Dio();
    _counter = startingIndex;
    _initSoLoud();
  }

  Future<void> _initSoLoud() async {
    final b = await SoLoud().startIsolate();
    if (b == PlayerErrors.noError) {
      debugPrint('isolate started');
      SoLoud().setVisualizationEnabled(true);
    }
  }

  Future<void> stopSoLoud() async {
    SoLoud().stopIsolate();
  }

  /// plays an assets file
  Future<void> playAsset(String assetsFile) async {
    final audioFile = await getAssetFile(assetsFile);
    return _play(audioFile.path);
  }

  SoundProps? currentSound;
  final ValueNotifier<double> soundLength = ValueNotifier(0);

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
  Future<File> getAssetFile(String assetsFile) async {
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

  String get counterLabel => 'Counter is: $_counter';

  int _counter = 0;

  void incrementCounter() {
    _counter++;
    rebuildUi();
  }

  void showDialog() {
    _dialogService.showCustomDialog(
      variant: DialogType.infoAlert,
      title: 'Stacked Rocks!',
      description: 'Give stacked $_counter stars on Github',
    );
  }

  void showBottomSheet() {
    _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.notice,
      title: ksHomeBottomSheetTitle,
      description: ksHomeBottomSheetDescription,
    );
  }

  streamData() async {
    // var url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';
    // final rs = await dio.get(
    //   url,
    //   options: Options(responseType: ResponseType.bytes), // Set the response type to `stream`.
    // );
    // print(rs.data);

    // AudioPlayer audioPlayer = AudioPlayer();

    // await audioPlayer.setUrl(url);

    // audioPlayer.play();

    // var response = dio.request(url, options: Options(responseType: ResponseType.bytes));
    // response.asStream().listen((streamedResponse) async {
    //   print("Received streamedResponse.statusCode:${streamedResponse.statusCode}");
    //   print("data:----------------------> ${streamedResponse.data}");
    //   // await audioPlayer.setAudioSource(MyCustomSource(streamedResponse.data));
    //   // audioPlayer.play();
    // });
  }

  Future<List<double>> _getAudioContent() async {
    streamData();
    // const String path = 'assets/test.mp3';

    // var url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';

    // AudioPlayer audioPlayer = AudioPlayer();

    // await audioPlayer.setUrl(url);

    // await audioPlayer.setAudioSource(MyCustomSource());
    // audioPlayer.play();

    // AssetsAudioPlayer player = AssetsAudioPlayer.newPlayer()
    //   ..open(
    //     Audio(path),
    //     autoStart: true,
    //     showNotification: true,
    //   );

    // player.current

    // final wav = await Wav.readFile(path);
    // final audio = normalizeRmsVolume(wav.toMono(), 0.3);
    // const chunkSize = 2048;
    // const buckets = 120;
    // final stft = STFT(chunkSize, Window.hanning(chunkSize));
    // Uint64List? logItr;
    // stft.run(
    //   audio,
    //   (Float64x2List chunk) {
    //     final amp = chunk.discardConjugates().magnitudes();
    //     logItr ??= linSpace(amp.length, buckets);
    //     int i0 = 0;
    //     for (final i1 in logItr!) {
    //       double power = 0;
    //       if (i1 != i0) {
    //         for (int i = i0; i < i1; ++i) {
    //           power += amp[i];
    //         }
    //         power /= i1 - i0;
    //       }
    //       stdout.write(gradient(power));
    //       i0 = i1;
    //     }
    //     stdout.write('\n');
    //   },
    //   chunkSize ~/ 2,
    // );

    // Uint8List data = File(path).readAsBytesSync();
    // List<double> list = data.buffer.asFloat64List();
    // return list;
    return [];
  }

  // Future<void> _run() async {
  //   // List<double> myData = await _getAudioContent();

  //   // final fft = FFT(myData.length);
  //   // final freq = fft.realFft(myData);
  //   // print(freq);
  // }

  // Float64List normalizeRmsVolume(List<double> a, double target) {
  //   final b = Float64List.fromList(a);
  //   double squareSum = 0;
  //   for (final x in b) {
  //     squareSum += x * x;
  //   }
  //   double factor = target * math.sqrt(b.length / squareSum);
  //   for (int i = 0; i < b.length; ++i) {
  //     b[i] *= factor;
  //   }
  //   return b;
  // }

  // Uint64List linSpace(int end, int steps) {
  //   final a = Uint64List(steps);
  //   for (int i = 1; i < steps; ++i) {
  //     a[i - 1] = (end * i) ~/ steps;
  //   }
  //   a[steps - 1] = end;
  //   return a;
  // }

  // String gradient(double power) {
  //   const scale = 2;
  //   const levels = [' ', '░', '▒', '▓', '█'];
  //   int index = math.log((power * levels.length) * scale).floor();
  //   if (index < 0) index = 0;
  //   if (index >= levels.length) index = levels.length - 1;
  //   return levels[index];
  // }
}

// // Feed your own stream of bytes into the player
// class MyCustomSource extends StreamAudioSource {
//   final List<int> bytes;
//   MyCustomSource(this.bytes);

//   @override
//   Future<StreamAudioResponse> request([int? start, int? end]) async {
//     start ??= 0;
//     end ??= bytes.length;
//     return StreamAudioResponse(
//       sourceLength: bytes.length,
//       contentLength: end - start,
//       offset: start,
//       stream: Stream.value(bytes.sublist(start, end)),
//       contentType: 'audio/mp3',
//     );
//   }
// }
