import AVFoundation
import FlutterMacOS
import AppKit
import AVKit

class PlayerView: NSObject {
    
    private let methodChannel: FlutterMethodChannel
    
    private var playerView: AVPlayerView?
    private weak var player: AVPlayer?
    private let controllerId: String
    
    init(
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger: FlutterBinaryMessenger
    ) {
        // Extract parameters
        let params = args as? [String: Any]
        self.controllerId = params?["controllerId"] as? String ?? ""
        self.methodChannel = FlutterMethodChannel(name: "\(Constants.MEDIAX_VIEW)_\(self.controllerId)", binaryMessenger: binaryMessenger)
        super.init()
        
        self.methodChannel.setMethodCallHandler(handleMethodCall)
        
        let playerController = ControllerManager.getController(controllerId: controllerId)
        
        guard let playerController = playerController else {
            fatalError("PlayerController with id \(self.controllerId) not found")
        }
        
        self.player = playerController.player
        
        setupPlayerView()
        setupInitialBackgroundPlayback()
    }
    
    private func setupPlayerView() {
        guard let player = self.player else { return }
        
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none  // Hide controls on macOS
        view.videoGravity = .resizeAspect  // Ensure proper video scaling
        
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        // Set proper frame - use container view bounds or default size
        if let screen = NSScreen.main {
            view.frame = CGRect(x: 0, y: 0, width: screen.frame.width, height: screen.frame.height)
        } else {
            view.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        }
        view.autoresizingMask = [.width, .height]
        
        playerView = view
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
            playerView?.videoGravity = .resizeAspect
        } else if (resizeMode == ResizeMode.stretch.rawValue) {
            playerView?.videoGravity = .resize
        } else if (resizeMode == ResizeMode.crop.rawValue) {
            playerView?.videoGravity = .resizeAspectFill
        }
    }
    
    private func setupInitialBackgroundPlayback() {
        if #available(macOS 12.0, *) {
            playerView?.player?.audiovisualBackgroundPlaybackPolicy = AVPlayerAudiovisualBackgroundPlaybackPolicy(rawValue: AVPlayerAudiovisualBackgroundPlaybackPolicy.continuesIfPossible.rawValue)!
        }
    }
    
    @objc private func handleEnterForeground() {
        guard let player = self.player else { return }
        
        // Reattach player to existing view
        if let view = playerView {
            view.player = player
            
            // Force immediate layout update
            view.needsLayout = true
            view.layout()
        } else {
            setupPlayerView()
        }
    }
    
    func view() -> NSView {
        if playerView == nil {
            setupPlayerView()
        }
        guard let view = playerView else {
            return NSView()
        }
        return view
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        playerView?.player = nil
        playerView = nil
    }
}
