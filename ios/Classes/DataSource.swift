//
//  DataSource.swift
//  Pods
//
//  Created by AI Alpha Tech on 31/01/25.
//

import AVKit
import Flutter

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
        guard let assetURL = Bundle.main.path(forResource: key, ofType: nil) else {
            throw NSError(domain: "AssetNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found: \(assetPath)"])
        }
        return DataSource(uri: assetURL, type: "asset")
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
