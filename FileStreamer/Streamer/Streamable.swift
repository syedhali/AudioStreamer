//
//  Streamable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation

public protocol Streamable: class {
    
    var currentTime: TimeInterval? { get }
    
    var delegate: StreamableDelegate? { get set }
    
    var duration: TimeInterval? { get }
    
    var engine: AVAudioEngine { get }
    
    var playerNode: AVAudioPlayerNode { get }
    
    var readBufferSize: AVAudioFrameCount { get }
    
    var readFormat: AVAudioFormat { get }
    
    var state: StreamableState { get }
    
    var url: URL? { get }
    
    var volume: Float { get set }
    
    func play()
    
    func pause()
    
    func stop()
    
    func seek(to time: TimeInterval) throws
}
