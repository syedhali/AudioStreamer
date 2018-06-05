//
//  StreamableState.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

public struct StreamableState: OptionSet {
    // Required overrides
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // Playback state
    static let stopped = StreamableState(rawValue: 1 << 0)
    static let paused = StreamableState(rawValue: 1 << 1)
    static let playing = StreamableState(rawValue: 1 << 2)
    
    // End state
    static let endOfFile = StreamableState(rawValue: 1 << 3)
    
    // Download state
    static let downloading = StreamableState(rawValue: 1 << 4)
}
