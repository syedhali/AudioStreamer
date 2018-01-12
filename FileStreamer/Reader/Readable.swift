//
//  Readable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation

/// <#Description#>
public protocol Readable {
    
    /// <#Description#>
    var currentPacket: AVAudioPacketCount { get set }
    
    /// <#Description#>
    ///
    /// - Parameter frames: <#frames description#>
    func read(_ frames: AVAudioFrameCount) -> AVAudioPCMBuffer?
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - parser: <#parser description#>
    ///   - clientFormat: <#clientFormat description#>
    init(parser: Parsable, readFormat: AVAudioFormat) throws
}
