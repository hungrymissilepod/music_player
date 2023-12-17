import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app_template/app/app.bottomsheets.dart';
import 'package:flutter_app_template/app/app.dialogs.dart';
import 'package:flutter_app_template/app/app.locator.dart';
import 'package:flutter_app_template/app/app.router.dart';
import 'package:flutter_app_template/ftt/soloud_handler.dart';
import 'package:stacked_services/stacked_services.dart';

/*


TODO:


- Fix player controls and make them look better
- Make player controls fade out over time if user does not interact with them
- try chaning big particls so they move in the z axis like the background stars do.
- get average frequency of the song (average tempo) and use that as the baseline speed of the visualiser.
  this way slower tempo songs are not at full speed and vice versa.
- Add bloom shader to circle in star visualiser
- Fix bug where you can play the same sound twice accidentally. Disable play button if you just pressed it or something. Wait until the sound is played.
- Add playing position bar and allow seeking position
- Fix any issues and clean up code
- Improve StarVisualiser
- Enable playing audio when app in background
- Do not update paint of visualisers when app is in background to help free up performance? See if this makes a difference.

Work on other visualisers. Ideas:
- rainfall
- fireworks
- 3d objects (cubes, polygons,). They can fall down or float across screen, rotate and shrink and get bigger etc.
- lines drawing across screen
- audio bar visualiser
- circle visualiser with bars coming outwards
- waveform visualizer that goes around inside edge of screen



*/

Random random = Random();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(const LifecycleWatcher(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [
        StackedService.routeObserver,
      ],
    );
  }
}

/// TODO: not sure if we need this?
class LifecycleWatcher extends StatefulWidget {
  const LifecycleWatcher({super.key, required this.child});

  final Widget child;

  @override
  LifecycleWatcherState createState() => LifecycleWatcherState();
}

class LifecycleWatcherState extends State<LifecycleWatcher> with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('AppLifecycleState - ${state.toString()}');
    setState(() {
      _lastLifecycleState = state;
      if (state == AppLifecycleState.resumed) {
        print('AppLifecycleState - resumed');
        // SoLoudHandler().init();
      }
      if (state == AppLifecycleState.paused) {
        print('AppLifecycleState - paused');
        // SoLoudHandler().dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
