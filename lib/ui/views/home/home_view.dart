import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_app_template/ftt/texture_type.dart';
import 'package:flutter_app_template/ftt/visualizer.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_app_template/ui/common/ui_helpers.dart';
import 'package:statsfl/statsfl.dart';

import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          viewModel.soLoudHandler.isPlayerInited
              ? CustomPaint(
                  painter: StarsPainter(
                    audioData: viewModel.soLoudHandler.playerData.value,
                  ),
                  child: Container(),
                )
              : Container(),
          const Opacity(opacity: 0.5, child: PlayerControls()),
        ],
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      HomeViewModel();

  @override
  void onDispose(HomeViewModel viewModel) {
    viewModel.dispose();
  }
}

class PlayerControls extends ViewModelWidget<HomeViewModel> {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return SafeArea(
      child: StatsFl(
        isEnabled: viewModel.fpsMonitorEnabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                verticalSpaceLarge,
                Column(
                  children: [
                    Text(viewModel.exampleSongs[viewModel.currentSong]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text(
                            '< Prev',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            viewModel.prevSong();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Play',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            viewModel.playCurrentExampleSong();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Pause',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            viewModel.pause();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Stop',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            viewModel.stop();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Next >',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            viewModel.nextSong();
                          },
                        ),
                      ],
                    ),
                    TextButton(
                      child: const Text(
                        'Play from URL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        viewModel.playFromUrl();
                      },
                    ),
                    verticalSpaceLarge,

                    /// fft smoothing slider
                    ValueListenableBuilder<double>(
                      valueListenable: viewModel.soLoudHandler.fftSmoothing,
                      builder: (_, smoothing, __) {
                        return Row(
                          children: [
                            Text('FFT smooth: ${smoothing.toStringAsFixed(2)}'),
                            Expanded(
                              child: Slider.adaptive(
                                value: smoothing,
                                onChanged: (smooth) {
                                  SoLoud().setFftSmoothing(smooth);
                                  viewModel.soLoudHandler.fftSmoothing.value = smooth;
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    /// fft range slider values to put into the texture
                    ValueListenableBuilder<RangeValues>(
                      valueListenable: viewModel.soLoudHandler.fftImageRange,
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
                                  viewModel.soLoudHandler.fftImageRange.value = values;
                                  viewModel.soLoudHandler.visualizerController
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
                    verticalSpaceSmall,
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
