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

/// The `Parser` is a concrete implementation of the `Parsable` protocol used to convert binary data into audio packet data. This class uses the Audio File Stream Services to progressively parse the properties and packets of the incoming audio data.
public class Parser: Parsable {
    static let logger = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser")
    static let loggerPacketCallback = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser.Packets")
    static let loggerPropertyListenerCallback = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser.PropertyListener")
    
    /// <#Description#>
    class Info {
        var bitRate: UInt32 = 0
        var byteCount: UInt64 = 0
        var dataOffset: Int64 = 0
        var frameCount: UInt64 = 0
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
    public var dataFormat: AVAudioFormat? {
        return info.dataFormat
    }
    
    /// <#Description#>
    public var dataOffset: Int64 {
        return info.dataOffset
    }
    
    ///
    public var duration: TimeInterval? {
        guard let dataFormat = info.dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        guard let totalFrameCount = totalFrameCount else {
            return nil
        }
        
        return TimeInterval(totalFrameCount) / TimeInterval(dataFormat.mSampleRate)
    }
    
    public var totalFrameCount: AVAudioFrameCount? {
        guard let dataFormat = info.dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        guard let totalPacketCount = totalPacketCount else {
            return nil
        }
        
        return AVAudioFrameCount(totalPacketCount) * AVAudioFrameCount(dataFormat.mFramesPerPacket)
    }
    
    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = info.dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        return max(AVAudioPacketCount(info.packetCount), AVAudioPacketCount(packets.count))
    }
    
    /// <#Description#>
    public var fileFormat: AVAudioFormat? {
        return info.fileFormat
    }
    
    /// <#Description#>
    public var packets: [(Data, AudioStreamPacketDescription?)] {
        return info.packets
    }
    
    // MARK: - Lifecycle
    
    /// <#Description#>
    ///
    /// - Throws: <#throws value description#>
    public init() throws {
        guard AudioFileStreamOpen(&self.info, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &self.streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    // MARK: - Methods
    
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
    
    public func packetOffset(forFrame frame: AVAudioFrameCount) -> AVAudioPacketCount? {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        guard let dataFormat = info.dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        return AVAudioPacketCount(frame) / AVAudioPacketCount(dataFormat.mFramesPerPacket)
    }
}
