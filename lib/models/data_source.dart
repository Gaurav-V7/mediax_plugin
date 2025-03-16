enum DataSourceType { asset, network, file }

class DataSource {
  final String uri;
  final DataSourceType type;

  DataSource._(this.uri, this.type);

  factory DataSource.asset(String assetUri) {
    return DataSource._(assetUri, DataSourceType.asset);
  }

  factory DataSource.network(String networkUri) {
    return DataSource._(networkUri, DataSourceType.network);
  }

  factory DataSource.file(String fileUri) {
    return DataSource._(fileUri, DataSourceType.file);
  }

  Map<String, dynamic> toMap() {
    return {'uri': uri, 'type': type.name};
  }
}
