import 'package:flutter/material.dart';
import 'package:flutter_app_template/app/app.bottomsheets.dart';
import 'package:flutter_app_template/app/app.dialogs.dart';
import 'package:flutter_app_template/app/app.locator.dart';
import 'package:flutter_app_template/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:statsfl/statsfl.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(StatsFl(align: Alignment.bottomLeft, child: const MainApp()));
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

// import 'package:flutter/material.dart';
// import 'package:flutter_fft/flutter_fft.dart';

// void main() => runApp(Application());

// class Application extends StatefulWidget {
//   @override
//   ApplicationState createState() => ApplicationState();
// }

// class ApplicationState extends State<Application> {
//   // double? frequency;
//   // String? note;
//   // int? octave;
//   // bool? isRecording;

//   // FlutterFft flutterFft = new FlutterFft();

//   // _initialize() async {
//   //   print("Starting recorder...");
//   //   // print("Before");
//   //   // bool hasPermission = await flutterFft.checkPermission();
//   //   // print("After: " + hasPermission.toString());

//   //   // Keep asking for mic permission until accepted
//   //   while (!(await flutterFft.checkPermission())) {
//   //     flutterFft.requestPermission();
//   //     // IF DENY QUIT PROGRAM
//   //   }

//   //   // await flutterFft.checkPermissions();
//   //   await flutterFft.startRecorder();
//   //   print("Recorder started...");
//   //   setState(() => isRecording = flutterFft.getIsRecording);

//   //   flutterFft.onRecorderStateChanged.listen(
//   //       (data) => {
//   //             print("Changed state, received: $data"),
//   //             setState(
//   //               () => {
//   //                 frequency = data[1] as double,
//   //                 note = data[2] as String,
//   //                 octave = data[5] as int,
//   //               },
//   //             ),
//   //             flutterFft.setNote = note!,
//   //             flutterFft.setFrequency = frequency!,
//   //             flutterFft.setOctave = octave!,
//   //             print("Octave: ${octave!.toString()}"),
//   //             print("Note: ${note!.toString()}"),
//   //             print("Frequency: ${frequency!.toString()}")
//   //           },
//   //       onError: (err) {
//   //         print("Error: $err");
//   //       },
//   //       onDone: () => {print("Isdone")});
//   // }

//   @override
//   void initState() {
//     // isRecording = flutterFft.getIsRecording;
//     // frequency = flutterFft.getFrequency;
//     // note = flutterFft.getNote;
//     // octave = flutterFft.getOctave;
//     super.initState();
//     // _initialize();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: "Simple flutter fft example",
//         theme: ThemeData.dark(),
//         color: Colors.blue,
//         home: Scaffold(
//           backgroundColor: Colors.purple,
//           body: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 isRecording!
//                     ? Text("Current note: ${note!},${octave!.toString()}", style: TextStyle(fontSize: 30))
//                     : Text("Not Recording", style: TextStyle(fontSize: 35)),
//                 isRecording!
//                     ? Text("Current frequency: ${frequency!.toStringAsFixed(2)}", style: TextStyle(fontSize: 30))
//                     : Text("Not Recording", style: TextStyle(fontSize: 35))
//               ],
//             ),
//           ),
//         ));
//   }
// }
