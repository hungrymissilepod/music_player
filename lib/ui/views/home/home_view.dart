import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/ui/views/home/player_controls.dart';
import 'package:flutter_app_template/ui/visualisers/star_visualiser.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ) {
    final ui.Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          viewModel.soLoudHandler.isPlayerInited
              ? StarField(
                  starSpeed: 1,
                  starCount: 100,
                  audioData: viewModel.soLoudHandler.playerData.value,
                )
              // ? CustomPaint(
              //     painter: StarsVisualiser(audioData: viewModel.soLoudHandler.playerData.value, canvasSize: size),
              //     child: Container(),
              //   )
              : Container(),
          Opacity(opacity: viewModel.showPlayerControls ? 0.6 : 0, child: PlayerControls()),
          Visibility(
            visible: kDebugMode,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: viewModel.togglePlayerControls,
                  icon: Icon(
                    Icons.close,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
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
