import 'package:flutter/material.dart';
import 'package:flutter_app_template/app/app.bottomsheets.dart';
import 'package:flutter_app_template/app/app.dialogs.dart';
import 'package:flutter_app_template/app/app.locator.dart';
import 'package:flutter_app_template/app/app.router.dart';
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

- Work out why some songs are failing to load. Either something wrong with my code or the files are corrupted??
- Add more songs and make a way to cycle through them and stop playing sound (basic player)
- Get average frequencies for bass, mid, high, etc using the method that I created in flutter_soloud repo
- Try playing a song from a url
- Now we can start creating custom painters


*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MainApp());
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
