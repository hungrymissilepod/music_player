import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/ftt/texture_type.dart';
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_app_template/ui/common/ui_helpers.dart';
import 'package:statsfl/statsfl.dart';

import 'home_viewmodel.dart';

class PlayerControls extends ViewModelWidget<HomeViewModel> {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    // color: Colors.grey[100]?.withOpacity(0.2),
    // return Container(
    //   height: 100,
    //   width: 100,
    //   color: Colors.red,
    // );
    return SafeArea(
      child: StatsFl(
        isEnabled: kDebugMode && viewModel.fpsMonitorEnabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Text(viewModel.exampleSongs[viewModel.currentSong]),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     TextButton(
              //       child: const Text(
              //         '< Prev',
              //         style: TextStyle(
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       onPressed: () {
              //         viewModel.prevSong();
              //       },
              //     ),
              //     TextButton(
              //       child: const Text(
              //         'Play',
              //         style: TextStyle(
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       onPressed: () {
              //         viewModel.playCurrentExampleSong();
              //       },
              //     ),
              //     TextButton(
              //       child: const Text(
              //         'Pause',
              //         style: TextStyle(
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       onPressed: () {
              //         viewModel.togglePause();
              //       },
              //     ),
              //     TextButton(
              //       child: const Text(
              //         'Stop',
              //         style: TextStyle(
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       onPressed: () {
              //         viewModel.stop();
              //       },
              //     ),
              //     TextButton(
              //       child: const Text(
              //         'Next >',
              //         style: TextStyle(
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       onPressed: () {
              //         viewModel.nextSong();
              //       },
              //     ),
              //   ],
              // ),
              // TextButton(
              //   child: const Text(
              //     'Play from URL',
              //     style: TextStyle(
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              //   onPressed: () {
              //     viewModel.playFromUrl();
              //   },
              // ),

              /// fft smoothing slider
              // ValueListenableBuilder<double>(
              //   valueListenable: viewModel.soLoudHandler.fftSmoothing,
              //   builder: (_, smoothing, __) {
              //     return Row(
              //       children: [
              //         Text('FFT smooth: ${smoothing.toStringAsFixed(2)}'),
              //         Expanded(
              //           child: Slider.adaptive(
              //             value: smoothing,
              //             onChanged: (smooth) {
              //               SoLoud().setFftSmoothing(smooth);
              //               viewModel.soLoudHandler.fftSmoothing.value = smooth;
              //             },
              //           ),
              //         ),
              //       ],
              //     );
              //   },
              // ),

              // /// fft range slider values to put into the texture
              // ValueListenableBuilder<RangeValues>(
              //   valueListenable: viewModel.soLoudHandler.fftImageRange,
              //   builder: (_, fftRange, __) {
              //     return Row(
              //       children: [
              //         Text('FFT range ${fftRange.start.toInt()}'),
              //         Expanded(
              //           child: RangeSlider(
              //             max: 255,
              //             divisions: 256,
              //             values: fftRange,
              //             onChanged: (values) {
              //               viewModel.soLoudHandler.fftImageRange.value = values;
              //               viewModel.soLoudHandler.visualizerController
              //                 ..changeMinFreq(values.start.toInt())
              //                 ..changeMaxFreq(values.end.toInt());
              //             },
              //           ),
              //         ),
              //         Text('${fftRange.end.toInt()}'),
              //       ],
              //     );
              //   },
              // ),
              // verticalSpaceSmall,

              ValueListenableBuilder<TextureType>(
                valueListenable: viewModel.soLoudHandler.textureType,
                builder: (_, type, __) {
                  return Visualizer(
                    key: UniqueKey(),
                    controller: viewModel.soLoudHandler.visualizerController,
                    textureType: type,
                    setupBitmapSize: viewModel.soLoudHandler.setupBitmapSize,
                    viewModel: viewModel,
                  );
                },
              ),
              SizedBox(
                height: 200,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    viewModel.toggleFpsMonitor();
                  },
                  child: Text(
                    'show debug controls',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  viewModel.exampleSongs[viewModel.currentSong],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 30),
              Column(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: viewModel.currentSongPositon,
                    builder: (context, value, child) {
                      return SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          trackShape: SliderCustomTrackShape(),
                        ),
                        child: Container(
                          height: 20,
                          child: Slider(
                            value: value,
                            onChanged: (value) {},
                            thumbColor: Colors.white,
                            activeColor: Colors.white.withOpacity(0.8),
                            inactiveColor: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: viewModel.currentSongPositonFormatted,
                        builder: (context, value, child) {
                          return Text(
                            '$value',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder(
                        valueListenable: viewModel.soLoudHandler.soundLength,
                        builder: (context, value, child) {
                          return Text(
                            '${viewModel.formattedTime(timeInSecond: viewModel.soLoudHandler.soundLength.value.round())}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: IconButton(
                      onPressed: () {
                        viewModel.prevSong();
                      },
                      iconSize: 50,
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: viewModel.soLoudHandler.isPlaying,
                    builder: (context, value, child) {
                      return Container(
                        height: 70,
                        width: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: IconButton(
                          onPressed: () {
                            viewModel.playPause();
                          },
                          iconSize: 50,
                          icon: Icon(
                            value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    height: 70,
                    width: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: IconButton(
                      onPressed: () {
                        viewModel.nextSong();
                      },
                      iconSize: 50,
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class SliderCustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double? trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
