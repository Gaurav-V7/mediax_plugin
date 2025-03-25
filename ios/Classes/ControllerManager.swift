//
//  ControllerManager.swift
//  Pods
//
//  Created by AI Alpha Tech on 31/01/25.
//

import AVFoundation
import Flutter

class ControllerManager {
    static var controllers = [String: PlayerController]()
    
    static func getController(controllerId: String) -> PlayerController? {
        return controllers[controllerId]
    }
    
    static func releaseAllControllers() {
        for (_, controller) in controllers {
            controller.releasePlayer()
        }
        controllers.removeAll()
    }
    
    static func createController(
        controllerId: String,
        flutterEngine: FlutterEngine,
        context: UIViewController?,
        activity: UIViewController?,
        params: [String: Any]?,
        methodChannel: FlutterMethodChannel,
        registrar: FlutterPluginRegistrar
    ) throws {
        
        let playerController = PlayerController(methodChannel: methodChannel, registrar: registrar)
        
        guard let params = params else {
            throw NSError(domain: Constants.CONTROLLER_MANAGER_ERROR_DOMAIN, code: 0, userInfo: [NSLocalizedDescriptionKey: Constants.PARAMS_MUST_NOT_BE_NULL])
        }
        
        var type: String? = nil
        var uri: String? = nil
        var autoplay: Bool = true
        
        if let dataSource = params[Constants.DATA_SOURCE] as? [String: Any] {
            guard let typeValue = dataSource[Constants.TYPE] as? String else {
                throw NSError(domain: Constants.CONTROLLER_MANAGER_ERROR_DOMAIN, code: 0, userInfo: [NSLocalizedDescriptionKey: Constants.DATASOURCE_TYPE_NULL_ERROR])
            }
            
            guard let uriValue = dataSource[Constants.URI] as? String else {
                throw NSError(domain: Constants.CONTROLLER_MANAGER_ERROR_DOMAIN, code: 0, userInfo: [NSLocalizedDescriptionKey: Constants.URI_NULL_ERROR])
            }
            
            let autoplayValue = params[Constants.AUTOPLAY] as? Bool ?? true
            
            type = typeValue
            uri = uriValue
            autoplay = autoplayValue
            
        }
        
        let enableMediaSession = params[Constants.ENABLE_MEDIA_SESSION] as? Bool ?? false
        
        playerController.initPlayer(uri: uri, type: type, autoplay: autoplay, enableMediaSession: enableMediaSession)
        
        controllers[controllerId] = playerController
    }
    
    static func releaseController(controllerId: String) {
        controllers[controllerId]?.releasePlayer()
        controllers.removeValue(forKey: controllerId)
    }
}
