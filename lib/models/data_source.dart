/// Represents the type of data source.
enum DataSourceType {
  /// A data source that refers to an asset.
  asset,

  /// A data source that refers to a network resource.
  network,

  /// A data source that refers to a local file.
  file
}

/// Represents a data source for a video.
///
/// A data source can either be:
///
/// * An asset (e.g. a video file bundled with the app).
/// * A network resource (e.g. a video hosted on a server).
/// * A local file (e.g. a video file stored on the device).
class DataSource {
  /// The URI of the data source.
  ///
  /// Depending on the [type], this can be:
  ///
  /// * The name of an asset (e.g. a video file bundled with the app).
  /// * The URL of a network resource (e.g. a video hosted on a server).
  /// * The path to a local file (e.g. a video file stored on the device).
  final String uri;

  /// The type of the data source.
  final DataSourceType type;

  DataSource._(this.uri, this.type);

  /// Creates a new Asset [DataSource] object with the given [uri] and [type].
  factory DataSource.asset(String assetUri) {
    return DataSource._(assetUri, DataSourceType.asset);
  }

  /// Creates a new Network [DataSource] object with the given [uri] and [type].
  factory DataSource.network(String networkUri) {
    return DataSource._(networkUri, DataSourceType.network);
  }

  /// Creates a new File [DataSource] object with the given [uri] and [type].
  factory DataSource.file(String fileUri) {
    return DataSource._(fileUri, DataSourceType.file);
  }

  /// Converts the [DataSource] object to a map.
  Map<String, dynamic> toMap() {
    return {'uri': uri, 'type': type.name};
  }
}
