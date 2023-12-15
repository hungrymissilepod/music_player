import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

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
