import AVKit
import FlutterMacOS

class DataSource {
    private let uri: String
    private let type: String
    
    private init(uri: String, type: String) {
        self.uri = uri
        self.type = type
    }
    
    /// Load an asset from Flutter assets (No copying required)
    static func asset(context: FlutterPluginRegistrar, assetPath: String) throws -> DataSource {
        let key = context.lookupKey(forAsset: assetPath)
        // On macOS, lookupKey returns a path relative to the .app bundle root
        // (e.g. "Contents/Frameworks/App.framework/Resources/flutter_assets/foo.mp4")
        // so resolve it against bundleURL, matching the video_player_avfoundation pattern.
        let fullPath = Bundle.main.path(forResource: key, ofType: nil)
            ?? URL(string: key, relativeTo: Bundle.main.bundleURL)?.path
        guard let resolvedPath = fullPath, FileManager.default.fileExists(atPath: resolvedPath) else {
            throw NSError(domain: "AssetNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found: \(assetPath)"])
        }
        return DataSource(uri: resolvedPath, type: "asset")
    }
    
    /// Load a media item from a network URL.
    static func network(url: String) -> DataSource {
        return DataSource(uri: url, type: "network")
    }
    
    /// Load a media item from a local file.
    static func file(filePath: String) -> DataSource {
        return DataSource(uri: filePath, type: "file")
    }
    
    /// Get an `AVURLAsset` for playback.
    func getMediaAsset() -> AVURLAsset {
        let url: URL
        switch type {
        case "network":
            // For network URLs, create URL directly from string
            guard let networkUrl = URL(string: uri) else {
                fatalError("Invalid network URL: \(uri)")
            }
            url = networkUrl
        case "file", "asset":
            // For files and assets, create file URL
            url = URL(fileURLWithPath: uri)
        default:
            fatalError("Unsupported media type: \(type)")
        }
        
        // Create asset with appropriate options
        var options: [String: Any] = [:]
        if type == "network" {
            // For network URLs, allow streaming
            options[AVURLAssetAllowsCellularAccessKey] = true
            options[AVURLAssetPreferPreciseDurationAndTimingKey] = true
        }
        
        return AVURLAsset(url: url, options: options)
    }
}
