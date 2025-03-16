//
//  PlayerView.swift
//  Pods
//
//  Created by AI Alpha Tech on 31/01/25.
//

import AVFoundation
import Flutter
import UIKit
import AVKit

class PlayerView: NSObject, FlutterPlatformView {
    
    private let methodChannel: FlutterMethodChannel
    
    private var playerViewController: AVPlayerViewController?
    private weak var player: AVPlayer?
    private let controllerId: String
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        flutterEngine: FlutterEngine
    ) {
        // Extract parameters
        let params = args as? [String: Any]
        self.controllerId = params?["controllerId"] as? String ?? ""
        self.methodChannel = FlutterMethodChannel(name: "\(Constants.MEDIAX_VIEW)_\(self.controllerId)", binaryMessenger: flutterEngine.binaryMessenger)
        super.init()
        
        self.methodChannel.setMethodCallHandler(handleMethodCall)
        
        let playerController = ControllerManager.getController(controllerId: controllerId)
        
        guard let playerController = playerController else {
            fatalError("PlayerController with id \(self.controllerId) not found")
        }
        
        self.player = playerController.player
        
        setupPlayerViewController()
        setupInitialBackgroundPlayback()
    }
    
    private func setupPlayerViewController() {
        guard let player = self.player else { return }
        
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect  // Ensure proper video scaling
        if #available(iOS 16.0, *) {
            controller.allowsVideoFrameAnalysis = false
        }
        controller.allowsPictureInPicturePlayback = false
        if #available(iOS 14.2, *) {
            controller.canStartPictureInPictureAutomaticallyFromInline = false
        }
        
        // Force view loading and layout
        _ = controller.view
        controller.view.backgroundColor = .black
        
        // Set proper frame
        controller.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        playerViewController = controller
    }
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Constants.SET_RESIZE_MODE:
            setResizeMode(resizeMode: call.arguments as! Int)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func setResizeMode(resizeMode: Int = ResizeMode.fit.rawValue) {
        if (resizeMode == ResizeMode.fit.rawValue) {
            playerViewController?.videoGravity = .resizeAspect
        } else if (resizeMode == ResizeMode.stretch.rawValue) {
            playerViewController?.videoGravity = .resize
        } else if (resizeMode == ResizeMode.crop.rawValue) {
            playerViewController?.videoGravity = .resizeAspectFill
        }
    }
    
    private func setupInitialBackgroundPlayback() {
        if #available(iOS 15.0, *) {
            playerViewController?.player?.audiovisualBackgroundPlaybackPolicy = AVPlayerAudiovisualBackgroundPlaybackPolicy(rawValue: AVPlayerAudiovisualBackgroundPlaybackPolicy.continuesIfPossible.rawValue)!
        }
    }
    
    @objc private func handleEnterForeground() {
        guard let player = self.player else { return }
        
        // Reattach player to existing view controller
        if let controller = playerViewController {
            controller.player = player
            
            // Force immediate layout update
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
        } else {
            setupPlayerViewController()
        }
    }
    
    func view() -> UIView {
        if playerViewController == nil {
            setupPlayerViewController()
        }
        return playerViewController?.view ?? UIView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        playerViewController?.player = nil
        playerViewController = nil
    }
}
