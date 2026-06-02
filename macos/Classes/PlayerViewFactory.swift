import FlutterMacOS
import AppKit

class PlayerViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private let registrar: FlutterPluginRegistrar
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }
    
    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        let params = args as? [String: Any]
        let controllerId = params?[Constants.CONTROLLER_ID] as? String
        
        if let controllerId = controllerId {
            _ = ControllerManager.getController(controllerId: controllerId)
        }
        
        // Try to get engine from registrar, or use binaryMessenger to create method channel
        // On macOS, we might need to access the engine differently
        let binaryMessenger = registrar.messenger
        let playerView = PlayerView(viewIdentifier: viewId, arguments: args, binaryMessenger: binaryMessenger)
        return playerView.view()
    }
    
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    
}
