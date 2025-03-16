import Flutter
import UIKit
import AVFoundation

public class MediaxPlugin: NSObject, FlutterPlugin {
    private var controllers: [String: PlayerController] = [:]
    private static var pluginRegistrar: FlutterPluginRegistrar?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MediaxPlugin()
        pluginRegistrar = registrar
        
        // Handle controller creation
        let channel = FlutterMethodChannel(name: Constants.MEDIAX, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Register the view factory with correct view type identifier
        let messenger = registrar.messenger()
        let flutterEngine = (UIApplication.shared.delegate as? FlutterAppDelegate)?.window?.rootViewController as? FlutterViewController
        let factory = PlayerViewFactory(flutterEngine: flutterEngine!.engine!)
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
                    binaryMessenger: MediaxPlugin.pluginRegistrar!.messenger()
                )
                
                // Check if the controller exists, if not create it
                if ControllerManager.getController(controllerId: controllerId) == nil {
                    let flutterEngine = (UIApplication.shared.delegate as? FlutterAppDelegate)?.window?.rootViewController as? FlutterViewController
                    do {
                        // Assuming the arguments contains necessary parameters like dataSource, autoplay, etc.
                        try ControllerManager.createController(
                            controllerId: controllerId,
                            flutterEngine: (flutterEngine?.engine!)!,
                            context: flutterEngine,
                            activity: flutterEngine,
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
}
