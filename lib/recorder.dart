// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors

import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class Recorder extends StatefulWidget {
  const Recorder({Key? key}) : super(key: key);

  @override
  State<Recorder> createState() => _RecorderState();
}

class _RecorderState extends State<Recorder> {
  final recorder = FlutterSoundRecorder();
  late final RecorderController recorderController;
  late final path;
  late final audioFile;
  Icon recIcon = Icon(Icons.mic);
  Icon playIcon = Icon(Icons.play_arrow);
  var clr = Colors.grey;
  var playClr = Colors.lightBlue;
  var playBtn = Colors.grey;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  Future initRecorder() async {
    await Permission.microphone.status;
    var status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Mic permission not granted')));
    }
    await recorder.openRecorder();
    recorder.setSubscriptionDuration(
      const Duration(seconds: 1),
    );
  }

  Future record() async {
    await recorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    path = await recorder.stopRecorder();
    audioFile = File(path!);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Audio stored in $path')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
              child: Container(
                padding: const EdgeInsets.all(5),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                    color: clr,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.black)),
                child: recIcon,
              ),
              onTap: () async {
                // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test 1'), backgroundColor: Colors.red, duration: Duration(milliseconds: 200),));
                if (recorder.isRecording) {
                  await stop();
                  setState(() {
                    recIcon = Icon(
                      Icons.mic,
                      size: 50,
                      color: Colors.white,
                    );
                    clr = Colors.green;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Recording stopped'),
                    backgroundColor: Colors.red,
                    duration: Duration(milliseconds: 200),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Recording started'),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 200),
                  ));
                  await record();
                  setState(() {
                    recIcon = Icon(Icons.stop, size: 50);
                    clr = Colors.red;
                  });
                }
              }),
          const SizedBox(
            height: 100,
          ),
          StreamBuilder<RecordingDisposition>(
            stream: recorder.onProgress,
            builder: (context, snapshot) {
              final duration =
                  snapshot.hasData ? snapshot.data!.duration : Duration.zero;
              String twoDigits(int n) => n.toString();
              final twoDigitMinutes =
                  twoDigits(duration.inSeconds.remainder(60));

              return Text(
                '$twoDigitMinutes sec',
                style:
                    const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              );
            },
          ),
        ],
      )),
    );
  }
}
