//
//  Parsable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation

/// The `Parsable` protocol represents a generic parser that can be used for converting binary data into audio packets.
public protocol Parsable: class {
    
    // MARK: - Properties
        
    /// <#Description#>
    var dataFormat: AVAudioFormat? { get }
    
    /// <#Description#>
    var duration: TimeInterval? { get }
    
    /// <#Description#>
    var totalFrameCount: AVAudioFrameCount? { get }
    
    /// <#Description#>
    var totalPacketCount: AVAudioPacketCount? { get }
    
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
