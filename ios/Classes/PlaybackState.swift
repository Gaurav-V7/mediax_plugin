//
//  PlaybackState.swift
//  Pods
//
//  Created by AI Alpha Tech on 31/01/25.
//

enum PlaybackState: Int {
    case idle = 0
    case loading
    case ready
    case buffering
    case ended
}
