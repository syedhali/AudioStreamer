//
//  Parsable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation

/// <#Description#>
public protocol Parsable: class {
    
    // MARK: - Properties
    
    /// <#Description#>
    var byteCount: UInt64 { get }
    
    /// <#Description#>
    var dataFormat: AVAudioFormat? { get }
    
    /// <#Description#>
    var duration: TimeInterval? { get }
    
    /// <#Description#>
    var totalFrameCount: AVAudioFrameCount? { get }
    
    /// <#Description#>
    var totalPacketCount: AVAudioPacketCount? { get }
    
    /// <#Description#>
    var isComplete: Bool { get }
    
    /// <#Description#>
    var fileFormat: AVAudioFormat? { get }
    
    /// <#Description#>
    var packets: [(Data, AudioStreamPacketDescription?)] { get }
    
    // MARK: - Methods
    
    /// <#Description#>
    ///
    /// - Parameter data: <#data description#>
    func parse(data: Data)
    
}
