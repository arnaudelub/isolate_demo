import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const int bigNumber = 1500000000;
void main() => runApp(AnimatedContainerApp());

class AnimatedContainerApp extends StatefulWidget {
  @override
  _AnimatedContainerAppState createState() => _AnimatedContainerAppState();
}

class _AnimatedContainerAppState extends State<AnimatedContainerApp> {
  // Define the various properties with default values. Update these properties
  // when the user taps a FloatingActionButton.
  double _width = 50;
  double _height = 50;
  Color _color = Colors.green;
  BorderRadiusGeometry _borderRadius = BorderRadius.circular(8);
  Timer? timer;
  GlobalKey _scaffoldKey = GlobalKey();
  Isolate? isolate;
  StreamSubscription? _isolateStreamSubscription;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      setState(() {
        final random = Random();

        // Generate a random width and height.
        _width = random.nextInt(300).toDouble();
        _height = random.nextInt(300).toDouble();

        // Generate a random color.
        _color = Color.fromRGBO(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
          1,
        );

        // Generate a random border radius.
        _borderRadius = BorderRadius.circular(random.nextInt(100).toDouble());
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _isolateStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startIsolate() async {
    final ReceivePort receivePort = ReceivePort();
    isolate = await Isolate.spawn(_task, receivePort.sendPort);
    _isolateStreamSubscription = receivePort.listen((data) {
      isolate!.kill(priority: Isolate.immediate);
      ScaffoldMessenger.of(_scaffoldKey.currentContext!)
          .showSnackBar(SnackBar(content: Text(data)));
    });
  }

  /// The task called by compute and Isolate.spawn() as to be static if inside a class
  /// or it has to be a top-level function
  Future<void> _calculateOrCompute(
      {bool isCompute = false, bool isIsolate = false}) async {
    int result = 0;
    if (isCompute) {
      result = await compute(bigTask, bigNumber);
      _showSnackBar("$result");
    } else if (isIsolate) {
      _startIsolate();
    } else {
      result = bigTask(bigNumber);
      _showSnackBar("$result");
    }
  }

  void _showSnackBar(String result) {
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(result)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Isolate Demo'),
        ),
        body: Center(
          child: AnimatedContainer(
            // Use the properties stored in the State class.
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: _borderRadius,
            ),
            // Define how long the animation should take.
            duration: Duration(seconds: 1),
            // Provide an optional curve to make the animation feel smoother.
            curve: Curves.fastOutSlowIn,
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              backgroundColor: Colors.lightBlue,
              child:
                  Tooltip(message: 'Compute', child: Icon(Icons.play_for_work)),
              // When the user taps the button
              onPressed: () => _calculateOrCompute(isCompute: true),
            ),
            FloatingActionButton(
              backgroundColor: Colors.lightBlueAccent,
              child: Tooltip(
                  message: 'Isolate', child: Icon(Icons.play_circle_fill)),
              // When the user taps the button
              onPressed: () => _calculateOrCompute(isIsolate: true),
            ),
            FloatingActionButton(
              backgroundColor: Colors.redAccent,
              child:
                  Tooltip(message: 'Calculate', child: Icon(Icons.play_arrow)),
              // When the user taps the button
              onPressed: () => _calculateOrCompute(),
            ),
          ],
        ),
      ),
    );
  }
}

void _task(SendPort sendPort) {
  final result = bigTask(bigNumber);
  sendPort.send("Got the result: $result");
}

int bigTask(int n) {
  assert(n > 1000000000);
  int result = 0;
  for (int i = 0; i < n; i++) {
    result++;
  }
  return result;
}
