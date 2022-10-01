// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors, use_build_context_synchronously

import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
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
    recorderController = RecorderController();
  }

  @override
  void dispose() {
    recorderController.dispose();
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

  Future<File> saveFilePermanantly(File file) async {
    final appStorage = await getApplicationDocumentsDirectory();
    final newFile = File('${appStorage.path}');

    return File(file.path).copy(newFile.path);
  }

  Future record() async {
    await recorder.startRecorder(toFile: 'recordApp');
    await recorderController.record();
  }

  Future stop() async {
    await recorderController.stop();
    final path = await recorder.stopRecorder();
    final audioFile = File(path!);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Audio stored in $audioFile')));
  }

  // Future stop() async {
  //   await recorderController.stop();
  //   path = await recorder.stopRecorder();
  //   audioFile = File(path!);
  //   final newFile = await saveFilePermanantly(audioFile);
  //   ScaffoldMessenger.of(context)
  //       .showSnackBar(SnackBar(content: Text('Audio stored in $newFile')));
  //   ScaffoldMessenger.of(context)
  //       .showSnackBar(SnackBar(content: Text('Audio stored in $audioFile')));
  // }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //Record pause button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              GestureDetector(
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.black)),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('File not found'),
                    duration: Duration(seconds: 1),
                  ));
                },
              )
            ],
          ),
          const SizedBox(
            height: 100,
          ),

          //Timer
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
          const SizedBox(
            height: 50,
          ),

          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
            width: w,
            child: AudioWaveforms(
              waveStyle: WaveStyle(
                waveColor: Colors.red,
                showDurationLabel: true,
                spacing: 10,
                showBottom: true,
                extendWaveform: true,
                showMiddleLine: false,
              ),
              size: Size(MediaQuery.of(context).size.width, 200.0),
              recorderController: recorderController,
            ),
          )
        ],
      )),
    );
  }
}
