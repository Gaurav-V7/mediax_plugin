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
  late MediaX controller;
  late PlayerView playerView;
  final GlobalKey<PlayerViewState> playerViewKey = GlobalKey();

  final dropDownItems = ["Network", "Local File", "Asset"];
  String? currentMode = "Asset";

  TextEditingController networkUrlTextController = TextEditingController();

  Rx<double> aspectRatio = (16 / 9).obs;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);

    controller = MediaX.init(
      enableMediaSession: true,
      dataSource: DataSource.network(
          "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"),
    );
    playerView = PlayerView(
      key: playerViewKey,
      controller: controller,
      awakeScreenWhilePlaying: true,
    );

    controller.isInitialized.listen((isInitialized) {
      debugPrint('initializationChanged: $isInitialized');
      if (isInitialized) {}
    });

    controller.videoSize.listen((videoSize) {
      debugPrint('videoSize: ${videoSize.width} ${videoSize.height}');
    });

    controller.aspectRatio.listen((ar) {
      debugPrint('aspectRatio: $aspectRatio');
      if (ar > 1.333) {
        aspectRatio.value = ar;
      }
    });

    controller.playbackState.listen((state) {
      debugPrint('playbackState: ${state.name}');
    });

    controller.playbackError.listen((error) {
      if (error != null) {
        debugPrint(error.toString());
        showToast(error.message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: mainView(),
        ),
      ),
    );
  }

  Widget mainView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Visibility(
            visible: !controller.isFullScreen.value,
            child: AppBar(
              title: const Text('MediaX example app'),
            ),
          ),
          Visibility(
            visible: !controller.isFullScreen.value,
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
                      if (currentMode == "Asset") {
                        controller.setMediaItem(
                            dataSource: DataSource.asset("assets/demo.mp4"));
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
                        final picker = await ImagePicker()
                            .pickVideo(source: ImageSource.gallery);

                        if (picker != null) {
                          controller.setMediaItem(
                              dataSource: DataSource.file(picker.path),
                              autoplay: false);
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
          frameLayout(child: playerView),
        ],
      ),
    );
  }

  void setMediaItem(String value) {
    controller.setMediaItem(dataSource: DataSource.network(value));
  }

  Widget frameLayout({required Widget child}) {
    final mediaQuery = MediaQuery.of(context);
    final screenAspectRatio = (mediaQuery.size.width / mediaQuery.size.height);
    return SizedBox(
      width: double.infinity,
      height: controller.isFullScreen.value == false ? 300 : null,
      child: AspectRatio(
        aspectRatio: controller.isFullScreen.value
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
