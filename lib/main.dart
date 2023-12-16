import 'package:flutter/material.dart';
import 'package:flutter_app_template/app/app.bottomsheets.dart';
import 'package:flutter_app_template/app/app.dialogs.dart';
import 'package:flutter_app_template/app/app.locator.dart';
import 'package:flutter_app_template/app/app.router.dart';
import 'package:flutter_app_template/ftt/soloud_handler.dart';
import 'package:stacked_services/stacked_services.dart';

/*
Note: In order to publish this app please remember to change the application ID

Android:
Change this value 'com.example.flutter_app_template'

iOS:
Change this value 'com.example.flutterAppTemplate'

Linux:
Change this value 'com.example.flutter_app_template'

MacOS:
Change this value 'com.example.flutterAppTemplate' and 'com.example.flutterAppTemplate.RunnerTests'

Windows:
Change these values in Runner.rc:
'com.example'
'flutter_app_template'
*/

/*


TODO:

- Fix bug where you can play the same sound twice accidentally. Disable play button if you just pressed it or something. Wait until the sound is played.
- Control visualiser based on average tempo/frequency of music
- Add playing position bar and allow seeking position
- Add simple boolean that will check if player is inited and if playerData is not nullptr and if playerData is not null to check if we are playing music.
- Change StarVisualiser to full screen behind the controls
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();
  SoLoudHandler soLoudHandler = SoLoudHandler();
  soLoudHandler.init();
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
        SoLoudHandler().init();
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
