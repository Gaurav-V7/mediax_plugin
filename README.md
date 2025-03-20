# Media Player plugin for Flutter

A flutter plugin for Android and iOS for media playback either Audio or Video.

**Android**: The plugin leverages ExoPlayer, a powerful and flexible media player for Android, to handle media playback.

**iOS**: The plugin uses AVPlayer, Apple's native media player, to deliver smooth and efficient media playback on iOS devices.

## Internet Permission Access

To enable network file/stream playback, you need to follow the requirements below:

### Android

Add INTERNET permission in the AndroidManifest.xml file of your application’s android directory.

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

To enable the http playback instead of https add the following attribute to the <application> tag of your manifest

```xml
<application
    ...
    android:usesCleartextTraffic="true">
    <Your-Activity />
</application>
```

> Or you can refer to [this documentation](https://developer.android.com/privacy-and-security/security-config) if you want more control for above http streams

### iOS

If you need to access videos using `http` (rather than `https`) URLs, you will need to add
the appropriate `NSAppTransportSecurity` permissions to your app's _Info.plist_ file, located
in `<project root>/ios/Runner/Info.plist`. See
[Apple's documentation](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity)
to determine the right combination of entries for your use case and supported iOS versions.

## Playback Types in MediaX

MediaX supports two types of playback:

### **1. Audio Playback**

Requires only the player controller to manage playback.

### **2. Video Playback**

Requires PlayerView to be connected with the player controller to render the video surface of the media item.

## Player Controller (Player Manager)

Controller will help you to get the data from the player instance of the player and media item's data to your view. You can get and show that data into your UI.

### Initializing the controller

```dart
late MediaX controller;

@Override
void initState() {
  super.initState();

  //Initializing the controller
  controller = MediaX.init(
    dataSource: DataSource.asset('assets/file.mp4'), // Not required
    autoplay: false // Not required
  );
}
```

When calling any methods of controller listed below check the initialization status of the controller using

```dart
controller.isInitialized.listen((isInitialized) {
    if (isInitialized) {
        // Call controller methods here want to execute after init
    }
});
```

### Setting the mediaItem (DataSource needed)

```dart
controller.setMediaItem(
  dataSource: DataSource.file('localFilePath.mp4'),
  autoplay: true // Not required
);
```

## Playback Controller Methods

### Play/Pause the current media

```dart
// To play the current media
controller.play();

// To pause the current media
controller.pause();

// To toggle play/pause
controller.playPause();
```

### Stop playback

```dart
controller.stop();
```

### Seek forward/backward the current media

```dart
// To seek forward
controller.seekForward();

// To seek backward/rewind
controller.seekBackward();
```

### Set forward/backward seconds

```dart
// To set forward seconds
controller.forwardSeekSeconds = 10; // value in seconds

// To set backward/rewind seconds
controller.backwardSeekSeconds = 10; // value in seconds
```

### Jump to any part of video (milliseconds)

```dart
controller.seekTo(15000); // 15000 millis = 15 secs
```

### Mute/Unmute Player

```dart
controller.setMuted(true); // To mute the player
controller.setMuted(false); // To unmute the player

controller.toggleMute(); // To toggle mute/unmute
```

### Observe the playback error

```dart
controller.playbackError.listen((error) {
  if (error != null) {
    print(error.toString());
  }
});
```

### Observe the playback state

```dart
controller.playbackState.listen((state) {
  print('playbackState: ${state.name}');
});
```

### Enable MediaSession

Control playback from Earphones/Headphones buttons like Play/Pause by default it is set to false

```dart
controller = MediaX.init(
   ...
   enableMediaSession: true
);
```

### Get Size of the Video

```dart
controller.videoSize.listen((videoSize) {
   print('videoSize: ${videoSize.width} ${videoSize.height}');
}); // Width and Height
```

### Get Aspect Ratio of the Video

```dart
controller.aspectRatio.listen((ar) {
    print('aspectRatio: $aspectRatio');
    aspectRatio.value = ar;
});
```

### Set Playback Speed

```dart
controller.setPlaybackSpeed(2.0); // Default is 1.0
```

## Player View (Video Surface)

### Access PlayerViewState methods

Initialize the PlayerViewState using GlobalKey and set the key to the playerView before accessing any PlayerViewState methods.

```dart
final GlobalKey<PlayerViewState> playerViewKey = GlobalKey<PlayerViewState>();
playerView = PlayerView(key: playerViewKey)

// Access methods like these
playerViewKey.currentState?.hideController();
```

### Keep Screen On While Playing (Default: Disabled)

```dart
playerView = PlayerView(awakeScreenWhilePlaying: true)
```

### Disable the default controller view

```dart
playerViewKey.currentState?.disableController(true);
```

### Show/Hide the Controller View

```dart
playerViewKey.currentState?.showController();
playerViewKey.currentState?.hideController();

// Toggle controller visibility
playerViewKey.currentState?.toggleControllerVisibility();
```

### Set Resize Mode (Fit, Stretch, Crop)

```dart
playerViewKey.currentState?.setResizeMode(ResizeMode.fit); // Fit to screen


// Stretch to screen
playerViewKey.currentState?.setResizeMode(ResizeMode.stretch);


// Crop and fill the screen
playerViewKey.currentState?.setResizeMode(ResizeMode.crop);
```

## DataSource

The DataSource holds the media item that is passed from MediaX to the platform player for playback.

### Types of DataSource

### **1. Asset**

A regular Flutter asset stored in the app’s asset directory.

```dart
DataSource.asset('assets/file.mp4/');
```

### **2. File**

A local file from the device storage. You need to provide the local file path for playback.

```dart
DataSource.file('../../file.mp4');
```

### **3. Network**

A media file accessible via a network URL. The URL should point to a valid media source.

```dart
DataSource.network('https://example.com/file.mp4');
```

## Playback States

There is an enum provided by PlaybackState which will compare the playback state obtained from the listen() method callback.

### The player can be in one of the following states:

### **Idle**

The player is stopped or not playing anything.

### **loading**

A media item is currently being loaded.

### **ready**

The media item has loaded and is ready to play.

### **buffering**

The media item is buffering or loading initially.

### **ended**

The media item has completed playing after reaching the end.

## Playback Error

To listen to the error changes observe the controller's playbackError object for non-null.

### Error Object Structure

The error object contains the following parameters:

### &bull; **message**

A descriptive message representing the cause of the error.

### &bull; **errorCode**

A unique error code to help identify the type of error.

### &bull; **stackTrace**

The full stack trace to assist in debugging and finding the root cause.

## Error Code and Message

- **`PlaybackError.unknown`** → Unknown error occurred.
- **`PlaybackError.sourceNotFound`** → Media source not found.
- **`PlaybackError.codecError`** → Codec Not Found.
- **`PlaybackError.networkError`** → Network error occurred.
- **`PlaybackError.timeout`** → Playback timed out.
- **`PlaybackError.drmError`** → DRM decryption failed.
- **`PlaybackError.internalError`** → Playback failed due to an internal error.
- **`PlaybackError.audioSessionError`** → Audio session error occurred.
- **`PlaybackError.unsupportedFormat`** → Media format is not supported.
- **`PlaybackError.invalidState`** → Invalid player state.
- **`PlaybackError.resourceError`** → Failed to allocate resources.
