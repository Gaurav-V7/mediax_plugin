//
//  PlayerViewFactory.swift
//  Pods
//
//  Created by AI Alpha Tech on 31/01/25.
//

import Flutter
import UIKit

class PlayerViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private let flutterEngine: FlutterEngine
    
    init(flutterEngine: FlutterEngine) {
        self.flutterEngine = flutterEngine
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let params = args as? [String: Any]
        let controllerId = params?[Constants.CONTROLLER_ID] as? String
        
        if let controllerId = controllerId {
            _ = ControllerManager.getController(controllerId: controllerId)
        }
        
        return PlayerView(frame: frame, viewIdentifier: viewId, arguments: args, flutterEngine: flutterEngine)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    
}
