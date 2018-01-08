//
//  Parser.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

/// <#Description#>
public class Parser: Parsable {
    static let logger = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser")
    static let loggerPacketCallback = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser.Packets")
    static let loggerPropertyListenerCallback = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser.PropertyListener")
    
    /// <#Description#>
    class Info {
        var bitRate: UInt32 = 0
        var byteCount: UInt64 = 0
        var dataOffset: Int64 = 0
        var packetCount: UInt64 = 0
        var fileFormat: AVAudioFormat?
        var dataFormat: AVAudioFormat?
        var isReadyToProducePackets: Bool = false
        var packets = [(Data, AudioStreamPacketDescription?)]()
    }
    
    /// <#Description#>
    fileprivate var info = Info()
    
    /// <#Description#>
    fileprivate var streamID: AudioFileStreamID?
    
    /// <#Description#>
    public var bitRate: UInt32 {
        return info.bitRate
    }
    
    /// <#Description#>
    public var byteCount: UInt64 {
        return info.byteCount
    }
    
    /// <#Description#>
    public var dataFormat: AVAudioFormat? {
        return info.dataFormat
    }
    
    /// <#Description#>
    public var dataOffset: Int64 {
        return info.dataOffset
    }
    
    /// <#Description#>
    public var fileFormat: AVAudioFormat? {
        return info.fileFormat
    }
    
    /// <#Description#>
    public var isComplete: Bool {
        return info.packetCount == info.packets.count
    }
    
    /// <#Description#>
    public var packets: [(Data, AudioStreamPacketDescription?)] {
        return info.packets
    }
    
    // MARK: - Initializers
    
    /// <#Description#>
    ///
    /// - Throws: <#throws value description#>
    public init() throws {
        guard AudioFileStreamOpen(&self.info, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &self.streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameter data: <#data description#>
    public func parse(data: Data) {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        guard let streamID = streamID else {
            os_log("Failed to open stream", log: Parser.logger, type: .error)
            return
        }
  
        let count = data.count
        _ = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            guard AudioFileStreamParseBytes(streamID, UInt32(count), bytes, []) == noErr else {
                os_log("Failed to parse bytes", log: Parser.logger, type: .error)
                return
            }
        }
    }
}
