//
//  StreamableDelegate.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

public protocol StreamableDelegate: class {

    // Progress 0 - 1
    func streamer(_ streamer: Streamable, updatedDownloadProgress progress: Float, forURL url: URL)
    
    // When play state changes
    func streamer(_ streamer: Streamable, changedState state: StreamableState)
    
    // When current time is updated
    func streamer(_ streamer: Streamable, updatedCurrentTime currentTime: TimeInterval)
    
    // When duration value is known
    func streamer(_ streamer: Streamable, updatedDuration duration: TimeInterval)
    
}
