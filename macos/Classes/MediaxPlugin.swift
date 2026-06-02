import Cocoa
import FlutterMacOS
import AVFoundation

public class MediaxPlugin: NSObject, FlutterPlugin {
    private static var pluginRegistrar: FlutterPluginRegistrar?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MediaxPlugin()
        pluginRegistrar = registrar
        
        // Handle controller creation
        let channel = FlutterMethodChannel(name: Constants.MEDIAX, binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Register the view factory
        let factory = PlayerViewFactory(registrar: registrar)
        registrar.register(factory, withId: Constants.VIDEO_VIEW)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case Constants.INIT_PLAYER:
            // Retrieve controllerId from arguments
            if let arguments = call.arguments as? [String: Any],
               let controllerId = arguments[Constants.CONTROLLER_ID] as? String {
                
                // Create a method channel for this specific controller
                let controllerChannel = FlutterMethodChannel(
                    name: "mediax_\(controllerId)",
                    binaryMessenger: MediaxPlugin.pluginRegistrar!.messenger
                )
                
                // Check if the controller exists, if not create it
                if ControllerManager.getController(controllerId: controllerId) == nil {
                    do {
                        try ControllerManager.createController(
                            controllerId: controllerId,
                            params: arguments,
                            methodChannel: controllerChannel,
                            registrar: MediaxPlugin.pluginRegistrar!
                        )
                    } catch {
                        print("Error creating controller: \(error)")
                    }
                }
            }
            result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        ControllerManager.releaseAllControllers()
    }
}
