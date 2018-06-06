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
    public static let stopped = StreamableState(rawValue: 1 << 0)
    public static let paused = StreamableState(rawValue: 1 << 1)
    public static let playing = StreamableState(rawValue: 1 << 2)
    
    // End state
    public static let endOfFile = StreamableState(rawValue: 1 << 3)
    
    // Download state
    public static let downloading = StreamableState(rawValue: 1 << 4)
}
