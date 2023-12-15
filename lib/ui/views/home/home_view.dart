import 'package:flutter/material.dart';
import 'package:flutter_app_template/ftt/texture_type.dart';
import 'package:flutter_app_template/ftt/visualizer.dart';
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
      body: SafeArea(
        child: StatsFl(
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
                      verticalSpaceLarge,

                      /// fft range slider values to put into the texture
                      ValueListenableBuilder<RangeValues>(
                        valueListenable: viewModel.fftImageRange,
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
                                    viewModel.fftImageRange.value = values;
                                    viewModel.visualizerController
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
                        valueListenable: viewModel.textureType,
                        builder: (_, type, __) {
                          return Visualizer(
                            key: UniqueKey(),
                            controller: viewModel.visualizerController,
                            textureType: type,
                          );
                        },
                      )
                    ],
                  ),
                ],
              ),
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
      HomeViewModel();
}
