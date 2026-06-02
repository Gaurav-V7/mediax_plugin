import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediax/mediax.dart';
import 'package:mediax/models/data_source.dart';
import 'package:mediax/views/player_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  MediaX? controller;
  PlayerView? playerView;
  final GlobalKey<PlayerViewState> playerViewKey = GlobalKey();

  final dropDownItems = ["Network", "Local File", "Asset"];
  String? currentMode = "Asset";
  String sampleStreamUrl = "";

  TextEditingController networkUrlTextController = TextEditingController();

  Rx<double> aspectRatio = (16 / 9).obs;

  @override
  void initState() {
    super.initState();
    // Only set preferred orientations on mobile platforms (not macOS/Windows)
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight
      ]);
    }
    // Only initialize MediaX on supported platforms (Android/iOS)
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      controller = MediaX.init(
        enableMediaSession: true,
        dataSource: DataSource.asset('assets/demo.mp4'),
      );
      playerView = PlayerView(
        key: playerViewKey,
        controller: controller!,
        awakeScreenWhilePlaying: true,
      );

      controller!.isInitialized.listen((isInitialized) {
        debugPrint('initializationChanged: $isInitialized');
        if (isInitialized) {
          // debugPrint('duration: ${controller.duration.value}');
        }
      });

      controller!.duration.listen((duration) {
        debugPrint('duration: ${controller!.duration.value}');
      });

      controller!.videoSize.listen((videoSize) {
        debugPrint('videoSize: ${videoSize.width} ${videoSize.height}');
      });

      controller!.aspectRatio.listen((ar) {
        debugPrint('aspectRatio: $aspectRatio');
        if (ar > 1.333) {
          aspectRatio.value = ar;
        }
      });

      controller!.playbackState.listen((state) {
        debugPrint('playbackState: ${state.name}');
      });

      controller!.playbackError.listen((error) {
        if (error != null) {
          debugPrint(error.toString());
          showToast(error.message);
        }
      });
    }

    networkUrlTextController.text = sampleStreamUrl;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show unsupported message on macOS
    if (controller == null || playerView == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MediaX example app'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'MediaX plugin is not supported on macOS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Please run this app on Android or iOS to use the video player.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Obx(
        () => SingleChildScrollView(
          child: Column(
            children: [
              Visibility(
                visible: !controller!.isFullScreen.value,
                child: AppBar(
                  title: const Text('MediaX example app'),
                ),
              ),
              Visibility(
                visible: !controller!.isFullScreen.value,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    DropdownButton<String>(
                        value: currentMode,
                        items: dropDownItems.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            currentMode = newValue;
                          });
                          debugPrint("currentMode: $currentMode");
                          if (currentMode == "Asset") {
                            controller!.setMediaItem(
                                dataSource:
                                    DataSource.asset("assets/demo.mp4"));
                            controller!.seekTo(0);
                          }
                        }),
                    Visibility(
                      visible: currentMode == "Network",
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          children: [
                            Flexible(
                              child: TextField(
                                onSubmitted: (value) => setMediaItem(value),
                                controller: networkUrlTextController,
                              ),
                            ),
                            IconButton(
                                onPressed: () => setMediaItem(
                                    networkUrlTextController.text
                                        .toString()
                                        .trim()),
                                icon: const Icon(Icons.play_arrow_rounded))
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: currentMode == "Local File",
                      child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final picker = await ImagePicker()
                                  .pickVideo(source: ImageSource.gallery);

                              if (picker != null) {
                                controller!.setMediaItem(
                                    dataSource: DataSource.file(picker.path),
                                    autoplay: false);
                              }
                            } catch (e) {
                              debugPrint("Error picking file: $e");
                            }
                          },
                          child: const Text("Pick file")),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
              frameLayout(child: playerView!),
            ],
          ),
        ),
      ),
    );
  }

  void setMediaItem(String value) {
    controller?.setMediaItem(dataSource: DataSource.network(value));
  }

  Widget frameLayout({required Widget child}) {
    if (controller == null) {
      return const SizedBox.shrink();
    }
    final mediaQuery = MediaQuery.of(context);
    final screenAspectRatio = (mediaQuery.size.width / mediaQuery.size.height);
    return SizedBox(
      width: double.infinity,
      height: controller!.isFullScreen.value == false ? 300 : null,
      child: AspectRatio(
        aspectRatio: controller!.isFullScreen.value
            ? screenAspectRatio
            : aspectRatio.value,
        child: child,
      ),
    );
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Orientation getOrientation() {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.orientation;
  }
}
